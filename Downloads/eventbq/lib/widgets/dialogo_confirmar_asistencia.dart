import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../theme/colores.dart';
import 'logo_flor.dart';

/// Diálogo "¿Quieres confirmar tu asistencia?".
/// Uso:  final ok = await mostrarDialogoConfirmarAsistencia(context, evento);
/// Devuelve true si el usuario presionó "Confirmar inscripción".
Future<bool> mostrarDialogoConfirmarAsistencia(BuildContext context, Evento evento) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black38,
    builder: (context) => _DialogoConfirmar(evento: evento),
  );
  return resultado ?? false;
}

class _DialogoConfirmar extends StatelessWidget {
  final Evento evento;

  const _DialogoConfirmar({required this.evento});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoFlor(tamano: 60, color: Colores.azulOscuro),
            const SizedBox(height: 16),
            const Text(
              '¿Quieres confirmar\ntu asistencia?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: Colores.azulOscuro, height: 1.4),
                children: [
                  const TextSpan(text: 'Estás a punto de inscribirte a '),
                  TextSpan(
                    text: evento.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        '. Tu cupo quedará reservado de inmediato. Puedes cancelar tu inscripción en cualquier momento desde tu perfil sin costo alguno.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _boton(context, 'Confirmar inscripción', Colores.celesteBoton, true),
            const SizedBox(height: 12),
            _boton(context, 'Cancelar', const Color(0xFFC2C2C2), false),
          ],
        ),
      ),
    );
  }

  Widget _boton(BuildContext context, String texto, Color color, bool valor) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, valor),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colores.azulOscuro,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
