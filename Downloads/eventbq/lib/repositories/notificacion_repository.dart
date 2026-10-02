import '../data/datos_simulados.dart';
import '../models/notificacion.dart';

class NotificacionRepository {
  List<Notificacion> obtenerPorTipo(String tipo) {
    return datosNotificaciones.where((n) => n.tipo == tipo).toList();
  }

  int contarNoLeidas() {
    return datosNotificaciones.where((n) => !n.leida).length;
  }

  void marcarTodasLeidas() {
    for (final n in datosNotificaciones) {
      n.leida = true;
    }
  }
}
