import 'package:flutter/material.dart';

/// Gráfico de barras sencillo (sin librerías externas).
/// Ej: GraficoBarras(valores: [3, 7, 5], etiquetas: ['Lun', 'Mar', 'Mié'])
class GraficoBarras extends StatelessWidget {
  final List<int> valores;
  final List<String> etiquetas;
  final int maximo; // valor más alto del eje Y
  final int paso; // cada cuánto se marca el eje Y
  final double alto;
  final Color colorBarra;

  const GraficoBarras({
    super.key,
    required this.valores,
    required this.etiquetas,
    this.maximo = 12,
    this.paso = 3,
    this.alto = 180,
    this.colorBarra = const Color(0xFF2E86C1),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: alto,
      child: CustomPaint(
        painter: _BarrasPainter(valores, etiquetas, maximo, paso, colorBarra),
      ),
    );
  }
}

class _BarrasPainter extends CustomPainter {
  final List<int> valores;
  final List<String> etiquetas;
  final int maximo;
  final int paso;
  final Color colorBarra;

  _BarrasPainter(
      this.valores, this.etiquetas, this.maximo, this.paso, this.colorBarra);

  static const _gris = Color(0xFF9AA0AE);

  @override
  void paint(Canvas canvas, Size size) {
    const izq = 30.0, abajo = 22.0, arriba = 8.0;
    final alto = size.height - abajo - arriba;
    final base = arriba + alto;
    final ejes = Paint()
      ..color = _gris
      ..strokeWidth = 1;

    // Ejes
    canvas.drawLine(const Offset(izq, arriba), Offset(izq, base), ejes);
    canvas.drawLine(Offset(izq, base), Offset(size.width, base), ejes);

    // Marcas del eje Y (0, 3, 6, 9, 12)
    for (int v = 0; v <= maximo; v += paso) {
      final y = base - alto * v / maximo;
      canvas.drawLine(Offset(izq - 4, y), Offset(izq, y), ejes);
      _texto(canvas, '$v', Offset(izq - 7, y), derecha: true, centroV: true);
    }

    // Barras
    final n = valores.length;
    if (n == 0) return;
    final hueco = (size.width - izq) / n;
    final ancho = hueco * 0.62;
    final pintura = Paint()..color = colorBarra;
    for (int i = 0; i < n; i++) {
      final x = izq + hueco * i + (hueco - ancho) / 2;
      final h = alto * valores[i] / maximo;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, base - h, ancho, h),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        pintura,
      );
      if (i < etiquetas.length) {
        _texto(canvas, etiquetas[i], Offset(x + ancho / 2, base + 4),
            centroH: true);
      }
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
  bool shouldRepaint(covariant _BarrasPainter old) =>
      old.valores != valores || old.maximo != maximo;
}
