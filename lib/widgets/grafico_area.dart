import 'package:flutter/material.dart';

/// Gráfico de área suavizado (sin librerías externas).
/// Ej: GraficoArea(valores: [2, 3, 30, 37, 10, 5], etiquetas: ['9','10','11','12','1','2'])
class GraficoArea extends StatelessWidget {
  final List<double> valores;
  final List<String> etiquetas;
  final int maximo; // valor más alto del eje Y
  final int paso; // cada cuánto se marca el eje Y
  final double alto;
  final Color color;

  const GraficoArea({
    super.key,
    required this.valores,
    required this.etiquetas,
    this.maximo = 40,
    this.paso = 10,
    this.alto = 170,
    this.color = const Color(0xFF2E86C1),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: alto,
      child: CustomPaint(
        painter: _AreaPainter(valores, etiquetas, maximo, paso, color),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  final List<double> valores;
  final List<String> etiquetas;
  final int maximo;
  final int paso;
  final Color color;

  _AreaPainter(this.valores, this.etiquetas, this.maximo, this.paso, this.color);

  static const _gris = Color(0xFF9AA0AE);

  @override
  void paint(Canvas canvas, Size size) {
    const izq = 30.0, abajo = 22.0, arriba = 8.0, derecha = 4.0;
    final alto = size.height - abajo - arriba;
    final base = arriba + alto;
    final ancho = size.width - izq - derecha;
    final ejes = Paint()
      ..color = _gris
      ..strokeWidth = 1;

    // Área suavizada
    final n = valores.length;
    if (n >= 2) {
      final puntos = <Offset>[
        for (int i = 0; i < n; i++)
          Offset(izq + ancho * i / (n - 1), base - alto * valores[i] / maximo),
      ];
      Offset p(int i) => puntos[i.clamp(0, n - 1)];
      double limitarY(double y) => y.clamp(arriba, base).toDouble();

      final camino = Path()
        ..moveTo(puntos.first.dx, base)
        ..lineTo(puntos.first.dx, puntos.first.dy);
      for (int i = 0; i < n - 1; i++) {
        final c1 = p(i) + (p(i + 1) - p(i - 1)) / 6;
        final c2 = p(i + 1) - (p(i + 2) - p(i)) / 6;
        camino.cubicTo(
          c1.dx, limitarY(c1.dy), //
          c2.dx, limitarY(c2.dy), //
          puntos[i + 1].dx, puntos[i + 1].dy,
        );
      }
      camino
        ..lineTo(puntos.last.dx, base)
        ..close();
      canvas.drawPath(camino, Paint()..color = color);

      // Etiquetas del eje X
      for (int i = 0; i < n && i < etiquetas.length; i++) {
        _texto(canvas, etiquetas[i], Offset(puntos[i].dx, base + 5),
            centroH: true);
      }
    }

    // Ejes
    canvas.drawLine(const Offset(izq, arriba), Offset(izq, base), ejes);
    canvas.drawLine(Offset(izq, base), Offset(size.width, base), ejes);
    for (int v = 0; v <= maximo; v += paso) {
      final y = base - alto * v / maximo;
      canvas.drawLine(Offset(izq - 4, y), Offset(izq, y), ejes);
      _texto(canvas, '$v', Offset(izq - 7, y), derecha: true, centroV: true);
    }
  }

  void _texto(Canvas canvas, String texto, Offset punto,
      {bool derecha = false, bool centroV = false, bool centroH = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(fontSize: 10, color: _gris),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = punto.dx;
    var dy = punto.dy;
    if (derecha) dx -= tp.width;
    if (centroH) dx -= tp.width / 2;
    if (centroV) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) =>
      old.valores != valores || old.maximo != maximo;
}
