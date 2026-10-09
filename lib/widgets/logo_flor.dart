import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Logo de EventBQ: flor de 5 pétalos con centro circular.
///
/// Usa tu imagen según el color con que se pide:
///   blanca  -> assets/images/logo_flor.png
///   azul    -> assets/images/logo_flor_azul.png
///   lila    -> assets/images/logo_flor_lila.png  (ícono pequeño del banner)
/// Si la imagen todavía no existe, se dibuja la flor con código.
class LogoFlor extends StatelessWidget {
  final double tamano;
  final Color color;

  /// false = dibujarla siempre con código (la usa la mascota de gracias).
  final bool usarImagen;

  const LogoFlor({
    super.key,
    this.tamano = 60,
    this.color = Colors.white,
    this.usarImagen = true,
  });

  String? get _ruta {
    if (!usarImagen) return null;
    if (color == Colors.white) return 'assets/images/logo_flor.png';
    if (color == Colores.azulOscuro) return 'assets/images/logo_flor_azul.png';
    if (color == const Color(0xFFC77DFF)) {
      return 'assets/images/logo_flor_lila.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dibujo = CustomPaint(painter: _FlorPainter(color));
    final ruta = _ruta;
    return SizedBox(
      width: tamano,
      height: tamano,
      child: ruta == null
          ? dibujo
          : Image.asset(
              ruta,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => dibujo,
            ),
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
      final posicion =
          centro + Offset(cos(angulo) * r * 0.58, sin(angulo) * r * 0.58);
      canvas.drawCircle(posicion, r * 0.40, pintura);
    }
    canvas.drawCircle(centro, r * 0.45, pintura);
  }

  @override
  bool shouldRepaint(covariant _FlorPainter old) => old.color != color;
}
