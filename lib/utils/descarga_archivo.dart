import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'descarga_archivo_stub.dart'
    if (dart.library.html) 'descarga_archivo_web.dart';

/// Descarga o comparte el PDF de forma multiplataforma:
/// - En Web: descarga directa del archivo o visor de impresión.
/// - En Móvil: diálogo nativo de compartir / guardar / imprimir.
Future<void> descargarOCompartirPdf({
  required Uint8List bytes,
  required String nombreArchivo,
}) async {
  if (kIsWeb) {
    try {
      await descargarBytesEnNavegador(bytes, nombreArchivo);
    } catch (_) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: nombreArchivo,
      );
    }
  } else {
    await Printing.sharePdf(
      bytes: bytes,
      filename: nombreArchivo,
    );
  }
}
