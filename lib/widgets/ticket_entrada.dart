import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Tarjeta tipo entrada: blanca, con dos recortes semicirculares a los lados
/// en la línea divisoria y una línea punteada entre la parte de arriba y la de abajo.
class TicketEntrada extends StatelessWidget {
  final double alturaSuperior;
  final Widget parteSuperior;
  final Widget parteInferior;

  const TicketEntrada({
    super.key,
    required this.alturaSuperior,
    required this.parteSuperior,
    required this.parteInferior,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(alturaSuperior),
      child: Container(
        width: double.infinity,
        color: Colores.fondo,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: alturaSuperior, child: parteSuperior),
            const _LineaPunteada(),
            parteInferior,
          ],
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double yDivision;
  _TicketClipper(this.yDivision);

  @override
  Path getClip(Size size) {
    const radio = 16.0;
    final tarjeta = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));
    final recortes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, yDivision), radius: radio))
      ..addOval(Rect.fromCircle(center: Offset(size.width, yDivision), radius: radio));
    return Path.combine(PathOperation.difference, tarjeta, recortes);
  }

  @override
  bool shouldReclip(covariant _TicketClipper old) => old.yDivision != yDivision;
}

class _LineaPunteada extends StatelessWidget {
  const _LineaPunteada();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cantidad = ((constraints.maxWidth - 40) / 8).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(cantidad, (i) {
              return Container(width: 4, height: 1.5, color: const Color(0xFFB5B8C4));
            }),
          ),
        );
      },
    );
  }
}

/// QR de mentira (solo visual): un patrón que se ve como un QR pero NO se puede escanear.
/// Cuando haya backend, reemplázalo por un QR real (ej. paquete qr_flutter).
class QrPlaceholder extends StatelessWidget {
  final String semilla;
  final double tamano;

  const QrPlaceholder({super.key, required this.semilla, this.tamano = 190});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _QrPainter(semilla)),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String semilla;
  _QrPainter(this.semilla);

  static const int _n = 25;

  bool _esBuscador(int f, int c) {
    return (f < 7 && c < 7) || (f < 7 && c >= _n - 7) || (f >= _n - 7 && c < 7);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final celda = size.width / _n;
    final pintura = Paint()..color = const Color(0xFFA23BA6);
    final azar = Random(semilla.hashCode);

    // Módulos al azar
    for (int f = 0; f < _n; f++) {
      for (int c = 0; c < _n; c++) {
        if (_esBuscador(f, c)) continue;
        if (azar.nextDouble() > 0.52) {
          canvas.drawRect(Rect.fromLTWH(c * celda, f * celda, celda, celda), pintura);
        }
      }
    }

    // Las 3 esquinas grandes
    void buscador(int f0, int c0) {
      canvas.drawRect(Rect.fromLTWH(c0 * celda, f0 * celda, 7 * celda, 7 * celda), pintura);
      canvas.drawRect(
        Rect.fromLTWH((c0 + 1) * celda, (f0 + 1) * celda, 5 * celda, 5 * celda),
        Paint()..color = Colores.fondo,
      );
      canvas.drawRect(
        Rect.fromLTWH((c0 + 2) * celda, (f0 + 2) * celda, 3 * celda, 3 * celda),
        pintura,
      );
    }

    buscador(0, 0);
    buscador(0, _n - 7);
    buscador(_n - 7, 0);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.semilla != semilla;
}
