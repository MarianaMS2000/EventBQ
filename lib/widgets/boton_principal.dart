import 'package:flutter/material.dart';
import '../theme/colores.dart';

/// Botón ancho con bordes redondeados (Iniciar Sesión, Registrarse, Crear cuenta...).
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Color colorFondo;
  final Color colorTexto;
  final bool cargando;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.colorFondo = Colors.white,
    this.colorTexto = Colores.azulOscuro,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          foregroundColor: colorTexto,
          elevation: 0,
          disabledBackgroundColor: colorFondo.withOpacity(0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: cargando
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorTexto,
                ),
              )
            : Text(
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
