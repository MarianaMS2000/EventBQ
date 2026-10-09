import 'package:flutter/material.dart';
import '../widgets/logo_flor.dart';

/// Flor blanca centrada para los encabezados (planes, pago, etc.).
/// Usa assets/images/logo_flor.png (ver LogoFlor).
class FlorEncabezado extends StatelessWidget {
  final double tamano;

  const FlorEncabezado({super.key, this.tamano = 64});

  @override
  Widget build(BuildContext context) {
    return Center(child: LogoFlor(tamano: tamano));
  }
}
