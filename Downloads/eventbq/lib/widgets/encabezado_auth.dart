import 'package:flutter/material.dart';
import 'logo_flor.dart';

/// Parte de arriba de Registro y Login: logo + título grande + subtítulo.
class EncabezadoAuth extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const EncabezadoAuth({super.key, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LogoFlor(tamano: 22),
        const SizedBox(height: 6),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB4BEDC), fontSize: 14),
        ),
      ],
    );
  }
}
