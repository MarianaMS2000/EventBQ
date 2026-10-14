import 'dart:convert';
import '../models/usuario.dart';
import '../preferences/preferencias_usuario.dart';
import '../utils/formato.dart';
import 'cambios.dart';
import 'notificacion_repository.dart';

/// Cuentas de usuario guardadas en el celular.
///
/// Las cuentas viven en una List<Usuario> (en memoria) y se guardan como JSON
/// en SharedPreferences cada vez que cambian. Sin backend: el registro crea la
/// cuenta de verdad y el login solo deja entrar si usuario/correo y contraseña
/// coinciden con una cuenta registrada.
class UsuarioRepository {
  static final UsuarioRepository _instancia = UsuarioRepository._();
  factory UsuarioRepository() => _instancia;
  UsuarioRepository._();

  static const _kCuentas = 'cuentas';

  final List<Usuario> _cuentas = [];
  bool _cargado = false;

  void _cargar() {
    if (_cargado) return;
    _cargado = true;
    final raw = PreferenciasUsuario.leerTexto(_kCuentas);
    if (raw == null) return;
    try {
      final lista = jsonDecode(raw) as List;
      _cuentas.addAll(
        lista.map((j) => Usuario.fromJson(Map<String, dynamic>.from(j as Map))),
      );
    } catch (_) {
      // Datos dañados: se empieza sin cuentas en vez de cerrar la app.
    }
  }

  void _guardar() {
    PreferenciasUsuario.guardarTexto(
      _kCuentas,
      jsonEncode(_cuentas.map((u) => u.toJson()).toList()),
    );
    notificarCambios();
  }

  /// Todas las cuentas registradas (copia).
  List<Usuario> obtenerCuentas() {
    _cargar();
    return List.of(_cuentas);
  }

  Usuario? obtenerPorId(String id) {
    _cargar();
    for (final u in _cuentas) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Usuario con la sesión abierta. Si no hay ninguno devuelve un "Invitado".
  Usuario obtenerUsuarioActual() {
    return obtenerPorId(PreferenciasUsuario.usuarioActual) ??
        Usuario(nombre: 'Invitado', usuario: '', correo: '');
  }

  /// ¿Hay una sesión válida? (el usuario guardado todavía existe).
  bool get haySesion =>
      PreferenciasUsuario.sesionIniciada &&
      obtenerPorId(PreferenciasUsuario.usuarioActual) != null;

  /// Inicia sesión. Devuelve null si salió bien, o el mensaje de error.
  String? iniciarSesion(String usuarioOCorreo, String clave) {
    _cargar();
    final dato = usuarioOCorreo.trim().toLowerCase();
    if (dato.isEmpty || clave.isEmpty) {
      return 'Escribe tu usuario y contraseña';
    }
    Usuario? cuenta;
    for (final u in _cuentas) {
      if (u.id == dato || u.correo.toLowerCase() == dato) {
        cuenta = u;
        break;
      }
    }
    if (cuenta == null) {
      return 'No existe una cuenta con esos datos. Regístrate primero';
    }
    if (cuenta.clave != clave) return 'Contraseña incorrecta';
    PreferenciasUsuario.usuarioActual = cuenta.id;
    notificarCambios();
    return null;
  }

  /// Crea la cuenta y abre la sesión. Devuelve null si salió bien, o el error.
  String? registrar({
    required String nombre,
    required String usuario,
    required String correo,
    required String clave,
  }) {
    _cargar();
    final nombreOk = nombre.trim();
    final usuarioOk = usuario.trim();
    final correoOk = correo.trim();

    if (nombreOk.length < 3) return 'Escribe tu nombre completo';
    if (usuarioOk.length < 3 || usuarioOk.contains(RegExp(r'\s'))) {
      return 'El usuario debe tener mínimo 3 caracteres y sin espacios';
    }
    if (!correoValido(correoOk)) return 'Escribe un email válido';
    if (clave.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }
    if (_cuentas.any((u) => u.id == usuarioOk.toLowerCase())) {
      return 'Ese usuario ya está registrado';
    }
    if (_cuentas.any((u) => u.correo.toLowerCase() == correoOk.toLowerCase())) {
      return 'Ese email ya tiene una cuenta';
    }

    final nueva = Usuario(
      nombre: nombreOk,
      usuario: usuarioOk,
      correo: correoOk,
      clave: clave,
      miembroDesde: mesYAnio(DateTime.now()),
    );
    _cuentas.add(nueva);
    _guardar();
    PreferenciasUsuario.usuarioActual = nueva.id;
    // La cuenta nueva ve el tutorial (onboarding): su clave empieza en false.
    NotificacionRepository().crearBienvenida(nueva.id);
    notificarCambios();
    return null;
  }

  /// Guarda los campos editables del perfil. Devuelve null si salió bien.
  String? actualizarPerfil({
    required String correo,
    required String telefono,
    required String rol,
  }) {
    _cargar();
    final actual = obtenerPorId(PreferenciasUsuario.usuarioActual);
    if (actual == null) return 'No hay una sesión activa';
    final correoOk = correo.trim();
    if (!correoValido(correoOk)) return 'Escribe un email válido';
    final repetido = _cuentas.any(
      (u) => u.id != actual.id && u.correo.toLowerCase() == correoOk.toLowerCase(),
    );
    if (repetido) return 'Ese email ya lo usa otra cuenta';
    actual.correo = correoOk;
    actual.telefono = telefono.trim();
    actual.rol = rol.trim();
    _guardar();
    return null;
  }

  /// Guarda la foto de perfil (ruta de asset o "base64:...").
  void actualizarFoto(String foto) {
    _cargar();
    final actual = obtenerPorId(PreferenciasUsuario.usuarioActual);
    if (actual == null) return;
    actual.foto = foto;
    _guardar();
  }

  void cerrarSesion() {
    PreferenciasUsuario.usuarioActual = '';
    notificarCambios();
  }
}
