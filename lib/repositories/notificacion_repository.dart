import 'dart:convert';
import '../models/notificacion.dart';
import '../preferences/preferencias_usuario.dart';
import 'cambios.dart';
import 'evento_repository.dart';

/// Notificaciones de cada usuario: una List<Notificacion> guardada en
/// SharedPreferences con la clave "notificaciones__<usuario>".
class NotificacionRepository {
  static final NotificacionRepository _instancia = NotificacionRepository._();
  factory NotificacionRepository() => _instancia;
  NotificacionRepository._();

  static const _kNotificaciones = 'notificaciones';

  List<Notificacion> _leer(String idUsuario) {
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

  void _guardar(String idUsuario, List<Notificacion> lista) {
    PreferenciasUsuario.guardarTexto(
      PreferenciasUsuario.claveDe(_kNotificaciones, idUsuario),
      jsonEncode(lista.map((n) => n.toJson()).toList()),
    );
    notificarCambios();
  }

  /// Agrega una notificación (la más nueva queda arriba) a cualquier usuario.
  void agregarA(
    String idUsuario, {
    required String titulo,
    required String descripcion,
    String tipo = 'Eventos',
    bool pideCalificacion = false,
    String idEvento = '',
  }) {
    if (idUsuario.isEmpty) return;
    final lista = _leer(idUsuario);
    lista.insert(
      0,
      Notificacion(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        titulo: titulo,
        descripcion: descripcion,
        tipo: tipo,
        pideCalificacion: pideCalificacion,
        idEvento: idEvento,
      ),
    );
    _guardar(idUsuario, lista);
  }

  void crearBienvenida(String idUsuario) {
    agregarA(
      idUsuario,
      titulo: '¡Bienvenido a EventBQ!',
      descripcion: 'Explora los eventos y reserva tu primera entrada',
    );
  }

  List<Notificacion> obtenerPorTipo(String tipo) {
    return _leer(PreferenciasUsuario.usuarioActual)
        .where((n) => n.tipo == tipo)
        .toList();
  }

  int contarNoLeidas() {
    return _leer(PreferenciasUsuario.usuarioActual)
        .where((n) => !n.leida)
        .length;
  }

  void marcarTodasLeidas() {
    final id = PreferenciasUsuario.usuarioActual;
    final lista = _leer(id);
    for (final n in lista) {
      n.leida = true;
    }
    _guardar(id, lista);
  }

  /// Si el usuario tiene entradas de eventos que ya terminaron y todavía no los
  /// calificó, crea la notificación "¡Califícalo!" (una sola vez por evento).
  void generarPendientesCalificacion() {
    final id = PreferenciasUsuario.usuarioActual;
    if (id.isEmpty) return;
    final eventos = EventoRepository();
    final lista = _leer(id);
    var cambio = false;
    for (final e in eventos.obtenerEntradasCompradas()) {
      if (e.estado != 'Finalizado') continue;
      if (eventos.yaCalifico(e.id)) continue;
      if (lista.any((n) => n.pideCalificacion && n.idEvento == e.id)) continue;
      lista.insert(
        0,
        Notificacion(
          id: 'n${DateTime.now().microsecondsSinceEpoch}',
          titulo: '¿Qué tal estuvo el evento? ¡Califícalo!',
          descripcion: e.titulo,
          tipo: 'Eventos',
          pideCalificacion: true,
          idEvento: e.id,
        ),
      );
      cambio = true;
    }
    if (cambio) {
      PreferenciasUsuario.guardarTexto(
        PreferenciasUsuario.claveDe(_kNotificaciones, id),
        jsonEncode(lista.map((n) => n.toJson()).toList()),
      );
    }
  }

  /// Quita el aviso de calificar de un evento (ya lo calificó).
  void quitarPedidoCalificacion(String idEvento) {
    final id = PreferenciasUsuario.usuarioActual;
    final lista = _leer(id);
    lista.removeWhere((n) => n.pideCalificacion && n.idEvento == idEvento);
    _guardar(id, lista);
  }
}
