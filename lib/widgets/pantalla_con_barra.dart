import 'package:flutter/material.dart';
import '../navegacion.dart';
import '../theme/colores.dart';
import 'barra_navegacion.dart';

/// Envuelve una pantalla secundaria (detalle, perfil organizador, etc.)
/// y le pone la barra de navegación flotante abajo.
class PantallaConBarra extends StatelessWidget {
  final Widget child;
  final int indiceActual;
  final Color colorFondo;

  /// Qué hace el botón +. Por defecto abre "Crear evento".
  final VoidCallback? alPresionarMas;

  const PantallaConBarra({
    super.key,
    required this.child,
    this.indiceActual = 1,
    this.colorFondo = Colores.fondo,
    this.alPresionarMas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          // La barra se oculta mientras el teclado está abierto.
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: SafeArea(
                top: false,
                child: BarraNavegacion(
                  indiceActual: indiceActual,
                  alSeleccionar: (i) => irAPestana(context, i),
                  alPresionarMas: alPresionarMas ??
                      () => Navigator.pushNamed(context, '/crear-evento'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
