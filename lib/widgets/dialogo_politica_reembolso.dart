import 'package:flutter/material.dart';
import '../theme/colores.dart';
import 'logo_flor.dart';

/// Ventana "Nota sobre política de reembolso".
/// Se cierra con la flecha de la esquina (devuelve al panel).
///
/// Uso:
///   await showDialog<void>(
///     context: context,
///     barrierColor: Colors.black,
///     barrierDismissible: false,
///     builder: (_) => const DialogoPoliticaReembolso(),
///   );
class DialogoPoliticaReembolso extends StatelessWidget {
  const DialogoPoliticaReembolso({super.key});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 17,
      height: 1.3,
      color: Colores.azulOscuro,
    );
    const negrita = TextStyle(fontWeight: FontWeight.bold);

    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 32, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: LogoFlor(tamano: 62, color: Colores.azulOscuro),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Nota sobre política\nde reembolso',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              const TextSpan(
                style: base,
                children: [
                  TextSpan(text: 'Para eventos gratuitos: ', style: negrita),
                  TextSpan(text: 'Liberarás tu entrada inmediatamente.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text.rich(
              const TextSpan(
                style: base,
                children: [
                  TextSpan(text: 'Para eventos de pago:\n', style: negrita),
                  TextSpan(
                    text: 'El reembolso se procesará según las políticas del '
                        'organizador (3 a 5 días hábiles)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 52,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.azulOscuro,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
