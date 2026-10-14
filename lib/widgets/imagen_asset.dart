import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Muestra una imagen. `ruta` puede ser:
///  - un asset ("assets/images/foto.jpg")
///  - una imagen elegida de la galería guardada como texto ("base64:....")
/// Si no existe o está vacía, muestra un placeholder de color con un ícono
/// (así la app nunca se rompe).
/// Debe ir dentro de un widget con tamaño (SizedBox, Expanded, etc.).
class ImagenAsset extends StatelessWidget {
  final String ruta;

  /// Si `ruta` no existe, se intenta con esta antes de mostrar el placeholder.
  final String? rutaRespaldo;
  final BoxFit fit;
  final Color colorPlaceholder;
  final IconData iconoPlaceholder;

  const ImagenAsset({
    super.key,
    required this.ruta,
    this.rutaRespaldo,
    this.fit = BoxFit.cover,
    this.colorPlaceholder = const Color(0xFF9AA5C4),
    this.iconoPlaceholder = Icons.image_outlined,
  });

  static const _prefijo = 'base64:';

  // Para no decodificar el mismo texto en cada redibujado.
  static final Map<String, Uint8List> _cache = {};

  /// Convierte los bytes de una imagen en el texto que se guarda en SharedPreferences.
  static String bytesATexto(Uint8List bytes) =>
      '$_prefijo${base64Encode(bytes)}';

  static Uint8List? _bytes(String ruta) {
    if (!ruta.startsWith(_prefijo)) return null;
    return _cache.putIfAbsent(
      ruta,
      () => base64Decode(ruta.substring(_prefijo.length)),
    );
  }

  Widget _imagen(String r, Widget Function() siFalla) {
    if (r.isEmpty) return siFalla();
    if (r.startsWith(_prefijo)) {
      try {
        return Image.memory(
          _bytes(r)!,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => siFalla(),
        );
      } catch (_) {
        return siFalla();
      }
    }
    return Image.asset(
      r,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => siFalla(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: colorPlaceholder,
      child: Center(
        child: Icon(iconoPlaceholder, color: Colors.white70, size: 36),
      ),
    );

    return _imagen(ruta, () {
      if (rutaRespaldo == null) return placeholder;
      return _imagen(rutaRespaldo!, () => placeholder);
    });
  }
}
