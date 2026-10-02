import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Botón ancho con bordes redondeados (Iniciar Sesión, Registrarse, Crear cuenta...).
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Color colorFondo;
  final Color colorTexto;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.colorFondo = Colors.white,
    this.colorTexto = Colores.azulOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          foregroundColor: colorTexto,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTexto,
          ),
        ),
      ),
    );
  }
}
