class Usuario {
  String nombre;
  String usuario;
  String correo;
  String clave;
  String foto; // asset ("assets/images/avatar.png") o "base64:..." si subió una
  String telefono;
  String rol;
  String miembroDesde;

  Usuario({
    required this.nombre,
    required this.usuario,
    required this.correo,
    this.clave = '',
    this.foto = 'assets/images/avatar.png',
    this.telefono = '',
    this.rol = '',
    this.miembroDesde = '',
  });

  /// Identificador único: el nombre de usuario en minúsculas.
  String get id => usuario.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'usuario': usuario,
        'correo': correo,
        'clave': clave,
        'foto': foto,
        'telefono': telefono,
        'rol': rol,
        'miembroDesde': miembroDesde,
      };

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        nombre: j['nombre'] as String? ?? '',
        usuario: j['usuario'] as String? ?? '',
        correo: j['correo'] as String? ?? '',
        clave: j['clave'] as String? ?? '',
        foto: j['foto'] as String? ?? 'assets/images/avatar.png',
        telefono: j['telefono'] as String? ?? '',
        rol: j['rol'] as String? ?? '',
        miembroDesde: j['miembroDesde'] as String? ?? '',
      );
}
