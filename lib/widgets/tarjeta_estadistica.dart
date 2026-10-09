import 'package:flutter/material.dart';

/// Cuadro de color con un número grande y una etiqueta
/// (ej. "248 / Total inscritos"). Se usa en el Panel de Organizador
/// y en Detalles del evento.
class TarjetaEstadistica extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color fondo;
  final Color borde;
  final double alto;

  const TarjetaEstadistica({
    super.key,
    required this.valor,
    required this.etiqueta,
    required this.fondo,
    required this.borde,
    this.alto = 92,
  });

  // Paleta de las 4 tarjetas del diseño
  static const verde = (fondo: Color(0xFFEBFFE6), borde: Color(0xFF5CD65C));
  static const turquesa = (fondo: Color(0xFFE3FFFC), borde: Color(0xFF2BC4A8));
  static const durazno = (fondo: Color(0xFFFFEFE9), borde: Color(0xFFF0A080));
  static const violeta = (fondo: Color(0xFFFAEAFF), borde: Color(0xFFC27BE0));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borde, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F4A7A),
            ),
          ),
          const Spacer(),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              color: Color(0xFF4A5580),
            ),
          ),
        ],
      ),
    );
  }
}
