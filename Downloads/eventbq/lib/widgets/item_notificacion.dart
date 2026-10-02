import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../theme/colores.dart';

/// Tarjeta de una notificación.
class ItemNotificacion extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback? onCalificar;

  const ItemNotificacion({super.key, required this.notificacion, this.onCalificar});

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: n.pideCalificacion ? const Color(0xFFEBD3EA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  n.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
              ),
              if (!n.leida)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5560B5),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    n.descripcion,
                    style: const TextStyle(fontSize: 13, color: Colores.azulOscuro),
                  ),
                ),
                if (n.pideCalificacion)
                  GestureDetector(
                    onTap: onCalificar,
                    child: const Text(
                      'CALIFICA AQUI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              n.tiempo,
              style: const TextStyle(fontSize: 11, color: Colores.grisTexto),
            ),
          ),
        ],
      ),
    );
  }
}
