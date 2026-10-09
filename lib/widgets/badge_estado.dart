import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Pastilla de estado: "Activo" (verde), "Cancelado" (rojo) o "Finalizado" (gris).
class BadgeEstado extends StatelessWidget {
  final String estado;

  const BadgeEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'Activo';
    final cancelado = estado == 'Cancelado';
    return Container(
      width: 78,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: activo
            ? Colores.verdeActivo
            : cancelado
                ? const Color(0xFFEF5350)
                : Colores.grisEstado,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cancelado ? Colors.white : Colores.azulOscuro,
        ),
      ),
    );
  }
}
