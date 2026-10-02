import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Barra inferior flotante con "joroba" central y botón + grande.
/// Posiciones: 0 Inicio, 1 Explorar, 2 Mis eventos, 3 Perfil.
class BarraNavegacion extends StatelessWidget {
  final int indiceActual;
  final ValueChanged<int> alSeleccionar;
  final VoidCallback alPresionarMas;

  const BarraNavegacion({
    super.key,
    required this.indiceActual,
    required this.alSeleccionar,
    required this.alPresionarMas,
  });

  static const double alto = 106; // altura total (incluye la joroba)

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: Stack(
        children: [
          // Fondo con forma de pastilla + joroba
          Positioned.fill(
            child: CustomPaint(painter: _FondoBarraPainter()),
          ),
          // Los 4 items (dejando un hueco en el centro)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 66,
            child: Row(
              children: [
                _item(0, Icons.home_outlined, Icons.home, 'Inicio'),
                _item(1, Icons.explore_outlined, Icons.explore, 'Explorar'),
                const Expanded(child: SizedBox()),
                _item(2, Icons.calendar_today_outlined, Icons.calendar_month, 'Mis eventos'),
                _item(3, Icons.person_outline, Icons.person, 'Perfil'),
              ],
            ),
          ),
          // Botón central +
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: alPresionarMas,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colores.azulOscuro, width: 3),
                      ),
                      child: const Icon(Icons.add, color: Colores.azulOscuro, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int indice, IconData icono, IconData iconoActivo, String texto) {
    final activo = indiceActual == indice;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => alSeleccionar(indice),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(activo ? iconoActivo : icono, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            Text(
              texto,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                decoration: activo ? TextDecoration.underline : TextDecoration.none,
                decorationColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FondoBarraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Pastilla: ocupa los 66 px de abajo
    final barra = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - 66, size.width, 66),
        const Radius.circular(33),
      ));
    // Joroba: círculo centrado en el borde superior de la pastilla
    final joroba = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height - 66),
        radius: 40,
      ));
    final forma = Path.combine(PathOperation.union, barra, joroba);

    canvas.drawShadow(forma, Colors.black38, 6, true);
    canvas.drawPath(forma, Paint()..color = Colores.azulOscuro);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
