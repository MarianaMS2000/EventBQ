class Usuario {
  String nombre;
  String usuario;
  String correo;
  String foto; // ruta del asset
  String telefono;
  String rol;
  String miembroDesde;
  int eventosAsistidos;
  int eventosCreados;
  double rating;

  Usuario({
    required this.nombre,
    required this.usuario,
    required this.correo,
    required this.foto,
    this.telefono = '',
    this.rol = '',
    this.miembroDesde = '',
    this.eventosAsistidos = 0,
    this.eventosCreados = 0,
    this.rating = 0,
  });
}
