import 'package:flutter/material.dart';
import '../models/categoria.dart';

/// Círculo de color con ícono y el nombre debajo.
class CategoriaItem extends StatelessWidget {
  final Categoria categoria;

  const CategoriaItem({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: categoria.colorFondo,
            shape: BoxShape.circle,
          ),
          child: Icon(categoria.icono, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 6),
        Text(
          categoria.nombre,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: categoria.colorTexto,
          ),
        ),
      ],
    );
  }
}
