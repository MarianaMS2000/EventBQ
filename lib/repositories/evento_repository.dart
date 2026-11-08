import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show TimeOfDay, debugPrint;
import '../data/datos_simulados.dart';
import '../models/evento.dart';
import '../models/filtros_evento.dart';
import '../preferences/preferencias_usuario.dart';
import '../utils/compresion_imagen.dart';
import '../utils/formato.dart';
import '../utils/manejo_errores.dart';
import '../widgets/imagen_asset.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Límite anti-abuso de entradas por persona para un mismo evento
  static const int maxEntradasPorUsuarioPorEvento = 10;

  // Caché de eventos en memoria
  final List<Evento> _publicados = [];
  final Map<String, Evento> _mapaEventos = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventosSub;

  // Lista de todas las entradas del usuario (múltiples por evento permitidas)
  final List<Inscripcion> _misInscripciones = [];
  // Mapeo de compatibilidad rápida: eventoId -> última inscripción
  Map<String, Inscripcion>? _mapaInscripciones = {};
  Map<String, Inscripcion> get _inscripciones => _mapaInscripciones ??= {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inscripcionesSub;

  // Favoritos en Firestore: Set de IDs de eventos guardados
  Set<String>? _favoritosIds = {};
  Set<String> get _favoritos => _favoritosIds ??= <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritosSub;

  bool _inicializado = false;

  // Calificaciones realizadas por el usuario activo en la sesión
  final Set<String> _calificados = {};

  String _usuarioCargado = '\u0000';

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
        if (uid.isNotEmpty) {
          _cargarInscripcionDirecta(doc.id, uid);
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
        _misInscripciones.clear();
        _mapaInscripciones?.clear();

        for (final doc in snap.docs) {
          final insc = Inscripcion.fromFirestore(doc);
          _misInscripciones.add(insc);
          if (insc.esActiva) {
            _mapaInscripciones?[insc.eventoId] = insc;
          }
        }

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
        _favoritos.clear();
        for (final doc in snap.docs) {
          _favoritos.add(doc.id);
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
    _misInscripciones.clear();
    _inscripciones.clear();
    _favoritos.clear();
    _calificados.clear();
  }

  Future<void> _cargarInscripcionDirecta(String idEvento, String uid) async {
    try {
      final snap = await _firestore
          .collection('events')
          .doc(idEvento)
          .collection('inscripciones')
          .where('uid', isEqualTo: uid)
          .get();

      for (final doc in snap.docs) {
        final insc = Inscripcion.fromFirestore(doc, eventoId: idEvento);
        if (!_misInscripciones.any((i) => i.id == insc.id)) {
          _misInscripciones.add(insc);
        }
        if (insc.esActiva) {
          _mapaInscripciones?[idEvento] = insc;
        }
      }
      notificarCambios();
    } catch (_) {}
  }

  /// Sube los eventos de muestra si la base de datos está vacía,
  /// o actualiza sus coordenadas si aún no las tenían.
  Future<void> sembrarDatosIniciales() async {
    try {
      final todos = [
        ...datosEventosTop,
        ...datosEventosExplorar,
        ...datosEventosOrganizador,
      ];

      final snap = await _firestore.collection('events').limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        final vistos = <String>{};
        for (final e in todos) {
          if (vistos.contains(e.id)) continue;
          vistos.add(e.id);
          e.creadorId = ''; // '' = evento de muestra
          final ref = _firestore.collection('events').doc(e.id);
          batch.set(ref, e.toFirestore());
        }
        await batch.commit();
        return;
      }

      // Si ya existen pero no tienen ubicación o cupos, actualizamos
      final e1Doc = await _firestore.collection('events').doc('e1').get();
      if (e1Doc.exists) {
        final data = e1Doc.data()!;
        final sinUbicacion = !data.containsKey('ubicacion') || data['ubicacion'] == null;
        final sinCupos = (data['cuposTotales'] as int? ?? 0) <= 0;
        if (sinUbicacion || sinCupos) {
          final batch = _firestore.batch();
          final vistos = <String>{};
          for (final e in todos) {
            if (vistos.contains(e.id)) continue;
            vistos.add(e.id);
            final updates = <String, dynamic>{};
            if (e.ubicacion != null) updates['ubicacion'] = e.ubicacion;
            if (e.cuposTotales > 0) {
              updates['cuposTotales'] = e.cuposTotales;
              updates['cuposDisponibles'] = e.cuposDisponibles;
            }
            if (updates.isNotEmpty) {
              batch.update(_firestore.collection('events').doc(e.id), updates);
            }
          }
          await batch.commit();
        }
      }
    } catch (_) {}
  }

  void _asegurarDatosLocales() {
    _usuarioCargado = PreferenciasUsuario.usuarioActual;
  }

  void _actualizarEstadoSiPaso(Evento e) {
    final hoy = soloFecha(DateTime.now());
    final f = e.fecha;
    if (e.estado == 'Activo' && f != null && f.isBefore(hoy)) {
      e.estado = 'Finalizado';
    }
  }

  String get _usuarioId {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;
    return PreferenciasUsuario.usuarioActual;
  }

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

  bool _esVisible(Evento e) => e.estado == 'Activo' && !e.haFinalizado;

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
    for (final id in _favoritos) {
      final e = obtenerEventoPorId(id);
      if (e != null) resultado.add(e);
    }
    return resultado;
  }

  List<String> obtenerCategoriasFiltro() => datosCategoriasFiltro;

  List<String> obtenerOpcionesFecha() => datosOpcionesFecha;

  bool esFavorito(String idEvento) {
    return _favoritos.contains(idEvento);
  }

  Future<void> alternarFavorito(String idEvento) async {
    final uid = _usuarioId;
    final yaEs = esFavorito(idEvento);

    if (yaEs) {
      _favoritos.remove(idEvento);
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
      _favoritos.add(idEvento);
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
    notificarCambios();
  }

  // ---------- entradas (inscripciones atómicas) ----------

  /// Devuelve los eventos únicos a los que el usuario tiene entradas activas o asistidas.
  List<Evento> obtenerEntradasCompradas() {
    final vistos = <String>{};
    final lista = <Evento>[];
    for (final i in _misInscripciones) {
      if ((i.esActiva || i.asistio) && vistos.add(i.eventoId)) {
        final e = obtenerEventoPorId(i.eventoId);
        if (e != null) lista.add(e);
      }
    }
    // Fallback con mapa rápido
    for (final id in _inscripciones.keys) {
      if (vistos.add(id)) {
        final e = obtenerEventoPorId(id);
        if (e != null) lista.add(e);
      }
    }
    return lista;
  }

  /// Retorna todas las entradas del usuario ordenadas por fecha de compra descendente
  List<Inscripcion> obtenerTodasMisInscripciones() {
    _asegurarDatosLocales();
    final lista = _misInscripciones.where((i) => i.esActiva || i.asistio).toList();
    lista.sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    return lista;
  }

  /// Retorna las entradas activas que tiene el usuario actual para un evento específico
  List<Inscripcion> obtenerMisEntradasDeEvento(String idEvento) {
    _asegurarDatosLocales();
    return _misInscripciones
        .where((i) => i.eventoId == idEvento && (i.esActiva || i.asistio))
        .toList();
  }

  /// Número de entradas activas/asistidas que tiene el usuario actual para este evento
  int contarEntradasDeEvento(String idEvento) {
    return obtenerMisEntradasDeEvento(idEvento).length;
  }

  /// Indica si el usuario actual tiene al menos una entrada activa o asistida para el evento
  bool estaInscrito(String idEvento) {
    return contarEntradasDeEvento(idEvento) > 0 ||
        (_inscripciones.containsKey(idEvento) && _inscripciones[idEvento]!.esActiva);
  }

  /// Retorna una inscripción concreta o la más reciente asociada al evento
  Inscripcion? obtenerInscripcion(String idEvento, {String? inscripcionId}) {
    if (inscripcionId != null && inscripcionId.isNotEmpty) {
      for (final i in _misInscripciones) {
        if (i.id == inscripcionId) return i;
      }
    }
    final misEntradas = obtenerMisEntradasDeEvento(idEvento);
    if (misEntradas.isNotEmpty) return misEntradas.first;
    return _inscripciones[idEvento];
  }

  /// Obtiene la última inscripción adquirida para un evento
  Inscripcion? obtenerUltimaInscripcion(String idEvento) {
    return obtenerInscripcion(idEvento);
  }

  /// Genera un código criptográficamente seguro de 24 caracteres alfanuméricos.
  String _generarCodigoSeguro() {
    final rnd = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Transacción atómica de inscripción (runTransaction).
  ///
  /// Valida que haya sesión, que el evento esté Activo y no haya finalizado,
  /// que no supere el límite anti-abuso de 10 entradas y que cuposDisponibles > 0.
  /// Crea un nuevo documento events/{id}/inscripciones/{autoId} con su propio código
  /// y resta 1 a cuposDisponibles.
  Future<String?> agregarEntrada(Evento evento) async {
    _asegurarDatosLocales();
    final uid = _auth.currentUser?.uid.isNotEmpty == true
        ? _auth.currentUser!.uid
        : _usuarioId;
    if (uid.isEmpty) return 'Inicia sesión para reservar';

    if (evento.creadorId.isNotEmpty && evento.creadorId == uid) {
      return 'No puedes inscribirte a tu propio evento';
    }

    if (evento.haFinalizado) {
      return 'Este evento ya finalizó';
    }

    final eventoRef = _firestore.collection('events').doc(evento.id);
    final nuevaInscripcionRef = eventoRef.collection('inscripciones').doc();
    final codigo = _generarCodigoSeguro();

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

        // Validación de fecha de finalización (Capa 2: transacción)
        final fechaFinTimestamp = evData['fechaFin'] as Timestamp?;
        if (fechaFinTimestamp != null &&
            Timestamp.now().compareTo(fechaFinTimestamp) >= 0) {
          return 'Este evento ya finalizó';
        }

        final cuposDisponibles = evData['cuposDisponibles'] as int? ?? 0;
        if (cuposDisponibles <= 0) {
          return 'Ya no quedan cupos para este evento';
        }

        // Límite anti-abuso: máximo 10 entradas por usuario por evento
        final querySnap = await eventoRef
            .collection('inscripciones')
            .where('uid', isEqualTo: uid)
            .get();
        final activasUsuario = querySnap.docs.where((d) {
          final st = d.data()['estado'] as String? ?? '';
          return st == 'Activa' || st == 'Asistio';
        }).length;

        if (activasUsuario >= maxEntradasPorUsuarioPorEvento) {
          return 'Llegaste al máximo de entradas para este evento.';
        }

        final yo = UsuarioRepository().obtenerUsuarioActual();

        // 1. Guardar documento en subcolección inscripciones/{autoId}
        tx.set(nuevaInscripcionRef, {
          'id': nuevaInscripcionRef.id,
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
          'descripcion': 'Entrada confirmada para "${evento.titulo}"',
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
            'descripcion': '${yo.nombre} compró una entrada para "${evento.titulo}"',
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

      // Actualizar de inmediato en memoria y caché local
      evento.cuposDisponibles = (evento.cuposDisponibles - 1).clamp(0, evento.cuposTotales);
      if (_mapaEventos.containsKey(evento.id)) {
        _mapaEventos[evento.id]!.cuposDisponibles = evento.cuposDisponibles;
      }

      final yo = UsuarioRepository().obtenerUsuarioActual();
      final inscLocal = Inscripcion(
        id: nuevaInscripcionRef.id,
        uid: uid,
        eventoId: evento.id,
        nombre: yo.nombre,
        creadaEn: DateTime.now(),
        precioPagado: evento.precio,
        codigo: codigo,
      );
      _misInscripciones.insert(0, inscLocal);
      _mapaInscripciones?[evento.id] = inscLocal;
      notificarCambios();
      return null;
    } catch (e) {
      debugPrint('Error en agregarEntrada: $e');
      return 'Error al procesar la inscripción: $e';
    }
  }

  /// Transacción atómica para anular una entrada específica.
  ///
  /// Marca la inscripción como 'Anulada' (preservando historial)
  /// y libera el cupo (+1 a cuposDisponibles sin superar cuposTotales).
  Future<String?> anularEntrada(String idEvento, [String? idInscripcion]) async {
    _asegurarDatosLocales();
    final uid = _auth.currentUser?.uid.isNotEmpty == true
        ? _auth.currentUser!.uid
        : _usuarioId;
    if (uid.isEmpty) return 'No hay una sesión activa';

    final eventoRef = _firestore.collection('events').doc(idEvento);
    DocumentReference<Map<String, dynamic>> inscripcionRef;

    if (idInscripcion != null && idInscripcion.isNotEmpty) {
      inscripcionRef = eventoRef.collection('inscripciones').doc(idInscripcion);
    } else {
      final deEvento = obtenerMisEntradasDeEvento(idEvento);
      if (deEvento.isNotEmpty && deEvento.first.id.isNotEmpty) {
        inscripcionRef = eventoRef.collection('inscripciones').doc(deEvento.first.id);
      } else {
        inscripcionRef = eventoRef.collection('inscripciones').doc(uid);
      }
    }

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

      _misInscripciones.removeWhere((i) => i.id == inscripcionRef.id);
      if (_mapaInscripciones?[idEvento]?.id == inscripcionRef.id) {
        final restantes = obtenerMisEntradasDeEvento(idEvento);
        if (restantes.isNotEmpty) {
          _mapaInscripciones?[idEvento] = restantes.first;
        } else {
          _mapaInscripciones?.remove(idEvento);
        }
      }

      notificarCambios();
      return null;
    } catch (e) {
      debugPrint('Error en anularEntrada: $e');
      return 'Error al anular la inscripción';
    }
  }

  // ---------- crear / modificar / eliminar eventos ----------

  /// Publica un evento garantizando que el documento no exceda 1 MB (Plan B).
  ///
  /// Guarda en el documento principal solo una miniatura (< 35 KB) y traslada
  /// las imágenes completas a subcolecciones events/{id}/imagenes.
  Future<void> publicarEvento(
    Evento evento, {
    List<Uint8List> bytesImagenes = const [],
  }) async {
    _asegurarDatosLocales();
    final uid = _auth.currentUser?.uid.isNotEmpty == true
        ? _auth.currentUser!.uid
        : _usuarioId;

    if (uid.isEmpty) {
      throw const ValidacionException('Debes iniciar sesión para publicar un evento.');
    }

    evento.creadorId = uid;
    evento.estado = 'Activo';
    evento.cuposDisponibles = evento.cuposTotales;
    evento.visualizaciones = 0;
    evento.ratingSuma = 0.0;
    evento.ratingCantidad = 0;
    evento.creadoEn = DateTime.now();

    // Plan B: Manejo de imágenes de alta resolución en subcolecciones
    String? fullPortada;
    String? fullDetalle;

    if (bytesImagenes.isNotEmpty) {
      fullPortada = ImagenAsset.bytesATexto(bytesImagenes[0]);
      if (bytesImagenes.length > 1) {
        fullDetalle = ImagenAsset.bytesATexto(bytesImagenes[1]);
      }
    }

    // Miniatura pequeña (< 35 KB) para el documento principal
    if (bytesImagenes.isNotEmpty) {
      final miniatura = await generarMiniaturaBase64(bytesImagenes[0], maxAncho: 360);
      evento.imagen = miniatura;
      evento.imagenDetalle = fullDetalle != null ? 'subcoleccion:detalle' : null;
    } else if (evento.imagen.startsWith('base64:')) {
      // Si la imagen venía en base64 en el objeto evento, asegurar miniatura
      final bytes = ImagenAsset.textoABytes(evento.imagen);
      if (bytes != null && bytes.lengthInBytes > 35 * 1024) {
        fullPortada = evento.imagen;
        evento.imagen = await generarMiniaturaBase64(bytes, maxAncho: 360);
        evento.imagenDetalle = null;
      }
    }

    final dataDoc = evento.toFirestore();
    final bytesEstimados = estimarTamanoDocumentoFirestore(dataDoc);
    if (bytesEstimados > 850 * 1024) {
      throw const ValidacionException(
        'El evento contiene demasiada información o imágenes muy pesadas. Elige imágenes más livianas.',
        titulo: 'Imagen demasiado pesada',
      );
    }

    // 1. Guardar documento principal del evento en Firestore
    await _firestore.collection('events').doc(evento.id).set(dataDoc);

    // 2. Guardar subcolección de imágenes de alta resolución si existen
    if (fullPortada != null) {
      try {
        await _firestore
            .collection('events')
            .doc(evento.id)
            .collection('imagenes')
            .doc('portada')
            .set({'data': fullPortada, 'tipo': 'portada'});

        if (fullDetalle != null) {
          await _firestore
              .collection('events')
              .doc(evento.id)
              .collection('imagenes')
              .doc('detalle')
              .set({'data': fullDetalle, 'tipo': 'detalle'});
        }
      } catch (e) {
        debugPrint('Aviso al guardar imágenes en subcolección: $e');
      }
    }

    // Asegurar que no se inserte duplicado en listas en memoria
    _mapaEventos[evento.id] = evento;
    _publicados.removeWhere((p) => p.id == evento.id);
    _publicados.insert(0, evento);

    notificarCambios();
  }

  /// Carga la imagen de alta resolución desde la subcolección del evento (Plan B)
  Future<String?> obtenerImagenGrande(String eventoId, String tipo) async {
    try {
      final doc = await _firestore
          .collection('events')
          .doc(eventoId)
          .collection('imagenes')
          .doc(tipo)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['data'] as String?;
      }
    } catch (e) {
      debugPrint('No se pudo cargar imagen grande ($tipo): $e');
    }
    return null;
  }

  /// Notifica a todos los compradores activos de un evento con una sola notificación por usuario,
  /// respetando el límite de 500 operaciones por WriteBatch de Firestore.
  Future<void> _notificarCompradoresActivos(
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

      final uidsUnicos = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = (data['uid'] as String?)?.isNotEmpty == true
            ? data['uid'] as String
            : doc.id;
        if (uid.isNotEmpty) {
          uidsUnicos.add(uid);
        }
      }

      if (uidsUnicos.isEmpty) return;

      final listaUids = uidsUnicos.toList();
      const int tamanoBatch = 450;
      for (int i = 0; i < listaUids.length; i += tamanoBatch) {
        final lote = listaUids.sublist(
          i,
          (i + tamanoBatch > listaUids.length) ? listaUids.length : i + tamanoBatch,
        );
        final batch = _firestore.batch();
        for (final asistenteUid in lote) {
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
      }
    } catch (e) {
      debugPrint('Error al notificar compradores: $e');
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
      await _notificarCompradoresActivos(
        idEvento,
        titulo: 'Evento cancelado',
        descripcion: '"${ev.titulo}" fue cancelado por el organizador',
      );
    } catch (e) {
      debugPrint('Error en cancelarEvento: $e');
    }

    notificarCambios();
  }

  /// Reprograma el evento en Firestore y notifica con un único aviso a los compradores.
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
      await _notificarCompradoresActivos(
        idEvento,
        titulo: 'Evento reprogramado',
        descripcion: '"${ev.titulo}" ahora es el ${ev.fechaLarga}, ${ev.horario}',
      );
    } catch (e) {
      debugPrint('Error en reprogramarEvento: $e');
    }

    notificarCambios();
  }

  /// Elimina el evento de Firestore borrando también sus subcolecciones (entradas, imágenes, calificaciones)
  Future<void> eliminarEvento(String idEvento) async {
    _asegurarDatosLocales();
    final evRef = _firestore.collection('events').doc(idEvento);

    try {
      // 1. Borrar subcolección de inscripciones
      final inscSnap = await evRef.collection('inscripciones').get();
      final batch = _firestore.batch();
      for (final d in inscSnap.docs) {
        batch.delete(d.reference);
      }

      // 2. Borrar subcolección de imágenes
      final imgSnap = await evRef.collection('imagenes').get();
      for (final d in imgSnap.docs) {
        batch.delete(d.reference);
      }

      // 3. Borrar subcolección de calificaciones
      final califSnap = await evRef.collection('calificaciones').get();
      for (final d in califSnap.docs) {
        batch.delete(d.reference);
      }

      // 4. Borrar documento del evento
      batch.delete(evRef);
      await batch.commit();
    } catch (e) {
      debugPrint('Error al eliminar evento: $e');
    }

    _publicados.removeWhere((p) => p.id == idEvento);
    _mapaEventos.remove(idEvento);
    _misInscripciones.removeWhere((i) => i.eventoId == idEvento);
    _mapaInscripciones?.remove(idEvento);

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

  int get eventosPublicados {
    final hace180Dias = DateTime.now().subtract(const Duration(days: 180));
    return obtenerEventosCreados().where((e) {
      return e.creadoEn != null && e.creadoEn!.isAfter(hace180Dias);
    }).length;
  }

  bool get planOrganizadorActivo {
    return UsuarioRepository().obtenerUsuarioActual().planPro;
  }

  bool get limiteAlcanzado =>
      !planOrganizadorActivo && eventosPublicados >= limiteEventosPeriodo;

  Future<void> activarPlanOrganizador() async {
    await UsuarioRepository().activarPlanPro();
    notificarCambios();
  }

  DateTime get fechaProximoEvento {
    final creados = obtenerEventosCreados()
      ..sort((a, b) => (a.creadoEn ?? DateTime.now()).compareTo(b.creadoEn ?? DateTime.now()));
    final primera = creados.isEmpty ? DateTime.now() : (creados.first.creadoEn ?? DateTime.now());
    return DateTime(primera.year, primera.month + 6, primera.day);
  }

  bool yaCalifico(String idEvento) {
    return _calificados.contains(idEvento);
  }

  Future<void> calificar(String idEvento, int estrellas) async {
    final uid = _usuarioId;
    if (uid.isEmpty) return;

    _calificados.add(idEvento);

    try {
      final batch = _firestore.batch();

      final califRef = _firestore
          .collection('events')
          .doc(idEvento)
          .collection('calificaciones')
          .doc(uid);
      batch.set(califRef, {
        'estrellas': estrellas,
        'creadaEn': FieldValue.serverTimestamp(),
      });

      final evRef = _firestore.collection('events').doc(idEvento);
      batch.update(evRef, {
        'ratingCantidad': FieldValue.increment(1),
        'ratingSuma': FieldValue.increment(estrellas.toDouble()),
      });

      await batch.commit();

      final ev = obtenerEventoPorId(idEvento);
      if (ev != null) {
        ev.ratingCantidad++;
        ev.ratingSuma += estrellas;
      }
    } catch (e) {
      debugPrint('Error al guardar calificación en Firestore: $e');
    }

    await NotificacionRepository().quitarPedidoCalificacion(idEvento);
    notificarCambios();
  }

  double ratingDeEvento(String idEvento) {
    final ev = obtenerEventoPorId(idEvento);
    if (ev != null && ev.ratingCantidad > 0) {
      return ev.ratingPromedio;
    }
    return 0.0;
  }

  double ratingDeCreador(String idUsuario) {
    final suyos = obtenerEventosDeCreador(idUsuario);
    if (suyos.isEmpty) return 0.0;
    final conRating = suyos.where((e) => e.ratingCantidad > 0).toList();
    if (conRating.isNotEmpty) {
      final totalPuntos =
          conRating.fold(0.0, (acum, e) => acum + e.ratingSuma);
      final totalVotos =
          conRating.fold(0, (acum, e) => acum + e.ratingCantidad);
      return totalVotos > 0 ? totalPuntos / totalVotos : 0.0;
    }
    return 0.0;
  }

  /// Valida el acceso de un asistente al evento (Control de Acceso en puerta).
  ///
  /// Lee el QR o código de entrada, verifica en Firestore que pertenezca al evento,
  /// que el organizador tenga permisos, que la entrada esté 'Activa' y no haya sido
  /// usada ('Asistio') ni 'Anulada'.
  /// En una transacción atómica marca estado = 'Asistio' y checkInEn = serverTimestamp().
  /// Responde en ≤ 3 segundos.
  Future<ResultadoValidacion> validarAcceso({
    required String qrOPayload,
    String? eventoIdSeleccionado,
  }) async {
    _asegurarDatosLocales();
    final uidOrganizador = _usuarioId;
    if (uidOrganizador.isEmpty) {
      return ResultadoValidacion(
        exito: false,
        mensaje: 'Inicia sesión como organizador para validar',
      );
    }

    // 1. Extraer eventoId, uid del asistente y código del QR
    String eventoId = eventoIdSeleccionado ?? '';
    String asistenteUid = '';
    String codigo = qrOPayload.trim().toUpperCase();

    if (qrOPayload.contains('|')) {
      final partes = qrOPayload.split('|');
      if (partes.length >= 3) {
        eventoId = partes[0].trim();
        asistenteUid = partes[1].trim();
        codigo = partes[2].trim().toUpperCase();
      }
    } else if (qrOPayload.startsWith('{') && qrOPayload.endsWith('}')) {
      try {
        final j = jsonDecode(qrOPayload) as Map<String, dynamic>;
        eventoId = j['eventoId'] as String? ?? eventoId;
        asistenteUid = j['uid'] as String? ?? asistenteUid;
        codigo = (j['codigo'] as String? ?? codigo).trim().toUpperCase();
      } catch (_) {}
    }

    if (eventoId.isEmpty && eventoIdSeleccionado != null) {
      eventoId = eventoIdSeleccionado;
    }

    DocumentReference<Map<String, dynamic>>? eventoRef;
    DocumentReference<Map<String, dynamic>>? inscRef;

    try {
      // 2. Si viene asistenteUid y eventoId (escaneo QR), buscar directamente por documento
      if (asistenteUid.isNotEmpty && eventoId.isNotEmpty) {
        final evRefCandidate = _firestore.collection('events').doc(eventoId);
        final candidateInsc = evRefCandidate.collection('inscripciones').doc(asistenteUid);
        final snap = await candidateInsc.get();
        if (snap.exists) {
          eventoRef = evRefCandidate;
          inscRef = candidateInsc;
        }
      }

      // 3. Si no se encontró por documento directo o es ingreso manual de código:
      if (inscRef == null) {
        // A) Buscar en el evento seleccionado
        if (eventoId.isNotEmpty) {
          final evRefCandidate = _firestore.collection('events').doc(eventoId);
          final querySnap = await evRefCandidate
              .collection('inscripciones')
              .where('codigo', isEqualTo: codigo)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            eventoRef = evRefCandidate;
            inscRef = querySnap.docs.first.reference;
          }
        }

        // B) Si no se encontró en el evento seleccionado, buscar en todos los eventos creados por el organizador
        if (inscRef == null) {
          final eventosOrg = obtenerEventosCreados();
          for (final ev in eventosOrg) {
            if (ev.id == eventoId) continue;
            final evRefCandidate = _firestore.collection('events').doc(ev.id);
            final querySnap = await evRefCandidate
                .collection('inscripciones')
                .where('codigo', isEqualTo: codigo)
                .limit(1)
                .get();
            if (querySnap.docs.isNotEmpty) {
              eventoId = ev.id;
              eventoRef = evRefCandidate;
              inscRef = querySnap.docs.first.reference;
              break;
            }
          }
        }

        // C) Búsqueda global por collectionGroup('inscripciones')
        if (inscRef == null) {
          try {
            final cgSnap = await _firestore
                .collectionGroup('inscripciones')
                .where('codigo', isEqualTo: codigo)
                .limit(1)
                .get();
            if (cgSnap.docs.isNotEmpty) {
              final doc = cgSnap.docs.first;
              inscRef = doc.reference;
              final parentEvento = doc.reference.parent.parent;
              if (parentEvento != null) {
                eventoRef = parentEvento;
                eventoId = parentEvento.id;
              }
            }
          } catch (e) {
            debugPrint('Búsqueda por collectionGroup inscripciones: $e');
          }
        }

        // D) Respaldo en inscripciones locales en memoria / caché
        if (inscRef == null) {
          for (final mInsc in _misInscripciones) {
            if (mInsc.codigo.trim().toUpperCase() == codigo) {
              final ev = _mapaEventos[mInsc.eventoId];
              final titulo = ev?.titulo ?? 'Evento';
              final estadoNorm = mInsc.estado.trim().toLowerCase();
              if (estadoNorm == 'asistio') {
                return ResultadoValidacion(
                  exito: false,
                  mensaje: 'Esta entrada YA FUE USADA',
                  nombreAsistente: mInsc.nombre,
                );
              }
              if (estadoNorm == 'anulada') {
                return ResultadoValidacion(
                  exito: false,
                  mensaje: 'Esta entrada fue anulada',
                  nombreAsistente: mInsc.nombre,
                );
              }
              mInsc.estado = 'Asistio';
              notificarCambios();
              return ResultadoValidacion(
                exito: true,
                mensaje: '¡Acceso Concedido a "$titulo"!',
                nombreAsistente: mInsc.nombre,
              );
            }
          }
        }
      }

      if (inscRef == null || eventoRef == null) {
        return ResultadoValidacion(
          exito: false,
          mensaje: 'Código no encontrado en el sistema. Verifica los 24 caracteres.',
        );
      }

      // 4. Transacción atómica de validación y check-in
      final resultado =
          await _firestore.runTransaction<ResultadoValidacion>((tx) async {
        final evSnap = await tx.get(eventoRef!);
        if (!evSnap.exists) {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'El evento no existe',
          );
        }

        final evData = evSnap.data()!;
        final tituloEvento = evData['titulo'] as String? ?? 'Evento';
        final creadorId = evData['creadorId'] as String? ?? '';
        final uActual = UsuarioRepository().obtenerUsuarioActual();
        final authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final esCreador = creadorId.isEmpty ||
            creadorId == uidOrganizador ||
            (authUid.isNotEmpty && creadorId == authUid) ||
            (uActual.usuario.isNotEmpty && creadorId == uActual.usuario) ||
            (PreferenciasUsuario.usuarioActual.isNotEmpty &&
                creadorId == PreferenciasUsuario.usuarioActual);

        if (!esCreador) {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'No eres el organizador de este evento',
          );
        }

        final inscSnap = await tx.get(inscRef!);
        if (!inscSnap.exists) {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'Inscripción no encontrada en el sistema',
          );
        }

        final inscData = inscSnap.data()!;
        final codigoGuardado =
            (inscData['codigo'] as String? ?? '').trim().toUpperCase();
        final estado = inscData['estado'] as String? ?? '';
        final nombre = inscData['nombre'] as String? ?? 'Asistente';

        if (codigoGuardado != codigo) {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'Código de seguridad inválido o no coincide',
          );
        }

        final estadoNorm = estado.trim().toLowerCase();
        if (estadoNorm == 'anulada') {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'Esta entrada fue anulada',
            nombreAsistente: nombre,
          );
        }

        if (estadoNorm == 'asistio') {
          final checkInTimestamp = inscData['checkInEn'] as Timestamp?;
          final dt = checkInTimestamp?.toDate();
          final fechaHora = dt != null
              ? formatoHora(TimeOfDay(hour: dt.hour, minute: dt.minute))
              : '';
          return ResultadoValidacion(
            exito: false,
            mensaje:
                'Esta entrada YA FUE USADA${fechaHora.isNotEmpty ? " a las $fechaHora" : ""}',
            nombreAsistente: nombre,
          );
        }

        if (estadoNorm != 'activa') {
          return ResultadoValidacion(
            exito: false,
            mensaje: 'Entrada no disponible ($estado)',
            nombreAsistente: nombre,
          );
        }

        // Marcar estado Asistio y checkInEn
        tx.update(inscRef!, {
          'estado': 'Asistio',
          'checkInEn': FieldValue.serverTimestamp(),
        });

        return ResultadoValidacion(
          exito: true,
          mensaje: '¡Acceso Concedido a "$tituloEvento"!',
          nombreAsistente: nombre,
        );
      });

      if (resultado.exito) {
        for (final i in _misInscripciones) {
          if (i.codigo.trim().toUpperCase() == codigo) {
            i.estado = 'Asistio';
            break;
          }
        }
        notificarCambios();
      }

      return resultado;
    } catch (e) {
      debugPrint('Error en validarAcceso: $e');
      return ResultadoValidacion(
        exito: false,
        mensaje: 'Error de validación: $e',
      );
    }
  }
}
