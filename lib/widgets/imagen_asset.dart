import 'package:flutter/material.dart';

/// Muestra una imagen de assets. Si el archivo todavía no existe,
/// muestra un placeholder de color con un ícono (así la app nunca se rompe).
/// Debe ir dentro de un widget con tamaño (SizedBox, Expanded, etc.).
class ImagenAsset extends StatelessWidget {
  final String ruta;
  final BoxFit fit;
  final Color colorPlaceholder;
  final IconData iconoPlaceholder;

  const ImagenAsset({
    super.key,
    required this.ruta,
    this.fit = BoxFit.cover,
    this.colorPlaceholder = const Color(0xFF9AA5C4),
    this.iconoPlaceholder = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ruta,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorPlaceholder,
          child: Center(
            child: Icon(iconoPlaceholder, color: Colors.white70, size: 36),
          ),
        );
      },
    );
  }
}
