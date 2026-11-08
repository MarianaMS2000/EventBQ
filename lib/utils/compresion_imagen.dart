import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../widgets/imagen_asset.dart';

/// Genera una miniatura pequeña (< 35 KB) para el documento principal de Firestore (Plan B).
/// Reduce el ancho a ~360 px usando el motor gráfico nativo de Flutter (dart:ui).
Future<String> generarMiniaturaBase64(Uint8List bytesOriginales, {int maxAncho = 360}) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytesOriginales,
      targetWidth: maxAncho,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      return ImagenAsset.bytesATexto(pngBytes);
    }
  } catch (e) {
    debugPrint('Aviso al generar miniatura con dart:ui: $e');
  }
  // Si dart:ui no pudo procesarlo (ej. entorno headless de test), retorna el original
  return ImagenAsset.bytesATexto(bytesOriginales);
}
