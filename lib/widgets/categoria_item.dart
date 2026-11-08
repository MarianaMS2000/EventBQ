import 'package:flutter/material.dart';
import '../models/categoria.dart';

/// Círculo de color con ícono y el nombre debajo.
class CategoriaItem extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback? onTap;
  final bool seleccionada;

  const CategoriaItem({
    super.key,
    required this.categoria,
    this.onTap,
    this.seleccionada = false,
  });

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
              border: seleccionada
                  ? Border.all(color: categoria.colorTexto, width: 3)
                  : null,
            ),
            child: Icon(categoria.icono, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            categoria.nombre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: seleccionada ? FontWeight.bold : FontWeight.w600,
              color: categoria.colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}
