import 'package:flutter/material.dart';
import 'repositories/evento_repository.dart';

/// Va a una pestaña de la pantalla principal.
/// 0 Inicio, 1 Explorar, 2 Mis eventos, 3 Perfil.
void irAPestana(BuildContext context, int indice) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/home',
    (route) => false,
    arguments: indice,
  );
}

/// SIMULACIÓN del límite de eventos: el contador de eventos publicados solo
/// dura mientras el usuario está en las pantallas de crear evento / organizador
/// (o comprando el plan). Al salir a cualquier otra pantalla se reinicia y
/// puede volver a crear eventos. Con backend esto lo controla el servidor.
class ObservadorCreacionEventos extends NavigatorObserver {
  static const _pantallasDeLaSimulacion = {
    '/crear-evento',
    '/panel-organizador',
    '/detalle-evento-organizador',
    '/planes',
    '/pago-suscripcion',
    '/suscripcion-activa',
  };

  void _revisar(Route<dynamic>? ruta) {
    if (ruta is! PageRoute) return; // ignora diálogos y hojas
    final nombre = ruta.settings.name;
    if (nombre == null) return;
    if (!_pantallasDeLaSimulacion.contains(nombre)) {
      EventoRepository().reiniciarPublicaciones();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _revisar(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _revisar(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _revisar(newRoute);
}
