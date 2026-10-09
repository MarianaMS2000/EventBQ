import 'dart:math';
import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../theme/colores.dart';

/// Ventana "¿Deseas anular tu inscripción?".
/// Devuelve true si el usuario presiona "Sí, anular inscripción".
///
/// Uso:
///   final ok = await showDialog<bool>(
///     context: context,
///     barrierColor: Colors.black,
///     builder: (_) => DialogoAnularInscripcion(evento: e),
///   );
class DialogoAnularInscripcion extends StatelessWidget {
  final Evento evento;

  const DialogoAnularInscripcion({super.key, required this.evento});

  /// "10 de Diciembre 2026" -> "10 de Diciembre, 2026"
  String get _fecha => evento.fechaParaDetalle.replaceFirstMapped(
        RegExp(r' (\d{4})$'),
        (m) => ', ${m[1]}',
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 72, height: 72, child: _CaritaTriste()),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas anular tu\ninscripción?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu cupo será liberado\npara otra persona.\nEsta acción no se\npuede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.25,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nombre: ${evento.titulo}\nFecha: $_fecha',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Colores.grisTexto,
              ),
            ),
            const SizedBox(height: 18),
            _boton(
              texto: 'Sí, anular inscripción',
              fondo: const Color(0xFFC62F34),
              colorTexto: Colors.white,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            _boton(
              texto: 'Conservar mi ticket',
              fondo: const Color(0xFFDCDDE0),
              colorTexto: Colores.azulOscuro,
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boton({
    required String texto,
    required Color fondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 200,
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: colorTexto,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Carita triste amarilla: assets/images/carita_triste.png
/// (si no existe, se dibuja con código).
class _CaritaTriste extends StatelessWidget {
  const _CaritaTriste();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/carita_triste.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          CustomPaint(painter: _CaritaPainter()),
    );
  }
}

class _CaritaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cafe = Color(0xFF5B3A1E);

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w / 2,
      Paint()..color = const Color(0xFFFFC72C),
    );

    // Ojos (con brillo)
    for (final x in [0.34, 0.66]) {
      final c = Offset(w * x, h * 0.42);
      canvas.drawCircle(c, w * 0.085, Paint()..color = cafe);
      canvas.drawCircle(
        c.translate(-w * 0.025, -h * 0.025),
        w * 0.025,
        Paint()..color = Colors.white,
      );
    }

    // Boca triste (arco hacia arriba)
    final boca = Rect.fromCenter(
      center: Offset(w / 2, h * 0.76),
      width: w * 0.24,
      height: h * 0.16,
    );
    canvas.drawArc(
      boca,
      pi,
      pi,
      false,
      Paint()
        ..color = cafe
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
