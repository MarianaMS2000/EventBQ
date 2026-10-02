import 'package:flutter/material.dart';
import '../theme/colores.dart';
import 'logo_flor.dart';

/// Flor blanca con carita sosteniendo estrellas (pantalla de agradecimiento).
/// Es un dibujo hecho con widgets; si tienes la ilustración real, cámbialo por Image.asset.
class MascotaGracias extends StatelessWidget {
  final double tamano;

  const MascotaGracias({super.key, this.tamano = 150});

  @override
  Widget build(BuildContext context) {
    const morado = Color(0xFF6B4FD8);
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        children: [
          LogoFlor(tamano: tamano),
          // Ojos
          Positioned(top: tamano * 0.30, left: tamano * 0.39, child: _ojo()),
          Positioned(top: tamano * 0.30, left: tamano * 0.58, child: _ojo()),
          // Sonrisa
          Positioned(
            top: tamano * 0.37,
            left: tamano * 0.46,
            child: Container(
              width: tamano * 0.09,
              height: tamano * 0.04,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colores.azulOscuro, width: 1.5)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
            ),
          ),
          // Estrellas
          Positioned(top: tamano * 0.46, left: tamano * 0.28, child: _estrella(morado, 0.20)),
          Positioned(top: tamano * 0.42, left: tamano * 0.44, child: _estrella(morado, 0.24)),
          Positioned(top: tamano * 0.50, left: tamano * 0.58, child: _estrella(morado, 0.20)),
          Positioned(top: tamano * 0.58, left: tamano * 0.40, child: _estrella(morado, 0.18)),
        ],
      ),
    );
  }

  Widget _ojo() {
    return Container(
      width: tamano * 0.03,
      height: tamano * 0.03,
      decoration: const BoxDecoration(color: Colores.azulOscuro, shape: BoxShape.circle),
    );
  }

  Widget _estrella(Color color, double proporcion) {
    return Icon(Icons.star, color: color, size: tamano * proporcion);
  }
}
