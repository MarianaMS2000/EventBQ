import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Ventana "¿Deseas cancelar este evento?".
/// Devuelve true si el organizador presiona "Sí, cancelar evento".
///
/// Uso:
///   final ok = await showDialog<bool>(
///     context: context,
///     builder: (_) => const DialogoCancelarEvento(),
///   );
class DialogoCancelarEvento extends StatelessWidget {
  final String inscritos;
  final String monto;

  const DialogoCancelarEvento({
    super.key,
    this.inscritos = '32',
    this.monto = '\$ 1.920.000',
  });

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 15,
      height: 1.3,
      color: Colores.azulOscuro,
    );
    const negrita = TextStyle(fontWeight: FontWeight.bold);

    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Deseas cancelar este\nevento?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                style: base,
                children: [
                  const TextSpan(
                    text: 'Esta acción no se puede deshacer. El evento se '
                        'eliminará de la vista pública, se notificará a los ',
                  ),
                  TextSpan(text: inscritos, style: negrita),
                  const TextSpan(
                    text: ' usuarios inscritos y se iniciará el proceso de '
                        'devolución de los ',
                  ),
                  TextSpan(text: '$monto.', style: negrita),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            _boton(
              texto: 'Sí, cancelar evento',
              fondo: const Color(0xFFC62F34),
              colorTexto: Colors.white,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            _boton(
              texto: 'Mantener evento',
              fondo: const Color(0xFFDCDDE0),
              colorTexto: Colores.azulOscuro,
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boton({
    required String texto,
    required Color fondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 186,
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: colorTexto,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
