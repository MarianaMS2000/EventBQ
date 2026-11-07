import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../repositories/usuario_repository.dart';
import '../utils/descarga_archivo.dart';
import '../utils/formato.dart';

/// Servicio para generar y descargar el ticket de evento en formato PDF.
/// - Incrusta fuentes TTF (Roboto) para soporte de tildes y caracteres en español.
/// - Dibuja el código QR real nativo con BarcodeWidget.
/// - Funciona sin conexión usando los datos en caché de la app.
class TicketPdfService {
  static Future<void> descargarTicketPdf({
    required Evento evento,
    Inscripcion? inscripcion,
  }) async {
    final repoEventos = EventoRepository();
    final repoUsuarios = UsuarioRepository();
    final usuario = repoUsuarios.obtenerUsuarioActual();

    // 1. Validaciones de seguridad
    if (evento.estado == 'Cancelado') {
      throw 'El evento fue cancelado por el organizador.';
    }

    final insc = inscripcion ?? repoEventos.obtenerInscripcion(evento.id);
    if (insc != null && insc.estado == 'Anulada') {
      throw 'Esta inscripción fue anulada. No es posible generar el ticket.';
    }

    // Código criptográfico único de la entrada
    final codigo = insc?.codigo ?? evento.id.padRight(24, '0');
    final uid = (insc != null && insc.uid.isNotEmpty) ? insc.uid : usuario.uid;
    final payloadQr = '${evento.id}|$uid|$codigo';

    // 2. Cargar fuentes TTF para soporte completo de tildes y eñes
    final fontRegularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttfRegular = pw.Font.ttf(fontRegularData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    // 3. Cargar logo opcional
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo_flor.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // 4. Crear documento PDF
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
      ),
    );

    const azulOscuro = PdfColor.fromInt(0xFF1E2852);
    const morado = PdfColor.fromInt(0xFF5A33D6);
    const grisFondo = PdfColor.fromInt(0xFFF6F8FB);
    const grisBorde = PdfColor.fromInt(0xFFE0E5EC);
    const grisTexto = PdfColor.fromInt(0xFF6B7280);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const pw.BoxDecoration(
                  color: azulOscuro,
                  borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(16)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 32,
                            height: 32,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(logoImage),
                          ),
                        pw.Text(
                          'EventBQ',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: morado,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        'BOLETO DIGITAL',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cuerpo del Ticket
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: grisFondo,
                  border: pw.Border.all(color: grisBorde, width: 1.5),
                  borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(16)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Título y Categoría
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: morado,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        evento.categoria.toUpperCase(),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      evento.titulo,
                      style: const pw.TextStyle(
                        color: azulOscuro,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: grisBorde, thickness: 1),
                    pw.SizedBox(height: 12),

                    // Fila de Datos: Fecha, Hora, Lugar, Precio
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: _datoColumna(
                            'FECHA Y HORA',
                            '${evento.fechaParaDetalle}\n${evento.horarioParaDetalle}',
                            azulOscuro,
                            grisTexto,
                          ),
                        ),
                        pw.Expanded(
                          child: _datoColumna(
                            'LUGAR',
                            evento.lugar,
                            azulOscuro,
                            grisTexto,
                          ),
                        ),
                        pw.Expanded(
                          child: _datoColumna(
                            'PRECIO',
                            evento.precio,
                            azulOscuro,
                            grisTexto,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),

                    // Datos del Asistente
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: grisBorde),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _datoColumna('ASISTENTE', usuario.nombre, azulOscuro, grisTexto),
                          _datoColumna('USUARIO', '@${usuario.usuario}', azulOscuro, grisTexto),
                          _datoColumna('ESTADO', insc?.estado ?? 'Activa', azulOscuro, grisTexto),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Bloque del QR
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'CÓDIGO DE ACCESO EN PUERTA',
                            style: const pw.TextStyle(
                              color: azulOscuro,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(color: grisBorde, width: 1.5),
                            ),
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: payloadQr,
                              width: 140,
                              height: 140,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            codigo,
                            style: const pw.TextStyle(
                              color: azulOscuro,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Presenta este código al ingresar para su escaneo o validación manual.',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              color: grisTexto,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Pie de página
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Este código QR es de un solo uso y quedará invalidado inmediatamente al registrarse el ingreso en puerta.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(color: grisTexto, fontSize: 9),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generado el ${formatoFecha(DateTime.now())} a través de EventBQ.',
                      style: const pw.TextStyle(color: grisTexto, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 5. Nombre de archivo sanitizado: ticket_<titulo-del-evento>.pdf
    final tituloSanitizado = evento.titulo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final nombreArchivo = 'ticket_$tituloSanitizado.pdf';

    // 6. Compartir / Descargar / Imprimir (multiplataforma)
    await descargarOCompartirPdf(
      bytes: await pdf.save(),
      nombreArchivo: nombreArchivo,
    );
  }

  static pw.Widget _datoColumna(
    String etiqueta,
    String valor,
    PdfColor colorValor,
    PdfColor colorEtiqueta,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          etiqueta,
          style: pw.TextStyle(
            color: colorEtiqueta,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          valor,
          style: pw.TextStyle(
            color: colorValor,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
