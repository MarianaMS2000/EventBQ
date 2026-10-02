import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../theme/colores.dart';
import 'imagen_asset.dart';

/// Header de Inicio, Explorar, Detalle y Notificaciones:
/// avatar + "Hola!" + nombre, y campana (abre Notificaciones) a la derecha.
class EncabezadoUsuario extends StatelessWidget {
  final Usuario usuario;

  const EncabezadoUsuario({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 44,
            height: 44,
            child: ImagenAsset(
              ruta: usuario.foto,
              iconoPlaceholder: Icons.person,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola!',
                style: TextStyle(color: Colores.grisTexto, fontSize: 13),
              ),
              Text(
                usuario.nombre,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notificaciones'),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none, color: Colores.azulOscuro, size: 22),
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colores.rojoNotificacion,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
