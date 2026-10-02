import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Campo de texto delineado para las pantallas oscuras (login y registro).
class CampoTextoAuth extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool esClave;
  final TextInputType tipoTeclado;

  const CampoTextoAuth({
    super.key,
    required this.hint,
    required this.controller,
    this.esClave = false,
    this.tipoTeclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colores.bordeCampo, width: 1),
    );

    return TextField(
      controller: controller,
      obscureText: esClave,
      keyboardType: tipoTeclado,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colores.bordeCampo, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        enabledBorder: borde,
        focusedBorder: borde.copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}
