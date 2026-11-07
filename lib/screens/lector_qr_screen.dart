import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/evento.dart';
import '../repositories/cambios.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';

/// Pantalla "Control de Acceso / Validador en puerta".
/// Permite escanear el código QR del asistente con la cámara o ingresar
/// el código manualmente, validando contra Firestore en ≤ 3 segundos.
class LectorQrScreen extends StatefulWidget {
  const LectorQrScreen({super.key});

  @override
  State<LectorQrScreen> createState() => _LectorQrScreenState();
}

class _LectorQrScreenState extends State<LectorQrScreen> {
  final _repo = EventoRepository();
  final _codigoCtrl = TextEditingController();
  late final MobileScannerController _scannerCtrl;

  bool _modoManual = false;
  bool _validando = false;
  String? _eventoIdSeleccionado;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_eventoIdSeleccionado == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Evento) {
        _eventoIdSeleccionado = args.id;
      } else {
        final creados = _repo.obtenerEventosCreados();
        if (creados.isNotEmpty) {
          _eventoIdSeleccionado = creados.first.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar(String payload) async {
    if (_validando || payload.trim().isEmpty) return;
    setState(() => _validando = true);

    try {
      final resultado = await _repo.validarAcceso(
        qrOPayload: payload.trim(),
        eventoIdSeleccionado: _eventoIdSeleccionado,
      );

      if (!mounted) return;
      await _mostrarResultado(resultado);
    } finally {
      if (mounted) {
        setState(() => _validando = false);
      }
    }
  }

  Future<void> _mostrarResultado(ResultadoValidacion res) async {
    if (res.exito) {
      _codigoCtrl.clear();
    }
    try {
      await _scannerCtrl.stop();
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: res.exito ? const Color(0xFFE6F9EE) : const Color(0xFFFFECEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  res.exito ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: res.exito ? const Color(0xFF00B074) : const Color(0xFFF44336),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                res.exito ? '¡ACCESO CONCEDIDO!' : 'ACCESO DENEGADO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: res.exito ? const Color(0xFF00875A) : const Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                res.mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colores.azulOscuro,
                  height: 1.3,
                ),
              ),
              if (res.nombreAsistente != null && res.nombreAsistente!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 20, color: Colores.azulMedio),
                      const SizedBox(width: 8),
                      Text(
                        res.nombreAsistente!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colores.azulOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: res.exito ? Colores.azulOscuro : const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    res.exito ? 'Continuar escaneando' : 'Volver a intentar',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (mounted && !_modoManual) {
      try {
        await _scannerCtrl.start();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return EscuchaDatos(
      builder: (context) {
        final eventos = _repo.obtenerEventosCreados();
        if (_eventoIdSeleccionado == null && eventos.isNotEmpty) {
          _eventoIdSeleccionado = eventos.first.id;
        }

        return Scaffold(
          backgroundColor: Colores.azulOscuro,
          appBar: AppBar(
            backgroundColor: Colores.azulOscuro,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Control de Acceso',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            actions: [
              IconButton(
                tooltip: _modoManual ? 'Escanear QR con cámara' : 'Ingresar código manual',
                icon: Icon(_modoManual ? Icons.qr_code_scanner : Icons.keyboard),
                onPressed: () {
                  setState(() => _modoManual = !_modoManual);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Selector de evento
                if (eventos.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _eventoIdSeleccionado,
                        dropdownColor: Colores.azulOscuro,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        items: eventos.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(
                              e.titulo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _eventoIdSeleccionado = val);
                        },
                      ),
                    ),
                  ),

                Expanded(
                  child: _modoManual ? _vistaManual() : _vistaCamara(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vistaCamara() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _scannerCtrl,
          errorBuilder: (ctx, error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 56),
                    const SizedBox(height: 14),
                    const Text(
                      'Cámara no disponible en este entorno',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes usar el ingreso manual de código para validar entradas al instante.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _modoManual = true),
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Ingresar código manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colores.celesteBoton,
                        foregroundColor: Colores.azulOscuro,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          onDetect: (capture) {
            if (_validando) return;
            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                _validar(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // Marco de escaneo visual
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        Positioned(
          bottom: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_validando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  const Icon(Icons.qr_code, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _validando ? 'Validando entrada...' : 'Apunta al código QR del asistente',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaManual() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.confirmation_number_outlined, color: Colores.azulOscuro, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Validación Manual por Código',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colores.azulOscuro),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escribe o pega el código de 24 caracteres que aparece en el ticket del asistente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colores.grisTexto),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Ej: W7K9D2F5P1...',
                labelText: 'Código del ticket',
                filled: true,
                fillColor: const Color(0xFFF3F5FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colores.azulMedio),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _validando ? null : () => _validar(_codigoCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.azulOscuro,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _validando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Validar Entrada',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _modoManual = false),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Volver a escanear con cámara'),
            ),
          ],
        ),
      ),
    );
  }
}
