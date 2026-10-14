import 'dart:convert';
import 'package:flutter/material.dart' show TimeOfDay;
import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../models/filtros_evento.dart';
import '../preferences/preferencias_usuario.dart';
import '../utils/formato.dart';
import 'cambios.dart';
import 'notificacion_repository.dart';
import 'usuario_repository.dart';

/// Las pantallas piden y guardan los eventos aquí.
///
/// - Eventos de muestra: salen de datos_simulados.dart (no cambian).
/// - Eventos creados por usuarios: List<Evento> en memoria (_publicados),
///   guardada como JSON en SharedPreferences cada vez que cambia.
/// - Entradas, publicaciones y plan: List por usuario, también en SharedPreferences.
class EventoRepository {
  static final EventoRepository _instancia = EventoRepository._();
  factory EventoRepository() => _instancia;
  EventoRepository._();

  static const _kEventos = 'eventos_publicados';
  static const _kEntradas = 'entradas_compradas';
  static const _kPublicaciones = 'publicaciones';
  static const _kPlanPro = 'plan_organizador_pro';
  static const _kCalificaciones = 'calificaciones';

  // Todos los eventos creados en este celular (de cualquier usuario).
  final List<Evento> _publicados = [];
  bool _eventosCargados = false;

  // Calificaciones: cada una es {evento, usuario, estrellas}.
  final List<Map<String, dynamic>> _calificaciones = [];

  // Datos del usuario con sesión abierta (se recargan si cambia de usuario).
  String _usuarioCargado = '\u0000';
  List<String> _entradas = []; // ids de los eventos a los que se inscribió
  List<DateTime> _publicaciones = []; // fechas en que publicó eventos
  bool _planPro = false;

  // ---------- carga / guardado ----------

  void _asegurarDatos() {
    if (!_eventosCargados) {
      _eventosCargados = true;
      final raw = PreferenciasUsuario.leerTexto(_kEventos);
      if (raw != null) {
        try {
          _publicados.addAll((jsonDecode(raw) as List)
              .map((j) => Evento.fromJson(Map<String, dynamic>.from(j as Map))));
        } catch (_) {}
      }
      final rawCal = PreferenciasUsuario.leerTexto(_kCalificaciones);
      if (rawCal != null) {
        try {
          _calificaciones.addAll((jsonDecode(rawCal) as List)
              .map((j) => Map<String, dynamic>.from(j as Map)));
        } catch (_) {}
      }
      _actualizarEstados();
    }

    final id = PreferenciasUsuario.usuarioActual;
    if (id != _usuarioCargado) {
      _usuarioCargado = id;
      _entradas = PreferenciasUsuario.leerLista(
          PreferenciasUsuario.claveDe(_kEntradas, id));
      _publicaciones = PreferenciasUsuario.leerLista(
              PreferenciasUsuario.claveDe(_kPublicaciones, id))
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();
      _planPro = PreferenciasUsuario.leerBool(
          PreferenciasUsuario.claveDe(_kPlanPro, id));
    }
  }

  void _guardarEventos() {
    PreferenciasUsuario.guardarTexto(
      _kEventos,
      jsonEncode(_publicados.map((e) => e.toJson()).toList()),
    );
    notificarCambios();
  }

  void _guardarEntradas() {
    PreferenciasUsuario.guardarLista(
      PreferenciasUsuario.claveDe(_kEntradas, _usuarioCargado),
      _entradas,
    );
  }

  void _guardarPublicaciones() {
    PreferenciasUsuario.guardarLista(
      PreferenciasUsuario.claveDe(_kPublicaciones, _usuarioCargado),
      _publicaciones.map((d) => d.toIso8601String()).toList(),
    );
  }

  /// Un evento "Activo" cuya fecha ya pasó pasa a "Finalizado".
  void _actualizarEstados() {
    final hoy = soloFecha(DateTime.now());
    var cambio = false;
    for (final e in _publicados) {
      final f = e.fecha;
      if (e.estado == 'Activo' && f != null && f.isBefore(hoy)) {
        e.estado = 'Finalizado';
        cambio = true;
      }
    }
    if (cambio) {
      PreferenciasUsuario.guardarTexto(
        _kEventos,
        jsonEncode(_publicados.map((e) => e.toJson()).toList()),
      );
    }
  }

