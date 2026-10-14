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
  String imagen; // portada: asset o "base64:..." (imagen elegida de la galería)

  // Segunda imagen (opcional): la que se ve por dentro, en el detalle.
  // Si el organizador solo sube una, el detalle usa la misma portada.
  String? imagenDetalle;

  // ---- Datos extra (opcionales) que usa la pantalla de detalle ----
  bool esHoy; // (dato simulado) el evento es hoy
  String estado; // "Activo", "Finalizado" o "Cancelado"
  String descripcion;
  String fechaLarga; // "10 de Diciembre 2026"
  String horario; // "10:00 AM - 2:00 PM"
  int cuposDisponibles;
  int cuposTotales;
  List<String> incluye;
  List<ItemAgenda> agenda;

  // ---- Datos de los eventos creados por usuarios (se guardan en el celular) ----
  String creadorId; // id del usuario que lo creó ('' = evento de ejemplo)
  String fechaIso; // fecha real "2026-12-24" (para ordenar y saber si ya pasó)
  double precioValor; // precio numérico (0 = gratis), para calcular el recaudo
  int visualizaciones;
  List<String> inscripciones; // fecha-hora (ISO) de cada inscripción

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
    this.creadorId = '',
    this.fechaIso = '',
    this.precioValor = 0,
    this.visualizaciones = 0,
    List<String>? inscripciones,
  }) : inscripciones = inscripciones ?? [];

  List<String> get _partes => fechaCompleta.split(' • ');
  String get hora => _partes.length > 1 ? _partes[1] : '';
  String get anio => _partes.length > 2 ? _partes[2] : '';
  String get imagenParaDetalle => imagenDetalle ?? imagen;
  String get fechaCorta => '$dia de $mes $anio';
  String get fechaParaDetalle => fechaLarga.isNotEmpty ? fechaLarga : fechaCorta;
  String get horarioParaDetalle => horario.isNotEmpty ? horario : hora;
  bool get esGratis => precio.contains('Gratis');

  /// Personas inscritas (solo tiene sentido en eventos con cupos).
  int get inscritos => cuposTotales - cuposDisponibles;

  /// Fecha real del evento (null si es un evento de ejemplo sin fecha real).
  DateTime? get fecha => fechaIso.isEmpty ? null : DateTime.tryParse(fechaIso);

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'categoria': categoria,
        'fechaCompleta': fechaCompleta,
        'dia': dia,
        'mes': mes,
        'lugar': lugar,
        'precio': precio,
        'imagen': imagen,
        'imagenDetalle': imagenDetalle,
        'esHoy': esHoy,
        'estado': estado,
        'descripcion': descripcion,
        'fechaLarga': fechaLarga,
        'horario': horario,
        'cuposDisponibles': cuposDisponibles,
        'cuposTotales': cuposTotales,
        'incluye': incluye,
        'agenda': agenda.map((a) => a.toJson()).toList(),
        'creadorId': creadorId,
        'fechaIso': fechaIso,
        'precioValor': precioValor,
        'visualizaciones': visualizaciones,
        'inscripciones': inscripciones,
      };

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        categoria: j['categoria'] as String? ?? '',
        fechaCompleta: j['fechaCompleta'] as String? ?? '',
        dia: j['dia'] as String? ?? '',
        mes: j['mes'] as String? ?? '',
        lugar: j['lugar'] as String? ?? '',
        precio: j['precio'] as String? ?? '',
        imagen: j['imagen'] as String? ?? '',
        imagenDetalle: j['imagenDetalle'] as String?,
        esHoy: j['esHoy'] as bool? ?? false,
        estado: j['estado'] as String? ?? 'Activo',
        descripcion: j['descripcion'] as String? ?? '',
        fechaLarga: j['fechaLarga'] as String? ?? '',
        horario: j['horario'] as String? ?? '',
        cuposDisponibles: j['cuposDisponibles'] as int? ?? 0,
        cuposTotales: j['cuposTotales'] as int? ?? 0,
        incluye: List<String>.from(j['incluye'] as List? ?? const []),
        agenda: (j['agenda'] as List? ?? const [])
            .map((a) => ItemAgenda.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        creadorId: j['creadorId'] as String? ?? '',
        fechaIso: j['fechaIso'] as String? ?? '',
        precioValor: (j['precioValor'] as num? ?? 0).toDouble(),
        visualizaciones: j['visualizaciones'] as int? ?? 0,
        inscripciones: List<String>.from(j['inscripciones'] as List? ?? const []),
      );
}
