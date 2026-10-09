import 'package:flutter/material.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/encabezado_usuario.dart';

/// Pestaña "Mis eventos": pregunta qué eventos quiere ver el usuario.
/// (La barra de navegación la pone MainScreen.)
class MisEventosScreen extends StatelessWidget {
  const MisEventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        child: Column(
          children: [
            EncabezadoUsuario(
                usuario: UsuarioRepository().obtenerUsuarioActual()),
            const SizedBox(height: 40),
            const Text(
              '¿Qué eventos\ndeseas ver?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 56),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _OpcionEventos(
                      imagen: 'assets/images/mis_entradas.png',
                      icono: Icons.confirmation_number_rounded,
                      colorIcono: const Color(0xFF2F80ED),
                      titulo: 'Mis Entradas\nCompradas',
                      descripcion:
                          'Consulta tus pases QR, fechas y tickets de eventos a los que te has inscrito',
                      fondo: const Color(0xFFDDFDFF),
                      borde: const Color(0xFF2BC4D8),
                      onTap: () =>
                          Navigator.pushNamed(context, '/panel-asistente'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OpcionEventos(
                      imagen: 'assets/images/mis_eventos_creados.png',
                      icono: Icons.present_to_all_rounded,
                      colorIcono: const Color(0xFFC74CF0),
                      titulo: 'Mis Eventos\nCreados',
                      descripcion:
                          'Accede a tu panel de control, métricas, recaudo y gestión de asistentes',
                      fondo: const Color(0xFFFAEAFF),
                      borde: const Color(0xFFB55BD6),
                      onTap: () =>
                          Navigator.pushNamed(context, '/panel-organizador'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionEventos extends StatelessWidget {
  final String imagen; // ilustración (si no existe, se usa el ícono)
  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String descripcion;
  final Color fondo;
  final Color borde;
  final VoidCallback onTap;

  const _OpcionEventos({
    required this.imagen,
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.descripcion,
    required this.fondo,
    required this.borde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 22, 10, 20),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borde, width: 1),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 90,
              child: Image.asset(
                imagen,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(icono, color: colorIcono, size: 78),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colores.azulOscuro,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