  String get _usuarioId => PreferenciasUsuario.usuarioActual;

  // ---------- consultas ----------

  /// Eventos de la pantalla Inicio: los de muestra + los últimos publicados.
  List<Evento> obtenerEventosTop() {
    _asegurarDatos();
    final nuevos = _publicados.where(_esVisible).toList().reversed.take(3);
    return [...datosEventosTop, ...nuevos];
  }

  /// Eventos de Explorar: los de muestra + los publicados por usuarios.
  List<Evento> obtenerEventosExplorar() {
    _asegurarDatos();
    final nuevos = _publicados.where(_esVisible).toList().reversed;
    return [...datosEventosExplorar, ...nuevos];
  }

  bool _esVisible(Evento e) => e.estado == 'Activo';

  List<Evento> obtenerEventosDeOrganizador() => datosEventosOrganizador;

  /// Eventos que creó un usuario concreto.
  List<Evento> obtenerEventosDeCreador(String idUsuario) {
    _asegurarDatos();
    return _publicados.where((e) => e.creadorId == idUsuario).toList();
  }

  /// Eventos que creó el usuario con sesión (Mis eventos > Mis Eventos Creados).
  List<Evento> obtenerEventosCreados() {
    _asegurarDatos();
    return obtenerEventosDeCreador(_usuarioId).reversed.toList();
  }

