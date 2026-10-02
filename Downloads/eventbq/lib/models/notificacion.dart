class Notificacion {
  String id;
  String titulo;
  String descripcion;
  String tiempo; // "Hace 2 horas"
  String tipo; // "Eventos" u "Organizador" (pestaña donde aparece)
  bool leida;
  bool pideCalificacion;
  String idEvento; // evento al que se refiere (para calificarlo) // muestra "CALIFICA AQUI" y fondo violeta

  Notificacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tiempo,
    required this.tipo,
    this.leida = false,
    this.pideCalificacion = false,
    this.idEvento = '',
  });
}
