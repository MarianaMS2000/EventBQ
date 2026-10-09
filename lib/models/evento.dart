import 'item_agenda.dart';

class Evento {
  String id;
  String titulo;
  String categoria;
  String fechaCompleta; // "Nov 27 • 08:00 PM • 2026"
  String dia; // "18"
  String mes; // "Dic"
  String lugar;
  String precio; // "$ 25.00", "$ Gratis"
  String imagen; // portada: la que se ve por fuera (tarjetas, tickets...)

  // Segunda imagen (opcional): la que se ve por dentro, en el detalle.
  // Si el organizador solo sube una, el detalle usa la misma portada.
  String? imagenDetalle;

  // ---- Datos extra (opcionales) que usa la pantalla de detalle ----
  bool esHoy; // (dato simulado) el evento es hoy
  String estado; // "Activo" o "Finalizado" (perfil del organizador)
  String descripcion;
  String fechaLarga; // "10 de Diciembre 2026"
  String horario; // "10:00 AM - 2:00 PM"
  int cuposDisponibles;
  int cuposTotales;
  List<String> incluye;
  List<ItemAgenda> agenda;

  Evento({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.fechaCompleta,
    required this.dia,
    required this.mes,
    required this.lugar,
    required this.precio,
    required this.imagen,
    this.imagenDetalle,
    this.esHoy = false,
    this.estado = 'Activo',
    this.descripcion = '',
    this.fechaLarga = '',
    this.horario = '',
    this.cuposDisponibles = 0,
    this.cuposTotales = 0,
    this.incluye = const [],
    this.agenda = const [],
  });

  List<String> get _partes => fechaCompleta.split(' • ');
  String get hora => _partes.length > 1 ? _partes[1] : '';
  String get anio => _partes.length > 2 ? _partes[2] : '';
  String get imagenParaDetalle => imagenDetalle ?? imagen;
  String get fechaCorta => '$dia de $mes $anio';
  String get fechaParaDetalle => fechaLarga.isNotEmpty ? fechaLarga : fechaCorta;
  String get horarioParaDetalle => horario.isNotEmpty ? horario : hora;
  bool get esGratis => precio.contains('Gratis');
}
