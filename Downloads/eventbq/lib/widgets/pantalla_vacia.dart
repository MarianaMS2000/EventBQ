import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Placeholder para pantallas que todavía no tienen diseño (Mis eventos, etc.).
class PantallaVacia extends StatelessWidget {
  final String titulo;

  const PantallaVacia({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$titulo\n(pantalla pendiente de diseño)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colores.azulOscuro),
        ),
      ),
    );
  }
}
