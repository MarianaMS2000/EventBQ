import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Ventana "¡Publicado! Tu evento ya está disponible".
/// Se cierra sola a los 2 segundos.
///
/// Uso:
///   await showDialog<void>(
///     context: context,
///     barrierColor: Colors.black,
///     barrierDismissible: false,
///     builder: (_) => const DialogoEventoPublicado(),
///   );
class DialogoEventoPublicado extends StatefulWidget {
  const DialogoEventoPublicado({super.key});

  @override
  State<DialogoEventoPublicado> createState() => _DialogoEventoPublicadoState();
}

class _DialogoEventoPublicadoState extends State<DialogoEventoPublicado> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFF38B887),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              '¡Publicado!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu evento ya\nestá disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.25,
                color: Colores.azulOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
