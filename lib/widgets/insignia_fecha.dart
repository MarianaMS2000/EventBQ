import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Cuadrito blanco sobre las imágenes: "18 / Dic" o solo un texto ("HOY").
class InsigniaFecha extends StatelessWidget {
  final String principal; // "18" o "HOY"
  final String? secundario; // "Dic" (si es null, solo se muestra el principal)
  final double ancho;

  const InsigniaFecha({
    super.key,
    required this.principal,
    this.secundario,
    this.ancho = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colores.azulOscuro, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            principal,
            style: TextStyle(
              fontSize: secundario == null ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
              height: 1.15,
            ),
          ),
          if (secundario != null)
            Text(
              secundario!,
              style: const TextStyle(fontSize: 9, color: Colores.azulOscuro, height: 1.1),
            ),
        ],
      ),
    );
  }
}
