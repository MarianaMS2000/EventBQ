import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
/// Los eventos se sincronizan en vivo con Cloud Firestore (colección 'events').
/// Mantiene un caché en memoria (_publicados y _mapaEventos) alimentado por
/// snapshots en tiempo real. Las lecturas son síncronas desde el caché.
class EventoRepository {
  static final EventoRepository _instancia = EventoRepository._();
  factory EventoRepository() => _instancia;
  EventoRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _kEntradas = 'entradas_compradas';
  static const _kPublicaciones = 'publicaciones';
  static const _kPlanPro = 'plan_organizador_pro';
  static const _kCalificaciones = 'calificaciones';

  // Caché de eventos en memoria
  final List<Evento> _publicados = [];
  final Map<String, Evento> _mapaEventos = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventosSub;
  bool _inicializado = false;

  // Calificaciones: cada una es {evento, usuario, estrellas}.
  final List<Map<String, dynamic>> _calificaciones = [];

  // Datos del usuario con sesión abierta
  String _usuarioCargado = '\u0000';
  List<String> _entradas = []; // ids de los eventos a los que se inscribió
  List<DateTime> _publicaciones = []; // fechas en que publicó eventos
  bool _planPro = false;

  // ---------- ciclo de vida y sincronización ----------

  /// Inicia el listener en tiempo real de la colección 'events' en Firestore.
  Future<void> iniciar(String uid) async {
    _asegurarDatosLocales();
    if (_inicializado) return;
    _inicializado = true;

    // Sembrar eventos iniciales si la base de datos está vacía
    await sembrarDatosIniciales();

    await _eventosSub?.cancel();
    _eventosSub = _firestore.collection('events').snapshots().listen((snap) {
      _publicados.clear();
      _mapaEventos.clear();

      for (final doc in snap.docs) {
        final e = Evento.fromFirestore(doc);
        _actualizarEstadoSiPaso(e);
        _publicados.add(e);
        _mapaEventos[e.id] = e;
      }

      notificarCambios();
    }, onError: (_) {});
  }

  /// Cancela la suscripción a Firestore
  Future<void> cancelar() async {
    await _eventosSub?.cancel();
    _eventosSub = null;
    _inicializado = false;
  }

  /// Sube los eventos de muestra de datos_simulados a Firestore si la colección está vacía.
  Future<void> sembrarDatosIniciales() async {
    try {
      final snap = await _firestore.collection('events').limit(1).get();
      if (snap.docs.isNotEmpty) return; // ya hay datos

      final batch = _firestore.batch();
      final todos = [
        ...datosEventosTop,
        ...datosEventosExplorar,
        ...datosEventosOrganizador,
      ];

      final vistos = <String>{};
      for (final e in todos) {
        if (vistos.contains(e.id)) continue;
        vistos.add(e.id);
        e.creadorId = ''; // '' = evento de muestra
        final ref = _firestore.collection('events').doc(e.id);
        batch.set(ref, e.toFirestore());
      }

      await batch.commit();
    } catch (_) {}
  }

  void _asegurarDatosLocales() {
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

      final rawCal = PreferenciasUsuario.leerTexto(_kCalificaciones);
      if (rawCal != null && _calificaciones.isEmpty) {
        try {
          _calificaciones.addAll((jsonDecode(rawCal) as List)
              .map((j) => Map<String, dynamic>.from(j as Map)));
        } catch (_) {}
      }
    }
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
  void _actualizarEstadoSiPaso(Evento e) {
    final hoy = soloFecha(DateTime.now());
    final f = e.fecha;
    if (e.estado == 'Activo' && f != null && f.isBefore(hoy)) {
      e.estado = 'Finalizado';
    }
  }

  String get _usuarioId => PreferenciasUsuario.usuarioActual;

  // ---------- consultas ----------

  /// Eventos de la pantalla Inicio: los más recientes/destacados Activos.
  List<Evento> obtenerEventosTop() {
    _asegurarDatosLocales();
    final activos = _publicados.where(_esVisible).toList();
    if (activos.isEmpty) {
      return datosEventosTop; // Respaldo sin parpadeo si aún no llegan snapshots
    }
    return activos.reversed.take(6).toList();
  }

  /// Eventos de Explorar: listado completo en vivo de eventos Activos.
  List<Evento> obtenerEventosExplorar() {
    _asegurarDatosLocales();
    final activos = _publicados.where(_esVisible).toList();
    if (activos.isEmpty) {
      return datosEventosExplorar;
    }
    return activos.reversed.toList();
  }

  bool _esVisible(Evento e) => e.estado == 'Activo';

