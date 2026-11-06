import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  String uid;
  String nombre;
  String usuario;
  String correo;
  String clave; // Se conserva como compatibilidad en memoria, no se almacena en Firestore
  String foto; // asset ("assets/images/avatar.png") o "base64:..."
  String telefono;
  String rol;
  String miembroDesde;
  bool onboardingCompletado;
  bool planPro;
  DateTime? creadoEn;

  Usuario({
    this.uid = '',
    required this.nombre,
    required this.usuario,
    required this.correo,
    this.clave = '',
    this.foto = 'assets/images/avatar.png',
    this.telefono = '',
    this.rol = '',
    this.miembroDesde = '',
    this.onboardingCompletado = false,
    this.planPro = false,
    this.creadoEn,
  });

  /// Identificador único: con Firebase es el UID de Auth.
  /// Si aún no tiene UID (caso legado/invitado), retorna el usuario en minúsculas.
  String get id => uid.isNotEmpty ? uid : usuario.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nombre': nombre,
        'usuario': usuario.trim().toLowerCase(),
        'correo': correo.trim().toLowerCase(),
        'foto': foto,
        'telefono': telefono,
        'rol': rol,
        'miembroDesde': miembroDesde,
        'onboardingCompletado': onboardingCompletado,
        'planPro': planPro,
        'creadoEn': creadoEn != null
            ? Timestamp.fromDate(creadoEn!)
            : FieldValue.serverTimestamp(),
      };

  factory Usuario.fromJson(Map<String, dynamic> j, {String? uid}) => Usuario(
        uid: uid ?? (j['uid'] as String? ?? ''),
        nombre: j['nombre'] as String? ?? '',
        usuario: j['usuario'] as String? ?? '',
        correo: j['correo'] as String? ?? '',
        clave: '', // Nunca se lee clave de Firestore
        foto: j['foto'] as String? ?? 'assets/images/avatar.png',
        telefono: j['telefono'] as String? ?? '',
        rol: j['rol'] as String? ?? '',
        miembroDesde: j['miembroDesde'] as String? ?? '',
        onboardingCompletado: j['onboardingCompletado'] as bool? ?? false,
        planPro: j['planPro'] as bool? ?? false,
        creadoEn: j['creadoEn'] is Timestamp
            ? (j['creadoEn'] as Timestamp).toDate()
            : (j['creadoEn'] is String
                ? DateTime.tryParse(j['creadoEn'] as String)
                : null),
      );

  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data() ?? {};
    return Usuario.fromJson(j, uid: doc.id);
  }
}
