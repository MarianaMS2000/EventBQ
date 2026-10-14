import 'package:flutter/material.dart';
import '../theme/colores.dart';
import '../utils/formato.dart';

/// Lo que elige el organizador en el diálogo de reprogramar.
class NuevaProgramacion {
  final DateTime fecha;
  final TimeOfDay inicio;
  final TimeOfDay cierre;

  const NuevaProgramacion(this.fecha, this.inicio, this.cierre);
}

/// Ventana "¿Deseas reprogramar el evento?".
/// Se toca cada campo para elegir fecha u hora. Devuelve una
/// [NuevaProgramacion] si presiona "Guardar nueva fecha", o null si vuelve.
///
/// Uso:  final r = await showDialog<NuevaProgramacion>(
///         context: context,
///         builder: (_) => DialogoReprogramarEvento(fechaInicial: ..., ...));
class DialogoReprogramarEvento extends StatefulWidget {
  final DateTime fechaInicial;
  final TimeOfDay inicioInicial;
  final TimeOfDay cierreInicial;

  const DialogoReprogramarEvento({
    super.key,
    required this.fechaInicial,
    required this.inicioInicial,
    required this.cierreInicial,
  });

  @override
  State<DialogoReprogramarEvento> createState() =>
      _DialogoReprogramarEventoState();
}

class _DialogoReprogramarEventoState extends State<DialogoReprogramarEvento> {
  late DateTime _fecha = widget.fechaInicial;
  late TimeOfDay _inicio = widget.inicioInicial;
  late TimeOfDay _cierre = widget.cierreInicial;

  Future<void> _elegirFecha() async {
    final hoy = soloFecha(DateTime.now());
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
      firstDate: hoy,
      lastDate: DateTime(2035),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final h = await showTimePicker(
      context: context,
      initialTime: inicio ? _inicio : _cierre,
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (h == null) return;
    setState(() => inicio ? _inicio = h : _cierre = h);
  }

  void _guardar() {
    final ini = _inicio.hour * 60 + _inicio.minute;
    final fin = _cierre.hour * 60 + _cierre.minute;
    if (fin <= ini) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de cierre debe ser después de la de inicio'),
        ),
      );
      return;
    }
    Navigator.pop(context, NuevaProgramacion(_fecha, _inicio, _cierre));
  }

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
            _campo('FECHA', formatoFecha(_fecha), _elegirFecha),
            const SizedBox(height: 14),
            _campo('HORA DE INICIO', formatoHora(_inicio),
                () => _elegirHora(inicio: true)),
            const SizedBox(height: 14),
            _campo('HORA DE CIERRE', formatoHora(_cierre),
                () => _elegirHora(inicio: false)),
            const SizedBox(height: 26),
            _boton(
              texto: 'Guardar nueva fecha',
              fondo: const Color(0xFF2F86C8),
              colorTexto: Colors.white,
              onTap: _guardar,
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

  Widget _campo(String etiqueta, String valor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          width: 110,
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
