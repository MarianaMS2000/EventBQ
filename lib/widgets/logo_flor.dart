import 'dart:math';
import 'package:flutter/material.dart';

/// Logo de EventBQ: flor de 5 pétalos con centro circular.
/// Está dibujado con código; si luego tienes el logo en PNG/SVG, puedes
/// reemplazar este widget por Image.asset('assets/images/logo.png').
class LogoFlor extends StatelessWidget {
  final double tamano;
  final Color color;

  const LogoFlor({super.key, this.tamano = 60, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _FlorPainter(color)),
    );
  }
}

class _FlorPainter extends CustomPainter {
  final Color color;
  _FlorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final pintura = Paint()..color = color;

    for (int i = 0; i < 5; i++) {
      final angulo = -pi / 2 + i * 2 * pi / 5;
      final posicion = centro + Offset(cos(angulo) * r * 0.58, sin(angulo) * r * 0.58);
      canvas.drawCircle(posicion, r * 0.40, pintura);
    }
    canvas.drawCircle(centro, r * 0.45, pintura);
  }

  @override
  bool shouldRepaint(covariant _FlorPainter old) => old.color != color;
}
