import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// "Categorías ............ Ver todo >"
class SeccionTitulo extends StatelessWidget {
  final String titulo;
  final VoidCallback? onVerTodo;

  const SeccionTitulo({super.key, required this.titulo, this.onVerTodo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colores.azulOscuro,
          ),
        ),
        GestureDetector(
          onTap: onVerTodo,
          child: const Text(
            'Ver todo >',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
