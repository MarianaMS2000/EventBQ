import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Pastilla "Activo" (verde) o "Finalizado" (gris).
class BadgeEstado extends StatelessWidget {
  final String estado;

  const BadgeEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'Activo';
    return Container(
      width: 78,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: activo ? Colores.verdeActivo : Colores.grisEstado,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colores.azulOscuro,
        ),
      ),
    );
  }
}
