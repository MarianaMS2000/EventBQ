class Notificacion {
  String id;
  String titulo;
  String descripcion;
  DateTime creadaEn;
  String tipo; // "Eventos" u "Organizador" (pestaña donde aparece)
  bool leida;
  bool pideCalificacion; // muestra "CALIFICA AQUI" y fondo violeta
  String idEvento; // evento al que se refiere (para calificarlo)

  Notificacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    DateTime? creadaEn,
    this.leida = false,
    this.pideCalificacion = false,
    this.idEvento = '',
  }) : creadaEn = creadaEn ?? DateTime.now();

  /// "Hace 5 min", "Hace 2 horas"...
  String get tiempo {
    final d = DateTime.now().difference(creadaEn);
    if (d.inMinutes < 1) return 'Hace un momento';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
    if (d.inHours < 24) {
      return 'Hace ${d.inHours} ${d.inHours == 1 ? 'hora' : 'horas'}';
    }
    return 'Hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'creadaEn': creadaEn.toIso8601String(),
        'tipo': tipo,
        'leida': leida,
        'pideCalificacion': pideCalificacion,
        'idEvento': idEvento,
      };

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        descripcion: j['descripcion'] as String? ?? '',
        creadaEn: DateTime.tryParse(j['creadaEn'] as String? ?? ''),
        tipo: j['tipo'] as String? ?? 'Eventos',
        leida: j['leida'] as bool? ?? false,
        pideCalificacion: j['pideCalificacion'] as bool? ?? false,
        idEvento: j['idEvento'] as String? ?? '',
      );
}
