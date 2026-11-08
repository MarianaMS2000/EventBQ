import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';
import '../preferences/preferencias_usuario.dart';
import '../services/push_notification_service.dart';
import 'cambios.dart';
import 'evento_repository.dart';

/// Las notificaciones se sincronizan en tiempo real con Cloud Firestore
/// en la ruta users/{uid}/notificaciones.
/// Mantiene un caché en memoria para responder de forma síncrona a la UI.
class NotificacionRepository {
  static final NotificacionRepository _instancia = NotificacionRepository._();
  factory NotificacionRepository() => _instancia;
  NotificacionRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _kNotificaciones = 'notificaciones';

  final List<Notificacion> _cache = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String _usuarioActivo = '';

  // ---------- Ciclo de vida y listeners ----------

  Future<void> iniciar(String uid) async {
    if (uid.isEmpty) return;
    if (_usuarioActivo == uid && _sub != null) return;
    _usuarioActivo = uid;

    // Cargar respaldo local primero
    final local = _leerLocal(uid);
    _cache.clear();
    _cache.addAll(local);

    await _sub?.cancel();
    _sub = _firestore
        .collection('users')
        .doc(uid)
        .collection('notificaciones')
        .snapshots()
        .listen((snap) {
      _cache.clear();
      for (final doc in snap.docs) {
        _cache.add(Notificacion.fromFirestore(doc));
      }
      _cache.sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
      _guardarLocal(uid, _cache);
      notificarCambios();
    }, onError: (e) {
      debugPrint('Error en snapshot notificaciones: $e');
    });
  }

  Future<void> cancelar() async {
    await _sub?.cancel();
    _sub = null;
    _usuarioActivo = '';
    _cache.clear();
  }

  // ---------- Respaldos locales ----------

  List<Notificacion> _leerLocal(String idUsuario) {
    final raw = PreferenciasUsuario.leerTexto(
      PreferenciasUsuario.claveDe(_kNotificaciones, idUsuario),
    );
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((j) => Notificacion.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _guardarLocal(String idUsuario, List<Notificacion> lista) {
    PreferenciasUsuario.guardarTexto(
      PreferenciasUsuario.claveDe(_kNotificaciones, idUsuario),
      jsonEncode(lista.map((n) => n.toJson()).toList()),
    );
  }

  // ---------- Consultas síncronas ----------

  List<Notificacion> obtenerPorTipo(String tipo) {
    if (_cache.isEmpty) {
      final local = _leerLocal(PreferenciasUsuario.usuarioActual);
      return local.where((n) => n.tipo == tipo).toList();
    }
    return _cache.where((n) => n.tipo == tipo).toList();
  }

  int contarNoLeidas() {
    if (_cache.isEmpty) {
      final local = _leerLocal(PreferenciasUsuario.usuarioActual);
      return local.where((n) => !n.leida).length;
    }
    return _cache.where((n) => !n.leida).length;
  }

  // ---------- Acciones ----------

  Future<void> marcarTodasLeidas() async {
    final uid = PreferenciasUsuario.usuarioActual;
    for (final n in _cache) {
      n.leida = true;
    }
    _guardarLocal(uid, _cache);
    notificarCambios();

    if (uid.isNotEmpty) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('notificaciones')
            .where('leida', isEqualTo: false)
            .get();
        if (snap.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in snap.docs) {
            batch.update(doc.reference, {'leida': true});
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Error al marcar notificaciones como leídas: $e');
      }
    }
  }

  Future<void> marcarLeida(String notifId) async {
    final uid = PreferenciasUsuario.usuarioActual;
    final n = _cache.where((notif) => notif.id == notifId).firstOrNull;
    if (n != null) n.leida = true;
    notificarCambios();

    if (uid.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('notificaciones')
            .doc(notifId)
            .update({'leida': true});
      } catch (_) {}
    }
  }

  Future<void> eliminar(String notifId) async {
    final uid = PreferenciasUsuario.usuarioActual;
    _cache.removeWhere((n) => n.id == notifId);
    _guardarLocal(uid, _cache);
    notificarCambios();

    if (uid.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('notificaciones')
            .doc(notifId)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> agregarA(
    String idUsuario, {
    required String titulo,
    required String descripcion,
    String tipo = 'Eventos',
    bool pideCalificacion = false,
    String idEvento = '',
  }) async {
    if (idUsuario.isEmpty) return;

    final n = Notificacion(
      id: 'n${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      tipo: tipo,
      pideCalificacion: pideCalificacion,
      idEvento: idEvento,
      creadaEn: DateTime.now(),
    );

    if (idUsuario == PreferenciasUsuario.usuarioActual) {
      _cache.insert(0, n);
      _guardarLocal(idUsuario, _cache);
      notificarCambios();
    }

    try {
      await _firestore
          .collection('users')
          .doc(idUsuario)
          .collection('notificaciones')
          .add(n.toFirestore());

      // Disparar push notification fuera de la app
      PushNotificationService().enviarPushAUsuario(
        destinoUid: idUsuario,
        titulo: titulo,
        cuerpo: descripcion,
      );
    } catch (e) {
      debugPrint('Error al crear notificación en Firestore: $e');
    }
  }

  void crearBienvenida(String idUsuario) {
    agregarA(
      idUsuario,
      titulo: '¡Bienvenido a EventBQ!',
      descripcion: 'Explora los eventos y reserva tu primera entrada',
    );
  }

  Future<void> generarPendientesCalificacion() async {
    final uid = PreferenciasUsuario.usuarioActual;
    if (uid.isEmpty) return;
    final eventos = EventoRepository();

    for (final e in eventos.obtenerEntradasCompradas()) {
      if (e.estado != 'Finalizado') continue;
      if (eventos.yaCalifico(e.id)) continue;
      if (_cache.any((n) => n.pideCalificacion && n.idEvento == e.id)) continue;

      await agregarA(
        uid,
        titulo: '¿Qué tal estuvo el evento? ¡Califícalo!',
        descripcion: e.titulo,
        tipo: 'Eventos',
        pideCalificacion: true,
        idEvento: e.id,
      );
    }
  }

  Future<void> quitarPedidoCalificacion(String idEvento) async {
    final uid = PreferenciasUsuario.usuarioActual;
    final aEliminar = _cache
        .where((n) => n.pideCalificacion && n.idEvento == idEvento)
        .toList();

    for (final n in aEliminar) {
      _cache.remove(n);
      if (uid.isNotEmpty) {
        try {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('notificaciones')
              .doc(n.id)
              .delete();
        } catch (_) {}
      }
    }
    _guardarLocal(uid, _cache);
    notificarCambios();
  }
}
