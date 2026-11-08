import 'package:flutter/material.dart';
import '../models/categoria.dart';

/// Círculo de color con ícono y el nombre debajo.
class CategoriaItem extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback? onTap;

  const CategoriaItem({super.key, required this.categoria, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
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
      ),
    );
  }
}
