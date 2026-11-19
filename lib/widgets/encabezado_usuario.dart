import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/cambios.dart';
import '../repositories/notificacion_repository.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import 'imagen_asset.dart';

/// Header de Inicio, Explorar, Detalle y Notificaciones:
/// avatar + "Hola!" + nombre, y campana (abre Notificaciones) a la derecha.
class EncabezadoUsuario extends StatelessWidget {
  /// Si no se pasa, usa el usuario con la sesión abierta (se actualiza solo).
  final Usuario? usuario;

  /// En la pantalla de Notificaciones se oculta (ya estás ahí).
  final bool mostrarCampana;

  const EncabezadoUsuario({
    super.key,
    this.usuario,
    this.mostrarCampana = true,
  });

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(builder: _contenido);
  }

  Widget _contenido(BuildContext context) {
    final usuario = this.usuario ?? UsuarioRepository().obtenerUsuarioActual();
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: 44,
                height: 44,
                child: usuario.foto.isNotEmpty
                    ? ImagenAsset(
                        ruta: usuario.foto,
                        iconoPlaceholder: Icons.person,
                      )
                    : Container(
                        color: const Color(0xFFE8EEF8),
                        child: const Icon(
                          Icons.person,
                          color: Colores.azulOscuro,
                          size: 26,
                        ),
                      ),
              ),
            ),
            if (usuario.planPro)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38E0FD), Color(0xFF1B3B82)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.diamond_rounded,
                      size: 10, color: Colors.white),
                ),
              ),
          ],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      usuario.nombre,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (usuario.planPro) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.diamond_rounded,
                        size: 16, color: Color(0xFF0072FF)),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (mostrarCampana)
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
                // Punto rojo: solo si hay notificaciones sin leer.
                Positioned(
                  top: 10,
                  right: 11,
                  child: EscuchaDatos(
                    builder: (_) => NotificacionRepository().contarNoLeidas() == 0
                        ? const SizedBox.shrink()
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colores.rojoNotificacion,
                              shape: BoxShape.circle,
                            ),
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
