import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay, debugPrint;
import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../models/filtros_evento.dart';
import '../models/inscripcion.dart';
import '../preferences/preferencias_usuario.dart';
import '../utils/formato.dart';
import 'cambios.dart';
import 'notificacion_repository.dart';
import 'usuario_repository.dart';

/// Las pantallas piden y guardan los eventos e inscripciones aquí.
///
/// Los datos se sincronizan en tiempo real con Cloud Firestore.
/// Mantiene cachés en memoria alimentados por listeners para lecturas síncronas.
/// Las operaciones que modifican cupos o inscripciones se ejecutan mediante
/// transacciones atómicas (runTransaction).
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

  // Inscripciones del usuario activo: eventoId -> Inscripcion
  final Map<String, Inscripcion> _mapaInscripciones = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscripcionesSub;

  // Favoritos en Firestore: Set de IDs de eventos guardados
  final Set<String> _favoritosIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritosSub;

  bool _inicializado = false;

  // Calificaciones: cada una es {evento, usuario, estrellas}.
  final List<Map<String, dynamic>> _calificaciones = [];

  // Datos locales de respaldo
  String _usuarioCargado = '\u0000';
  List<String> _entradas = []; // ids de los eventos a los que se inscribió
  List<DateTime> _publicaciones = []; // fechas en que publicó eventos
  bool _planPro = false;

  // ---------- ciclo de vida y sincronización ----------

  /// Inicia los listeners en tiempo real de Firestore para eventos, inscripciones y favoritos.
  Future<void> iniciar(String uid) async {
    _asegurarDatosLocales();
    if (_inicializado && _usuarioCargado == uid) return;
    _inicializado = true;

    // Sembrar eventos iniciales si la colección está vacía
    await sembrarDatosIniciales();

    // 1. Escucha en tiempo real de la colección 'events'
    await _eventosSub?.cancel();
    _eventosSub = _firestore.collection('events').snapshots().listen((snap) {
      _publicados.clear();
      _mapaEventos.clear();

      for (final doc in snap.docs) {
        final e = Evento.fromFirestore(doc);
        _actualizarEstadoSiPaso(e);
        if (!_mapaEventos.containsKey(e.id)) {
          _publicados.add(e);
          _mapaEventos[e.id] = e;
        }
      }

      notificarCambios();
    }, onError: (_) {});

    // 2. Escucha de inscripciones del usuario mediante Collection Group
    if (uid.isNotEmpty) {
      await _inscripcionesSub?.cancel();
      _inscripcionesSub = _firestore
          .collectionGroup('inscripciones')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen((snap) {
        _mapaInscripciones.clear();
        _entradas.clear();

        for (final doc in snap.docs) {
          final insc = Inscripcion.fromFirestore(doc);
          if (insc.esActiva) {
            _mapaInscripciones[insc.eventoId] = insc;
            _entradas.add(insc.eventoId);
          }
        }

        _guardarEntradas();
        notificarCambios();
      }, onError: (_) {});

      // 3. Escucha de favoritos en users/{uid}/favoritos
      await _favoritosSub?.cancel();
      _favoritosSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('favoritos')
          .snapshots()
          .listen((snap) {
        _favoritosIds.clear();
        for (final doc in snap.docs) {
          _favoritosIds.add(doc.id);
        }
        notificarCambios();
      }, onError: (_) {});
    }
  }

  /// Cancela todas las suscripciones al cerrar sesión
  Future<void> cancelar() async {
    await _eventosSub?.cancel();
    await _inscripcionesSub?.cancel();
    await _favoritosSub?.cancel();
    _eventosSub = null;
    _inscripcionesSub = null;
    _favoritosSub = null;
    _inicializado = false;
    _mapaInscripciones.clear();
    _favoritosIds.clear();
  }

  /// Sube los eventos de muestra si la base de datos está vacía.
  Future<void> sembrarDatosIniciales() async {
    try {
      final snap = await _firestore.collection('events').limit(1).get();
      if (snap.docs.isNotEmpty) return;

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

  void _actualizarEstadoSiPaso(Evento e) {
    final hoy = soloFecha(DateTime.now());
    final f = e.fecha;
    if (e.estado == 'Activo' && f != null && f.isBefore(hoy)) {
      e.estado = 'Finalizado';
    }
  }

  String get _usuarioId => PreferenciasUsuario.usuarioActual;

  // ---------- consultas ----------

  List<Evento> obtenerEventosTop() {
    _asegurarDatosLocales();
    final vistos = <String>{};
    final activos = <Evento>[];
    for (final e in _publicados) {
      if (_esVisible(e) && vistos.add(e.id)) {
        activos.add(e);
      }
    }
    if (activos.isEmpty) return datosEventosTop;
    return activos.reversed.take(6).toList();
  }

  List<Evento> obtenerEventosExplorar() {
    _asegurarDatosLocales();
    final vistos = <String>{};
    final activos = <Evento>[];
    for (final e in _publicados) {
      if (_esVisible(e) && vistos.add(e.id)) {
        activos.add(e);
      }
    }
    if (activos.isEmpty) return datosEventosExplorar;
    return activos.reversed.toList();
  }

  bool _esVisible(Evento e) => e.estado == 'Activo';

  List<Evento> obtenerEventosDeOrganizador() {
    _asegurarDatosLocales();
    final vistos = <String>{};
    final suyos = <Evento>[];
    for (final e in _publicados) {
      if ((e.creadorId == '' || e.creadorId == _usuarioId) && vistos.add(e.id)) {
        suyos.add(e);
      }
    }
    return suyos.isNotEmpty ? suyos : datosEventosOrganizador;
  }

  List<Evento> obtenerEventosDeCreador(String idUsuario) {
    _asegurarDatosLocales();
    final vistos = <String>{};
    final resultado = <Evento>[];
    for (final e in _publicados) {
      if (e.creadorId == idUsuario && vistos.add(e.id)) {
        resultado.add(e);
      }
    }
    return resultado;
  }

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

  // ---------- favoritos (users/{uid}/favoritos) ----------

  List<Evento> obtenerFavoritos() {
    _asegurarDatosLocales();
    final resultado = <Evento>[];
    for (final id in _favoritosIds) {
      final e = obtenerEventoPorId(id);
      if (e != null) resultado.add(e);
    }
    // Compatibilidad si aún no carga el snapshot remoto
    if (resultado.isEmpty) {
      for (final id in PreferenciasUsuario.favoritos) {
        final e = obtenerEventoPorId(id);
        if (e != null && !resultado.contains(e)) resultado.add(e);
      }
    }
    return resultado;
  }

  List<String> obtenerCategoriasFiltro() => datosCategoriasFiltro;

  List<String> obtenerOpcionesFecha() => datosOpcionesFecha;

  bool esFavorito(String idEvento) {
    if (_favoritosIds.contains(idEvento)) return true;
    return PreferenciasUsuario.esFavorito(idEvento);
  }

  Future<void> alternarFavorito(String idEvento) async {
    final uid = _usuarioId;
    final yaEs = esFavorito(idEvento);

    if (yaEs) {
      _favoritosIds.remove(idEvento);
      if (uid.isNotEmpty) {
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('favoritos')
              .doc(idEvento)
              .delete();
        } catch (_) {}
      }
    } else {
      _favoritosIds.add(idEvento);
      if (uid.isNotEmpty) {
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('favoritos')
              .doc(idEvento)
              .set({'creadoEn': FieldValue.serverTimestamp()});
        } catch (_) {}
      }
    }
    await PreferenciasUsuario.alternarFavorito(idEvento);
    notificarCambios();
  }

  // ---------- entradas (inscripciones atómicas) ----------

  /// Devuelve los eventos a los que el usuario tiene inscripción activa.
  List<Evento> obtenerEntradasCompradas() {
    _asegurarDatosLocales();
    final lista = <Evento>[];
    final ids = _mapaInscripciones.isNotEmpty
        ? _mapaInscripciones.keys.toList()
        : _entradas;

    for (final id in ids) {
      final e = obtenerEventoPorId(id);
      if (e != null && !lista.contains(e)) {
        lista.add(e);
      }
    }
    return lista;
  }

  bool estaInscrito(String idEvento) {
    _asegurarDatosLocales();
    if (_mapaInscripciones.containsKey(idEvento)) {
      return _mapaInscripciones[idEvento]!.esActiva;
    }
    return _entradas.contains(idEvento);
  }

  /// Retorna la inscripción activa asociada a un evento (con su código criptográfico).
  Inscripcion? obtenerInscripcion(String idEvento) {
    return _mapaInscripciones[idEvento];
  }

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

  /// Genera un código criptográficamente seguro de 24 caracteres alfanuméricos.
  String _generarCodigoSeguro() {
    final rnd = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Transacción atómica de inscripción (runTransaction).
  ///
  /// Valida que haya sesión, que el evento esté Activo,
  /// que no esté ya inscrito y que cuposDisponibles > 0.
  /// Crea events/{id}/inscripciones/{uid} con su código y resta 1 a cuposDisponibles.
  Future<String?> agregarEntrada(Evento evento) async {
    _asegurarDatosLocales();
    final uid = _usuarioId;
    if (uid.isEmpty) return 'Inicia sesión para reservar';

    final eventoRef = _firestore.collection('events').doc(evento.id);
    final inscripcionRef = eventoRef.collection('inscripciones').doc(uid);

    try {
      final errorTransaccion =
          await _firestore.runTransaction<String?>((tx) async {
        final evSnap = await tx.get(eventoRef);
        if (!evSnap.exists) {
          return 'Este evento ya no está disponible';
        }

        final evData = evSnap.data()!;
        final estado = evData['estado'] as String? ?? 'Activo';
        if (estado != 'Activo') {
          return 'Este evento ya no está disponible';
        }

        final cuposDisponibles = evData['cuposDisponibles'] as int? ?? 0;
        if (cuposDisponibles <= 0) {
          return 'No quedan cupos disponibles';
        }

        final inscSnap = await tx.get(inscripcionRef);
        if (inscSnap.exists) {
          final inscData = inscSnap.data()!;
          final estadoInsc = inscData['estado'] as String? ?? '';
          if (estadoInsc == 'Activa') {
            return 'Ya estás inscrito a este evento';
          }
        }

        final yo = UsuarioRepository().obtenerUsuarioActual();
        final codigo = _generarCodigoSeguro();

        // 1. Guardar documento en subcolección inscripciones/{uid}
        tx.set(inscripcionRef, {
          'uid': uid,
          'eventoId': evento.id,
          'nombre': yo.nombre.isNotEmpty ? yo.nombre : 'Asistente',
          'creadaEn': FieldValue.serverTimestamp(),
          'precioPagado': evento.precio,
          'estado': 'Activa',
          'codigo': codigo,
          'checkInEn': null,
        });

        // 2. Descontar cupo en el evento
        tx.update(eventoRef, {
          'cuposDisponibles': cuposDisponibles - 1,
        });

        // 3. Notificación para el asistente
        final notifAsistenteRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('notificaciones')
            .doc();
        tx.set(notifAsistenteRef, {
          'titulo': 'Tu inscripción fue confirmada',
          'descripcion': evento.titulo,
          'tipo': 'Eventos',
          'leida': false,
          'pideCalificacion': false,
          'idEvento': evento.id,
          'creadaEn': FieldValue.serverTimestamp(),
        });

        // 4. Notificación para el organizador (si no es el mismo)
        final creadorId = evData['creadorId'] as String? ?? '';
        if (creadorId.isNotEmpty && creadorId != uid) {
          final notifOrgRef = _firestore
              .collection('users')
              .doc(creadorId)
              .collection('notificaciones')
              .doc();
          tx.set(notifOrgRef, {
            'titulo': 'Nueva inscripción',
            'descripcion': '${yo.nombre} se inscribió a "${evento.titulo}"',
            'tipo': 'Organizador',
            'leida': false,
            'pideCalificacion': false,
            'idEvento': evento.id,
            'creadaEn': FieldValue.serverTimestamp(),
          });
        }

        return null;
      });

      if (errorTransaccion != null) {
        return errorTransaccion;
      }

      // Actualizar de inmediato en caché local y memoria
      evento.cuposDisponibles = (evento.cuposDisponibles - 1).clamp(0, evento.cuposTotales);
      if (_mapaEventos.containsKey(evento.id)) {
        _mapaEventos[evento.id]!.cuposDisponibles = evento.cuposDisponibles;
      }

      final yo = UsuarioRepository().obtenerUsuarioActual();
      final inscLocal = Inscripcion(
        uid: uid,
        eventoId: evento.id,
        nombre: yo.nombre,
        creadaEn: DateTime.now(),
        precioPagado: evento.precio,
        codigo: _generarCodigoSeguro(),
      );
      _mapaInscripciones[evento.id] = inscLocal;
      if (!_entradas.contains(evento.id)) {
        _entradas.add(evento.id);
        _guardarEntradas();
      }

      notificarCambios();
      return null;
    } catch (e) {
      debugPrint('Error en agregarEntrada: $e');
      return 'Error al procesar la inscripción: $e';
    }
  }

  /// Transacción atómica para anular la inscripción.
  ///
  /// Marca la inscripción como 'Anulada' (preservando historial)
  /// y libera el cupo (+1 a cuposDisponibles sin superar cuposTotales).
  Future<String?> anularEntrada(String idEvento) async {
    _asegurarDatosLocales();
    final uid = _usuarioId;
    if (uid.isEmpty) return 'No hay una sesión activa';

    final eventoRef = _firestore.collection('events').doc(idEvento);
    final inscripcionRef = eventoRef.collection('inscripciones').doc(uid);

    try {
      final error = await _firestore.runTransaction<String?>((tx) async {
        final evSnap = await tx.get(eventoRef);
        final inscSnap = await tx.get(inscripcionRef);

        if (!inscSnap.exists) {
          return 'No se encontró la inscripción para este evento';
        }

        final inscData = inscSnap.data()!;
        if (inscData['estado'] == 'Anulada') {
          return 'Esta inscripción ya fue anulada';
        }

        // Marcar estado Anulada
        tx.update(inscripcionRef, {
          'estado': 'Anulada',
        });

        // Incrementar cuposDisponibles sin exceder cuposTotales
        if (evSnap.exists) {
          final evData = evSnap.data()!;
          final cuposDisp = evData['cuposDisponibles'] as int? ?? 0;
          final cuposTot = evData['cuposTotales'] as int? ?? 0;
          if (cuposDisp < cuposTot) {
            tx.update(eventoRef, {
              'cuposDisponibles': cuposDisp + 1,
            });
          }
        }

        return null;
      });

      if (error != null) return error;

      // Actualizar de inmediato en caché local
      final ev = obtenerEventoPorId(idEvento);
      if (ev != null) {
        ev.cuposDisponibles = (ev.cuposDisponibles + 1).clamp(0, ev.cuposTotales);
      }

      _entradas.remove(idEvento);
      _mapaInscripciones.remove(idEvento);
      _guardarEntradas();
      notificarCambios();
      return null;
    } catch (e) {
      debugPrint('Error en anularEntrada: $e');
      return 'Error al anular la inscripción';
    }
  }

  // ---------- crear / modificar / eliminar eventos ----------

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

    await _firestore.collection('events').doc(evento.id).set(evento.toFirestore());

    // Asegurar que no se inserte duplicado
    _mapaEventos[evento.id] = evento;
    _publicados.removeWhere((p) => p.id == evento.id);
    _publicados.insert(0, evento);

    _publicaciones.add(DateTime.now());
    _guardarPublicaciones();
    notificarCambios();
  }

  /// Notifica a todos los inscritos activos mediante WriteBatch (hasta 500 ops)
  Future<void> _notificarInscritosActivos(
    String idEvento, {
    required String titulo,
    required String descripcion,
  }) async {
    try {
      final snap = await _firestore
          .collection('events')
          .doc(idEvento)
          .collection('inscripciones')
          .where('estado', isEqualTo: 'Activa')
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        final asistenteUid = doc.id;
        final notifRef = _firestore
            .collection('users')
            .doc(asistenteUid)
            .collection('notificaciones')
            .doc();
        batch.set(notifRef, {
          'titulo': titulo,
          'descripcion': descripcion,
          'tipo': 'Eventos',
          'leida': false,
          'pideCalificacion': false,
          'idEvento': idEvento,
          'creadaEn': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error al notificar inscritos: $e');
    }
  }

  /// Cancela el evento en Firestore y notifica a todos los asistentes activos.
  Future<void> cancelarEvento(String idEvento) async {
    _asegurarDatosLocales();
    final ev = obtenerEventoPorId(idEvento);
    if (ev == null) return;
    ev.estado = 'Cancelado';

    try {
      await _firestore.collection('events').doc(idEvento).update({'estado': 'Cancelado'});
      await _notificarInscritosActivos(
        idEvento,
        titulo: 'Evento cancelado',
        descripcion: '"${ev.titulo}" fue cancelado por el organizador',
      );
    } catch (e) {
      debugPrint('Error en cancelarEvento: $e');
    }

    notificarCambios();
  }

  /// Reprograma el evento en Firestore y notifica a todos los inscritos activos.
  Future<void> reprogramarEvento(
    String idEvento,
    DateTime fecha,
    TimeOfDay inicio,
    TimeOfDay cierre,
  ) async {
    _asegurarDatosLocales();
    final ev = obtenerEventoPorId(idEvento);
    if (ev == null) return;
    aplicarFechaAEvento(ev, fecha, inicio, cierre);
    if (ev.estado == 'Finalizado') ev.estado = 'Activo';

    try {
      await _firestore.collection('events').doc(idEvento).update(ev.toFirestore());
      await _notificarInscritosActivos(
        idEvento,
        titulo: 'Evento reprogramado',
        descripcion: '"${ev.titulo}" ahora es el ${ev.fechaLarga}, ${ev.horario}',
      );
    } catch (e) {
      debugPrint('Error en reprogramarEvento: $e');
    }

    notificarCambios();
  }

  /// Elimina el evento de Firestore y limpia el caché.
  Future<void> eliminarEvento(String idEvento) async {
    _asegurarDatosLocales();
    _publicados.removeWhere((p) => p.id == idEvento);
    _mapaEventos.remove(idEvento);
    _entradas.remove(idEvento);
    _guardarEntradas();

    try {
      await _firestore.collection('events').doc(idEvento).delete();
    } catch (e) {
      debugPrint('Error en eliminarEvento: $e');
    }

    notificarCambios();
  }

  /// Obtiene la lista de inscripciones para un evento concreto (para el organizador)
  Future<List<Inscripcion>> obtenerInscripcionesDeEvento(String idEvento) async {
    try {
      final snap = await _firestore
          .collection('events')
          .doc(idEvento)
          .collection('inscripciones')
          .get();
      return snap.docs.map(Inscripcion.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error en obtenerInscripcionesDeEvento: $e');
      return [];
    }
  }

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

  // ---------- límites y calificaciones ----------

  List<DateTime> _publicacionesVigentes() {
    final ahora = DateTime.now();
    return _publicaciones.where((d) {
      final vence = DateTime(d.year, d.month + 6, d.day);
      return vence.isAfter(ahora);
    }).toList();
  }

  int get eventosPublicados {
    _asegurarDatosLocales();
    final vigentesLocales = _publicacionesVigentes().length;
    final hace180Dias = DateTime.now().subtract(const Duration(days: 180));
    final creadosRecientes = obtenerEventosCreados().where((e) {
      return e.creadoEn != null && e.creadoEn!.isAfter(hace180Dias);
    }).length;
    return creadosRecientes > vigentesLocales ? creadosRecientes : vigentesLocales;
  }

  bool get planOrganizadorActivo {
    final u = UsuarioRepository().obtenerUsuarioActual();
    if (u.planPro) return true;
    _asegurarDatosLocales();
    return _planPro;
  }

  bool get limiteAlcanzado =>
      !planOrganizadorActivo && eventosPublicados >= limiteEventosPeriodo;

  Future<void> activarPlanOrganizador() async {
    _asegurarDatosLocales();
    _planPro = true;
    await PreferenciasUsuario.guardarBool(
      PreferenciasUsuario.claveDe(_kPlanPro, _usuarioCargado),
      true,
    );
    await UsuarioRepository().activarPlanPro();
    notificarCambios();
  }

  DateTime get fechaProximoEvento {
    _asegurarDatosLocales();
    final vigentes = _publicacionesVigentes()..sort();
    final primera = vigentes.isEmpty ? DateTime.now() : vigentes.first;
    return DateTime(primera.year, primera.month + 6, primera.day);
  }

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