  List<Evento> obtenerEventosDeOrganizador() {
    _asegurarDatosLocales();
    final suyos = _publicados
        .where((e) => e.creadorId == '' || e.creadorId == _usuarioId)
        .toList();
    return suyos.isNotEmpty ? suyos : datosEventosOrganizador;
  }

  /// Eventos que creó un usuario concreto.
  List<Evento> obtenerEventosDeCreador(String idUsuario) {
    _asegurarDatosLocales();
    return _publicados.where((e) => e.creadorId == idUsuario).toList();
  }

  /// Eventos que creó el usuario con sesión (Mis eventos > Mis Eventos Creados).
  List<Evento> obtenerEventosCreados() {
    _asegurarDatosLocales();
    return obtenerEventosDeCreador(_usuarioId).reversed.toList();
  }

  Evento? obtenerEventoPorId(String id) {
    _asegurarDatosLocales();
    if (_mapaEventos.containsKey(id)) {
      return _mapaEventos[id];
    }
    final todosLocales = [
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
    ];
    for (final e in todosLocales) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Busca por texto y aplica los filtros de categoría, fecha y precio en memoria.
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
    _asegurarDatosLocales();
    final vistos = <String>{};
    final resultado = <Evento>[];
    final todos = [
      ..._publicados,
      ...datosEventosTop,
      ...datosEventosExplorar,
      ...datosEventosOrganizador,
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
    _asegurarDatosLocales();
    final lista = <Evento>[];
    for (final id in _entradas) {
      final e = obtenerEventoPorId(id);
      if (e != null) lista.add(e);
    }
    return lista;
  }

  bool estaInscrito(String idEvento) {
    _asegurarDatosLocales();
    return _entradas.contains(idEvento);
  }

  /// Ids de usuarios inscritos a un evento.
  List<String> usuariosInscritos(String idEvento) {
    _asegurarDatosLocales();
    final ids = <String>[];
    for (final u in UsuarioRepository().obtenerCuentas()) {
      final entradas = PreferenciasUsuario.leerLista(
          PreferenciasUsuario.claveDe(_kEntradas, u.id));
      if (entradas.contains(idEvento)) ids.add(u.id);
    }
    return ids;
  }

  /// Inscribe al usuario.
  String? agregarEntrada(Evento evento) {
    _asegurarDatosLocales();
    final e = obtenerEventoPorId(evento.id) ?? evento;
    if (_usuarioId.isEmpty) return 'Inicia sesión para reservar';
    if (_entradas.contains(e.id)) return 'Ya estás inscrito a este evento';
    if (e.creadorId == _usuarioId) {
      return 'No puedes inscribirte a tu propio evento';
    }
    if (e.estado != 'Activo') return 'Este evento ya no está disponible';
    if (e.cuposDisponibles <= 0) return 'No quedan cupos disponibles';

    _entradas.add(e.id);
    _guardarEntradas();
    e.cuposDisponibles--;
    e.inscripciones.add(DateTime.now().toIso8601String());

    if (e.creadorId.isNotEmpty) {
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

  /// Anula la entrada del usuario.
  void anularEntrada(String idEvento) {
    _asegurarDatosLocales();
    if (!_entradas.remove(idEvento)) return;
    _guardarEntradas();
    final e = obtenerEventoPorId(idEvento);
    if (e != null) {
      if (e.cuposDisponibles < e.cuposTotales) e.cuposDisponibles++;
      if (e.inscripciones.isNotEmpty) e.inscripciones.removeLast();
    }
    notificarCambios();
  }

  // ---------- crear / modificar / eliminar eventos ----------

  /// Guarda un evento nuevo en Firestore y cuenta la publicación.
  Future<void> publicarEvento(Evento evento) async {
    _asegurarDatosLocales();
    final uid = _usuarioId;
    evento.creadorId = uid;
    evento.estado = 'Activo';
    evento.cuposDisponibles = evento.cuposTotales;
    evento.visualizaciones = 0;
    evento.ratingSuma = 0.0;
    evento.ratingCantidad = 0;
    evento.creadoEn = DateTime.now();

    // Guardar en Firestore
    await _firestore.collection('events').doc(evento.id).set(evento.toFirestore());

    _publicados.insert(0, evento);
    _mapaEventos[evento.id] = evento;

    _publicaciones.add(DateTime.now());
    _guardarPublicaciones();
    notificarCambios();
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

  /// El organizador cancela su evento.
  void cancelarEvento(String idEvento) {
    _asegurarDatosLocales();
    final ev = obtenerEventoPorId(idEvento);
    if (ev == null) return;
    ev.estado = 'Cancelado';
    _firestore.collection('events').doc(idEvento).update({'estado': 'Cancelado'});
    _avisarInscritos(
      ev,
      'Evento cancelado',
      '"${ev.titulo}" fue cancelado por el organizador',
    );
    notificarCambios();
  }

  /// El organizador cambia fecha y horas.
  void reprogramarEvento(
    String idEvento,
    DateTime fecha,
    TimeOfDay inicio,
    TimeOfDay cierre,
  ) {
    _asegurarDatosLocales();
    final ev = obtenerEventoPorId(idEvento);
    if (ev == null) return;
    aplicarFechaAEvento(ev, fecha, inicio, cierre);
    if (ev.estado == 'Finalizado') ev.estado = 'Activo';
    _firestore.collection('events').doc(idEvento).update(ev.toFirestore());
    _avisarInscritos(
      ev,
      'Evento reprogramado',
      '"${ev.titulo}" ahora es el ${ev.fechaLarga}, ${ev.horario}',
    );
    notificarCambios();
  }

  /// Borra un evento creado por el usuario.
  void eliminarEvento(String idEvento) {
    _asegurarDatosLocales();
    _publicados.removeWhere((p) => p.id == idEvento);
    _mapaEventos.remove(idEvento);
    _entradas.remove(idEvento);
    _guardarEntradas();
    _firestore.collection('events').doc(idEvento).delete();
    notificarCambios();
  }

  /// Suma una visualización (cuando alguien distinto al creador abre el detalle).
  Future<void> registrarVisualizacion(Evento evento) async {
    _asegurarDatosLocales();
    final uid = _usuarioId;
    if (evento.creadorId.isEmpty || (uid.isNotEmpty && evento.creadorId == uid)) return;
    try {
      await _firestore.collection('events').doc(evento.id).update({
        'visualizaciones': FieldValue.increment(1),
      });
      evento.visualizaciones++;
    } catch (_) {}
  }

  // ---------- límite de eventos publicados (plan gratuito) ----------

  List<DateTime> _publicacionesVigentes() {
    final ahora = DateTime.now();
    return _publicaciones.where((d) {
      final vence = DateTime(d.year, d.month + 6, d.day);
      return vence.isAfter(ahora);
    }).toList();
  }

  int get eventosPublicados {
    _asegurarDatosLocales();
    return _publicacionesVigentes().length;
  }

  bool get planOrganizadorActivo {
    _asegurarDatosLocales();
    return _planPro;
  }

  bool get limiteAlcanzado =>
      !planOrganizadorActivo && eventosPublicados >= limiteEventosPeriodo;

  void activarPlanOrganizador() {
    _asegurarDatosLocales();
    _planPro = true;
    PreferenciasUsuario.guardarBool(
      PreferenciasUsuario.claveDe(_kPlanPro, _usuarioCargado),
      true,
    );
    notificarCambios();
  }

  DateTime get fechaProximoEvento {
    _asegurarDatosLocales();
    final vigentes = _publicacionesVigentes()..sort();
    final primera = vigentes.isEmpty ? DateTime.now() : vigentes.first;
    return DateTime(primera.year, primera.month + 6, primera.day);
  }

  // ---------- calificaciones ----------

  bool yaCalifico(String idEvento) {
    _asegurarDatosLocales();
    return _calificaciones
        .any((c) => c['evento'] == idEvento && c['usuario'] == _usuarioId);
  }

  void calificar(String idEvento, int estrellas) {
    _asegurarDatosLocales();
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

  double ratingDeEvento(String idEvento) {
    _asegurarDatosLocales();
    final ev = obtenerEventoPorId(idEvento);
    if (ev != null && ev.ratingCantidad > 0) {
      return ev.ratingPromedio;
    }
    final notas = _calificaciones
        .where((c) => c['evento'] == idEvento)
        .map((c) => c['estrellas'] as int)
        .toList();
    if (notas.isEmpty) return 0;
    return notas.reduce((a, b) => a + b) / notas.length;
  }

  double ratingDeCreador(String idUsuario) {
    _asegurarDatosLocales();
    final suyos = obtenerEventosDeCreador(idUsuario);
    if (suyos.isEmpty) return 0;
    final conRating = suyos.where((e) => e.ratingCantidad > 0).toList();
    if (conRating.isNotEmpty) {
      final totalPuntos =
          conRating.fold(0.0, (acum, e) => acum + e.ratingSuma);
      final totalVotos =
          conRating.fold(0, (acum, e) => acum + e.ratingCantidad);
      return totalVotos > 0 ? totalPuntos / totalVotos : 0.0;
    }
    final ids = suyos.map((e) => e.id).toSet();
    final notas = _calificaciones
        .where((c) => ids.contains(c['evento']))
        .map((c) => c['estrellas'] as int)
        .toList();
    if (notas.isEmpty) return 0;
    return notas.reduce((a, b) => a + b) / notas.length;
  }
}
