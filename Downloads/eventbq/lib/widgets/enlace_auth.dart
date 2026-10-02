import 'package:flutter/material.dart';

/// Footer de login/registro: "Ya tienes una cuenta?" + "Ingresa" subrayado.
class EnlaceAuth extends StatelessWidget {
  final String pregunta;
  final String accion;
  final VoidCallback onPressed;

  const EnlaceAuth({
    super.key,
    required this.pregunta,
    required this.accion,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pregunta,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        GestureDetector(
          onTap: onPressed,
          child: Text(
            accion,
            style: const TextStyle(
              color: Color(0xFFB4BEDC),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFB4BEDC),
            ),
          ),
        ),
      ],
    );
  }
}
