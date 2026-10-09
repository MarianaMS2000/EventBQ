import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Ventana "¿Deseas reprogramar el evento?".
/// Por ahora es solo diseño: "Guardar nueva fecha" y "Volver" solo cierran
/// la ventana y regresan a la pantalla anterior.
///
/// Uso:  showDialog(context: context, builder: (_) => const DialogoReprogramarEvento());
class DialogoReprogramarEvento extends StatelessWidget {
  final String fecha;
  final String horaInicio;
  final String horaCierre;

  const DialogoReprogramarEvento({
    super.key,
    this.fecha = '20/12/2026',
    this.horaInicio = '1:00 PM',
    this.horaCierre = '4:00 PM',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.fondo,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Deseas reprogramar\nel evento?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona la nueva fecha y hora. Le notificaremos '
              'automáticamente a los usuarios inscritos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: Colores.azulOscuro,
              ),
            ),
            const SizedBox(height: 18),
            _campo('FECHA', fecha),
            const SizedBox(height: 14),
            _campo('HORA DE INICIO', horaInicio),
            const SizedBox(height: 14),
            _campo('HORA DE CIERRE', horaCierre),
            const SizedBox(height: 26),
            _boton(
              texto: 'Guardar nueva fecha',
              fondo: const Color(0xFF2F86C8),
              colorTexto: Colors.white,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            _boton(
              texto: 'Volver',
              fondo: const Color(0xFFF09A00),
              colorTexto: Colors.black,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String etiqueta, String valor) {
    return Column(
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colores.azulOscuro,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colores.azulOscuro, width: 1.2),
          ),
          child: Text(
            valor,
            style: const TextStyle(fontSize: 12, color: Colores.azulOscuro),
          ),
        ),
      ],
    );
  }

  Widget _boton({
    required String texto,
    required Color fondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 176,
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: colorTexto,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