  Evento? obtenerEventoPorId(String id) {
    _asegurarDatos();
    final todos = [
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
      ..._publicados,
    ];
    for (final e in todos) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Busca por texto y aplica los filtros de categoría, fecha y precio.
  List<Evento> buscarEventos(String texto, {FiltrosEvento? filtros}) {
    final t = texto.toLowerCase().trim();
    final hoy = soloFecha(DateTime.now());
    return obtenerEventosExplorar().where((e) {
      if (t.isNotEmpty &&
          !e.titulo.toLowerCase().contains(t) &&
          !e.lugar.toLowerCase().contains(t)) {
        return false;
      }
      if (filtros != null) {
        if (filtros.categorias.isNotEmpty &&
            !filtros.categorias.contains(e.categoria)) {
          return false;
        }
        final f = e.fecha;
        if (filtros.fecha == 'Hoy') {
          final esHoy = f != null ? soloFecha(f) == hoy : e.esHoy;
          if (!esHoy) return false;
        } else if (filtros.fecha == 'Esta semana') {
          // Solo los eventos con fecha real se pueden filtrar.
          if (f == null || f.isBefore(hoy) || f.difference(hoy).inDays > 7) {
            return false;
          }
        } else if (filtros.fecha == 'Este mes') {
          if (f == null || f.year != hoy.year || f.month != hoy.month) {
            return false;
          }
        }
        if (filtros.precio == 'Gratis' && !e.esGratis) return false;
        if (filtros.precio == 'De pago' && e.esGratis) return false;
      }
      return true;
    }).toList();
  }

  /// Eventos con el corazón activado (sin repetir).
  List<Evento> obtenerFavoritos() {
    _asegurarDatos();
    final vistos = <String>{};
    final resultado = <Evento>[];
    final todos = [
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
      ..._publicados,
    ];
    for (final e in todos) {
      if (vistos.contains(e.id)) continue;
      vistos.add(e.id);
      if (PreferenciasUsuario.esFavorito(e.id)) resultado.add(e);
    }
    return resultado;
  }

  List<String> obtenerCategoriasFiltro() => datosCategoriasFiltro;

  List<String> obtenerOpcionesFecha() => datosOpcionesFecha;

  bool esFavorito(String idEvento) => PreferenciasUsuario.esFavorito(idEvento);

  Future<void> alternarFavorito(String idEvento) async {
    await PreferenciasUsuario.alternarFavorito(idEvento);
    notificarCambios();
  }

  // ---------- entradas (inscripciones) ----------

  /// Entradas que compró el usuario (Mis Entradas Compradas).
  List<Evento> obtenerEntradasCompradas() {
    _asegurarDatos();
    final lista = <Evento>[];
    for (final id in _entradas) {
      final e = obtenerEventoPorId(id);
      if (e != null) lista.add(e);
    }
    return lista;
  }

  bool estaInscrito(String idEvento) {
    _asegurarDatos();
    return _entradas.contains(idEvento);
  }

  /// Ids de usuarios inscritos a un evento (revisa las entradas de cada cuenta).
  List<String> usuariosInscritos(String idEvento) {
    _asegurarDatos();
    final ids = <String>[];
    for (final u in UsuarioRepository().obtenerCuentas()) {
      final entradas = PreferenciasUsuario.leerLista(
          PreferenciasUsuario.claveDe(_kEntradas, u.id));
      if (entradas.contains(idEvento)) ids.add(u.id);
    }
    return ids;
  }

  /// Inscribe al usuario. Devuelve null si salió bien, o el motivo del error.
  String? agregarEntrada(Evento evento) {
    _asegurarDatos();
    final e = obtenerEventoPorId(evento.id) ?? evento;
    if (_usuarioId.isEmpty) return 'Inicia sesión para reservar';
    if (_entradas.contains(e.id)) return 'Ya estás inscrito a este evento';
    if (e.creadorId == _usuarioId) {
      return 'No puedes inscribirte a tu propio evento';
    }
    if (e.estado != 'Activo') return 'Este evento ya no está disponible';
    final esPropio = _publicados.any((p) => p.id == e.id);
    if (esPropio && e.cuposDisponibles <= 0) return 'No quedan cupos disponibles';

    _entradas.add(e.id);
    _guardarEntradas();
    if (esPropio) {
      e.cuposDisponibles--;
      e.inscripciones.add(DateTime.now().toIso8601String());
      _guardarEventos();
      final yo = UsuarioRepository().obtenerUsuarioActual();
      NotificacionRepository().agregarA(
        e.creadorId,
        titulo: 'Nueva inscripción',
        descripcion: '${yo.nombre} se inscribió a "${e.titulo}"',
        tipo: 'Organizador',
        idEvento: e.id,
      );
    }
    NotificacionRepository().agregarA(
      _usuarioId,
      titulo: 'Tu inscripción fue confirmada',
      descripcion: e.titulo,
      idEvento: e.id,
    );
    notificarCambios();
    return null;
  }

  /// Anula la entrada del usuario (se quita de la lista y se libera el cupo).
  void anularEntrada(String idEvento) {
    _asegurarDatos();
    if (!_entradas.remove(idEvento)) return;
    _guardarEntradas();
    final e = _publicados.where((p) => p.id == idEvento);
    if (e.isNotEmpty) {
      final ev = e.first;
      if (ev.cuposDisponibles < ev.cuposTotales) ev.cuposDisponibles++;
      if (ev.inscripciones.isNotEmpty) ev.inscripciones.removeLast();
      _guardarEventos();
    }
    notificarCambios();
  }

  // ---------- crear / modificar / eliminar eventos ----------

  /// Guarda un evento nuevo del usuario y cuenta la publicación.
  void publicarEvento(Evento evento) {
    _asegurarDatos();
    evento.creadorId = _usuarioId;
    _publicados.add(evento);
    _guardarEventos();
    _publicaciones.add(DateTime.now());
    _guardarPublicaciones();
  }

  void _avisarInscritos(Evento e, String titulo, String descripcion) {
    for (final id in usuariosInscritos(e.id)) {
      NotificacionRepository().agregarA(
        id,
        titulo: titulo,
        descripcion: descripcion,
        idEvento: e.id,
      );
    }
  }

  /// El organizador cancela su evento: se avisa a los inscritos.
  void cancelarEvento(String idEvento) {
    _asegurarDatos();
    final e = _publicados.where((p) => p.id == idEvento);
    if (e.isEmpty) return;
    final ev = e.first;
    ev.estado = 'Cancelado';
    _guardarEventos();
    _avisarInscritos(
      ev,
      'Evento cancelado',
      '"${ev.titulo}" fue cancelado por el organizador',
    );
  }

  /// El organizador cambia fecha y horas: se avisa a los inscritos.
  void reprogramarEvento(
    String idEvento,
    DateTime fecha,
    TimeOfDay inicio,
    TimeOfDay cierre,
  ) {
    _asegurarDatos();
    final e = _publicados.where((p) => p.id == idEvento);
    if (e.isEmpty) return;
    final ev = e.first;
    aplicarFechaAEvento(ev, fecha, inicio, cierre);
    if (ev.estado == 'Finalizado') ev.estado = 'Activo';
    _guardarEventos();
    _avisarInscritos(
      ev,
      'Evento reprogramado',
      '"${ev.titulo}" ahora es el ${ev.fechaLarga}, ${ev.horario}',
    );
  }

  /// Borra un evento creado por el usuario.
  void eliminarEvento(String idEvento) {
    _asegurarDatos();
    _publicados.removeWhere((p) => p.id == idEvento);
    _entradas.remove(idEvento);
    _guardarEntradas();
    _guardarEventos();
  }

  /// Suma una visualización (cuando alguien distinto al creador abre el detalle).
  void registrarVisualizacion(Evento evento) {
    _asegurarDatos();
    if (evento.creadorId.isEmpty || evento.creadorId == _usuarioId) return;
    final e = _publicados.where((p) => p.id == evento.id);
    if (e.isEmpty) return;
    e.first.visualizaciones++;
    // Se guarda sin avisar a las pantallas (se llama mientras se abre el detalle).
    PreferenciasUsuario.guardarTexto(
      _kEventos,
      jsonEncode(_publicados.map((x) => x.toJson()).toList()),
    );
  }

  // ---------- límite de eventos publicados (plan gratuito) ----------

  /// Publicaciones del usuario dentro de los últimos 6 meses.
  List<DateTime> _publicacionesVigentes() {
    final ahora = DateTime.now();
    return _publicaciones.where((d) {
      final vence = DateTime(d.year, d.month + 6, d.day);
      return vence.isAfter(ahora);
    }).toList();
  }

  int get eventosPublicados {
    _asegurarDatos();
    return _publicacionesVigentes().length;
  }

  /// Con el plan Organizador Pro no hay límite (eventos ilimitados).
  bool get planOrganizadorActivo {
    _asegurarDatos();
    return _planPro;
  }

  bool get limiteAlcanzado =>
      !planOrganizadorActivo && eventosPublicados >= limiteEventosPeriodo;

  /// Se llama al terminar de pagar el plan Organizador Pro.
  void activarPlanOrganizador() {
    _asegurarDatos();
    _planPro = true;
    PreferenciasUsuario.guardarBool(
      PreferenciasUsuario.claveDe(_kPlanPro, _usuarioCargado),
      true,
    );
    notificarCambios();
  }

  /// Fecha desde la que podrá publicar otro (6 meses tras la primera vigente).
  DateTime get fechaProximoEvento {
    _asegurarDatos();
    final vigentes = _publicacionesVigentes()..sort();
    final primera = vigentes.isEmpty ? DateTime.now() : vigentes.first;
    return DateTime(primera.year, primera.month + 6, primera.day);
  }

  // ---------- calificaciones ----------

  bool yaCalifico(String idEvento) {
    _asegurarDatos();
    return _calificaciones
        .any((c) => c['evento'] == idEvento && c['usuario'] == _usuarioId);
  }

  void calificar(String idEvento, int estrellas) {
    _asegurarDatos();
    _calificaciones.removeWhere(
        (c) => c['evento'] == idEvento && c['usuario'] == _usuarioId);
    _calificaciones.add({
      'evento': idEvento,
      'usuario': _usuarioId,
      'estrellas': estrellas,
    });
    PreferenciasUsuario.guardarTexto(
        _kCalificaciones, jsonEncode(_calificaciones));
    NotificacionRepository().quitarPedidoCalificacion(idEvento);
  }

  /// Promedio de estrellas de un evento (0 si nadie lo calificó).
  double ratingDeEvento(String idEvento) {
    _asegurarDatos();
    final notas = _calificaciones
        .where((c) => c['evento'] == idEvento)
        .map((c) => c['estrellas'] as int)
        .toList();
    if (notas.isEmpty) return 0;
    return notas.reduce((a, b) => a + b) / notas.length;
  }

  /// Promedio de estrellas de todos los eventos de un organizador.
  double ratingDeCreador(String idUsuario) {
    _asegurarDatos();
    final ids = obtenerEventosDeCreador(idUsuario).map((e) => e.id).toSet();
    final notas = _calificaciones
        .where((c) => ids.contains(c['evento']))
        .map((c) => c['estrellas'] as int)
        .toList();
    if (notas.isEmpty) return 0;
    return notas.reduce((a, b) => a + b) / notas.length;
  }
}
