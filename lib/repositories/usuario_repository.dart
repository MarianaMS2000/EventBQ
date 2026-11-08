import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../preferences/preferencias_usuario.dart';
import '../utils/formato.dart';
import 'cambios.dart';
import 'evento_repository.dart';
import 'notificacion_repository.dart';

/// Repositorio de usuarios conectado a Firebase (Auth + Firestore).
///
/// Mantiene un caché en memoria alimentado por snapshots de Firestore.
/// Las lecturas son síncronas desde el caché y las escrituras son asíncronas
/// (Future) con manejo robusto de excepciones de Firebase.
class UsuarioRepository {
  static final UsuarioRepository _instancia = UsuarioRepository._();
  factory UsuarioRepository() => _instancia;
  UsuarioRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Usuario? _usuarioActual;
  final Map<String, Usuario> _cacheUsuarios = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _usuarioSub;
  StreamSubscription<User?>? _authSub;
  bool _inicializado = false;

  /// Inicializa la escucha del usuario autenticado actual.
  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    // Escuchar el stream de cambios de autenticación (reactivo en Web y Móvil)
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) async {
      if (user != null) {
        PreferenciasUsuario.usuarioActual = user.uid;
        await _iniciarEscucha(user.uid);
      } else {
        await _cancelarEscucha();
      }
      notificarCambios();
    });

    final currentUid = _auth.currentUser?.uid.isNotEmpty == true
        ? _auth.currentUser!.uid
        : PreferenciasUsuario.usuarioActual;

    if (currentUid.isNotEmpty) {
      PreferenciasUsuario.usuarioActual = currentUid;
      await _iniciarEscucha(currentUid);
    }
  }

  Future<void> _iniciarEscucha(String uid) async {
    await _usuarioSub?.cancel();

    // Obtener primera vez de inmediato para tener el caché disponible
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _usuarioActual = Usuario.fromFirestore(doc);
        _cacheUsuarios[uid] = _usuarioActual!;
        PreferenciasUsuario.guardarTexto(
          'perfil_cache_$uid',
          jsonEncode(_usuarioActual!.toJson()),
        );
        notificarCambios();
      } else if (_auth.currentUser != null && _auth.currentUser!.uid == uid) {
        // El usuario está autenticado pero su documento no existe en users: crearlo
        final email = _auth.currentUser!.email ?? '';
        final baseName = _auth.currentUser!.displayName?.isNotEmpty == true
            ? _auth.currentUser!.displayName!
            : (email.contains('@') ? email.split('@').first : 'Usuario');
        final capitalName = baseName.isNotEmpty
            ? '${baseName[0].toUpperCase()}${baseName.substring(1)}'
            : 'Usuario';
        final usernameCandidate = email.contains('@')
            ? email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')
            : 'user_${uid.substring(0, 5)}';

        final nuevo = Usuario(
          uid: uid,
          nombre: capitalName,
          usuario: usernameCandidate,
          correo: email,
          foto: '',
          miembroDesde: mesYAnio(DateTime.now()),
          onboardingCompletado: true,
          planPro: false,
          creadoEn: DateTime.now(),
        );
        try {
          await _firestore.collection('users').doc(uid).set(nuevo.toJson());
        } catch (_) {}
        _usuarioActual = nuevo;
        _cacheUsuarios[uid] = nuevo;
        PreferenciasUsuario.guardarTexto(
          'perfil_cache_$uid',
          jsonEncode(nuevo.toJson()),
        );
        notificarCambios();
      }
    } catch (_) {}

    _usuarioSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _usuarioActual = Usuario.fromFirestore(doc);
        _cacheUsuarios[uid] = _usuarioActual!;
        PreferenciasUsuario.guardarTexto(
          'perfil_cache_$uid',
          jsonEncode(_usuarioActual!.toJson()),
        );
        notificarCambios();
      }
    }, onError: (_) {});
  }

  /// Cancela listeners y limpia caché local.
  Future<void> _cancelarEscucha() async {
    await _usuarioSub?.cancel();
    _usuarioSub = null;
    _usuarioActual = null;
    PreferenciasUsuario.usuarioActual = '';
  }

  /// Usuario con la sesión abierta. Si no hay ninguno devuelve un "Invitado".
  Usuario obtenerUsuarioActual() {
    if (_usuarioActual != null) return _usuarioActual!;

    final currentUid = _auth.currentUser?.uid.isNotEmpty == true
        ? _auth.currentUser!.uid
        : PreferenciasUsuario.usuarioActual;

    if (currentUid.isNotEmpty) {
      if (_cacheUsuarios.containsKey(currentUid)) {
        _usuarioActual = _cacheUsuarios[currentUid];
        return _usuarioActual!;
      }

      // Restaurar sincrónicamente desde SharedPreferences para evitar cualquier parpadeo de "Invitado"
      final perfilGuardado = PreferenciasUsuario.leerTexto('perfil_cache_$currentUid');
      if (perfilGuardado != null && perfilGuardado.isNotEmpty) {
        try {
          final j = jsonDecode(perfilGuardado) as Map<String, dynamic>;
          _usuarioActual = Usuario.fromJson(j, uid: currentUid);
          _cacheUsuarios[currentUid] = _usuarioActual!;
          _iniciarEscucha(currentUid);
          return _usuarioActual!;
        } catch (_) {}
      }

      _iniciarEscucha(currentUid);
    }

    final authEmail = _auth.currentUser?.email ?? '';
    final defaultNombre = _auth.currentUser?.displayName?.isNotEmpty == true
        ? _auth.currentUser!.displayName!
        : (authEmail.isNotEmpty && authEmail.contains('@')
            ? '${authEmail.split("@").first[0].toUpperCase()}${authEmail.split("@").first.substring(1)}'
            : (currentUid.isNotEmpty ? 'Usuario' : 'Invitado'));

    final defaultUsuario = authEmail.isNotEmpty && authEmail.contains('@')
        ? authEmail.split('@').first.toLowerCase()
        : '';

    return Usuario(
      uid: currentUid,
      nombre: defaultNombre,
      usuario: defaultUsuario,
      correo: authEmail,
      foto: '',
    );
  }

  /// ¿Hay una sesión válida en Firebase Auth?
  bool get haySesion => _auth.currentUser != null;

  /// ¿Completó el onboarding el usuario con sesión?
  bool get onboardingCompletado =>
      _usuarioActual?.onboardingCompletado ?? PreferenciasUsuario.onboardingCompletado;

  /// Marca el onboarding como completado en Firestore y preferencias locales.
  Future<void> completarOnboarding() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'onboardingCompletado': true,
        });
        _usuarioActual?.onboardingCompletado = true;
      } catch (_) {}
    }
    notificarCambios();
  }

  /// Activa el plan Pro en Firestore y en caché
  Future<void> activarPlanPro() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'planPro': true,
        });
        _usuarioActual?.planPro = true;
      } catch (_) {}
    }
    notificarCambios();
  }

  /// Busca un usuario por su UID. Si no está en caché, lo consulta en segundo plano.
  Usuario? obtenerPorId(String id) {
    if (id.isEmpty) return null;
    if (_usuarioActual != null && (_usuarioActual!.uid == id || _usuarioActual!.id == id)) {
      return _usuarioActual;
    }
    if (_cacheUsuarios.containsKey(id)) {
      return _cacheUsuarios[id];
    }
    // Carga perezosa en segundo plano
    _cargarUsuarioRemoto(id);
    return null;
  }

  Future<void> _cargarUsuarioRemoto(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        final u = Usuario.fromFirestore(doc);
        _cacheUsuarios[id] = u;
        notificarCambios();
      }
    } catch (_) {}
  }

  /// Todas las cuentas cargadas en memoria (para compatibilidad).
  List<Usuario> obtenerCuentas() {
    if (_usuarioActual != null) {
      final list = _cacheUsuarios.values.toList();
      if (!list.any((u) => u.uid == _usuarioActual!.uid)) {
        list.add(_usuarioActual!);
      }
      return list;
    }
    return _cacheUsuarios.values.toList();
  }

  /// Inicia sesión con usuario o correo. Devuelve null si salió bien, o el mensaje de error.
  Future<String?> iniciarSesion(String usuarioOCorreo, String clave) async {
    final dato = usuarioOCorreo.trim();
    final claveOk = clave.trim();

    if (dato.isEmpty || claveOk.isEmpty) {
      return 'Escribe tu usuario y contraseña';
    }

    String emailFinal = dato.toLowerCase();

    // Si no contiene '@', es un nombre de usuario: buscar su correo en Firestore
    if (!dato.contains('@')) {
      try {
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(dato.toLowerCase())
            .get();

        if (!usernameDoc.exists || usernameDoc.data() == null) {
          return 'No existe una cuenta con ese usuario. Regístrate primero';
        }
        emailFinal = (usernameDoc.data()!['correo'] as String? ?? '').toLowerCase();
        if (emailFinal.isEmpty) {
          return 'Error al obtener la cuenta de usuario';
        }
      } catch (e) {
        return 'Error de conexión. Verifica tu internet';
      }
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailFinal,
        password: claveOk,
      );

      final uid = cred.user!.uid;
      PreferenciasUsuario.usuarioActual = uid;
      await _iniciarEscucha(uid);
      notificarCambios();
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe una cuenta con esos datos. Regístrate primero';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-credential':
          return 'Usuario o contraseña incorrectos';
        case 'invalid-email':
          return 'Escribe un email válido';
        case 'user-disabled':
          return 'Esta cuenta ha sido inhabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta más tarde';
        case 'network-request-failed':
          return 'No tienes conexión a internet';
        case 'operation-not-allowed':
        case 'configuration-not-found':
          return 'Debes activar "Correo/Contraseña" en Firebase Authentication en la consola';
        default:
          if ((e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
            return 'Debes activar "Correo/Contraseña" en la consola de Firebase Authentication';
          }
          return e.message ?? 'Error al iniciar sesión';
      }
    } catch (_) {
      return 'Ocurrió un error inesperado al iniciar sesión';
    }
  }

  /// Crea la cuenta en Firebase Auth, reserva el username y crea el perfil en Firestore.
  /// Si falla algún paso de Firestore, se hace rollback eliminando el usuario de Auth.
  Future<String?> registrar({
    required String nombre,
    required String usuario,
    required String correo,
    required String clave,
  }) async {
    final nombreOk = nombre.trim();
    final usuarioOk = usuario.trim().toLowerCase();
    final correoOk = correo.trim().toLowerCase();
    final claveOk = clave;

    if (nombreOk.length < 3) return 'Escribe tu nombre completo';
    if (usuarioOk.length < 3 || usuarioOk.contains(RegExp(r'\s'))) {
      return 'El usuario debe tener mínimo 3 caracteres y sin espacios';
    }
    if (!correoValido(correoOk)) return 'Escribe un email válido';
    if (claveOk.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    // 1. Validar disponibilidad del username en Firestore
    try {
      final usernameDoc =
          await _firestore.collection('usernames').doc(usuarioOk).get();
      if (usernameDoc.exists) {
        return 'Ese usuario ya está registrado';
      }
    } catch (e) {
      return 'Error de conexión al verificar el usuario';
    }

    UserCredential? cred;
    try {
      // 2. Crear la cuenta en Firebase Auth
      cred = await _auth.createUserWithEmailAndPassword(
        email: correoOk,
        password: claveOk,
      );

      final uid = cred.user!.uid;

      // 3. Crear documentos en batch: usernames/{usuario} y users/{uid}
      final batch = _firestore.batch();

      batch.set(_firestore.collection('usernames').doc(usuarioOk), {
        'uid': uid,
        'correo': correoOk,
      });

      final nuevoUsuario = Usuario(
        uid: uid,
        nombre: nombreOk,
        usuario: usuarioOk,
        correo: correoOk,
        foto: '',
        telefono: '',
        rol: '',
        miembroDesde: mesYAnio(DateTime.now()),
        onboardingCompletado: false,
        planPro: false,
        creadoEn: DateTime.now(),
      );

      batch.set(_firestore.collection('users').doc(uid), nuevoUsuario.toJson());

      await batch.commit();

      // Guardar displayName en Firebase Auth para sincronía instantánea
      try {
        await cred.user?.updateDisplayName(nombreOk);
      } catch (_) {}

      // 4. Inicializar sesión y notificación de bienvenida
      PreferenciasUsuario.usuarioActual = uid;
      PreferenciasUsuario.guardarTexto(
        'perfil_cache_$uid',
        jsonEncode(nuevoUsuario.toJson()),
      );
      await _iniciarEscucha(uid);
      NotificacionRepository().crearBienvenida(uid);
      notificarCambios();
      return null;
    } on FirebaseAuthException catch (e) {
      // Si Auth falló
      switch (e.code) {
        case 'email-already-in-use':
          return 'Ese email ya tiene una cuenta';
        case 'weak-password':
          return 'La contraseña debe tener mínimo 6 caracteres';
        case 'invalid-email':
          return 'Escribe un email válido';
        case 'network-request-failed':
          return 'No tienes conexión a internet';
        case 'operation-not-allowed':
        case 'configuration-not-found':
          return 'Debes activar "Correo/Contraseña" en Firebase Authentication en la consola';
        default:
          if ((e.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
            return 'Debes activar "Correo/Contraseña" en la consola de Firebase Authentication';
          }
          return e.message ?? 'Error al registrar la cuenta';
      }
    } catch (e) {
      // Rollback: si Firestore falló, borramos el usuario creado en Auth
      if (cred?.user != null) {
        try {
          await cred!.user!.delete();
        } catch (_) {}
      }
      return 'Error al guardar los datos de usuario. Intenta nuevamente';
    }
  }

  /// Guarda los campos editables del perfil en Firestore y Auth.
  Future<String?> actualizarPerfil({
    required String correo,
    required String telefono,
    required String rol,
  }) async {
    final actual = obtenerUsuarioActual();
    if (!haySesion || actual.uid.isEmpty) return 'No hay una sesión activa';

    final correoOk = correo.trim().toLowerCase();
    if (!correoValido(correoOk)) return 'Escribe un email válido';

    final cambioCorreo = correoOk != actual.correo.toLowerCase();

    if (cambioCorreo) {
      // Verificar que el nuevo correo no esté registrado por otra cuenta
      try {
        final query = await _firestore
            .collection('users')
            .where('correo', isEqualTo: correoOk)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty && query.docs.first.id != actual.uid) {
          return 'Ese email ya lo usa otra cuenta';
        }

        // Actualizar en Firebase Auth mediante verifyBeforeUpdateEmail
        final user = _auth.currentUser;
        if (user != null) {
          await user.verifyBeforeUpdateEmail(correoOk);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          return 'Por seguridad, vuelve a iniciar sesión antes de cambiar tu correo';
        }
        if (e.code == 'email-already-in-use') {
          return 'Ese email ya tiene una cuenta';
        }
        return 'Error de autenticación: ${e.message}';
      } catch (_) {
        return 'Error al verificar el nuevo correo';
      }
    }

    try {
      final batch = _firestore.batch();
      final userDocRef = _firestore.collection('users').doc(actual.uid);

      final Map<String, dynamic> updateData = {
        'telefono': telefono.trim(),
        'rol': rol.trim(),
      };

      if (cambioCorreo) {
        updateData['correo'] = correoOk;
        // Actualizar también en usernames/{usuario}
        batch.update(
          _firestore.collection('usernames').doc(actual.usuario.toLowerCase()),
          {'correo': correoOk},
        );
      }

      batch.update(userDocRef, updateData);
      await batch.commit();

      actual.telefono = telefono.trim();
      actual.rol = rol.trim();
      if (cambioCorreo) actual.correo = correoOk;

      notificarCambios();
      return null;
    } catch (_) {
      return 'Error al guardar cambios en el perfil';
    }
  }

  /// Guarda la foto de perfil en Firestore (en formato base64:... o asset).
  /// Devuelve null si fue exitoso o un mensaje de error si falló.
  Future<String?> actualizarFoto(String foto) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return 'No hay una sesión activa';

    // Validación preventiva de peso (< 300 KB)
    if (foto.length > 300 * 1024) {
      return 'Esa imagen es demasiado pesada. Elige una más liviana.';
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'foto': foto,
      });
      _usuarioActual?.foto = foto;
      if (_usuarioActual != null) {
        PreferenciasUsuario.guardarTexto(
          'perfil_cache_$uid',
          jsonEncode(_usuarioActual!.toJson()),
        );
      }
      notificarCambios();
      return null;
    } catch (_) {
      return 'No se pudo actualizar la foto de perfil';
    }
  }

  /// Cierra sesión en Firebase Auth, cancela listeners y limpia estado.
  Future<void> cerrarSesion() async {
    await _cancelarEscucha();
    await EventoRepository().cancelar();
    await NotificacionRepository().cancelar();
    await _auth.signOut();
    notificarCambios();
  }
}
