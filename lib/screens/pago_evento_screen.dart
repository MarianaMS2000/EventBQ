import 'dart:async';
import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../theme/colores.dart';
import '../utils/manejo_errores.dart';
import '../widgets/imagen_asset.dart';

enum MetodoPagoEvento { nequi, daviplata, efectivo, tarjeta }

class PagoEventoScreen extends StatefulWidget {
  final Evento evento;

  const PagoEventoScreen({super.key, required this.evento});

  @override
  State<PagoEventoScreen> createState() => _PagoEventoScreenState();
}

class _PagoEventoScreenState extends State<PagoEventoScreen> {
  MetodoPagoEvento _metodoSeleccionado = MetodoPagoEvento.nequi;

  final _telefonoCtrl = TextEditingController(text: '3001234567');
  final _tarjetaCtrl = TextEditingController();
  final _vencimientoCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _procesando = false;
  bool _esperandoAprobacionNequi = false;
  String? _referenciaGenerada;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _tarjetaCtrl.dispose();
    _vencimientoCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _nombreMetodo(MetodoPagoEvento m) {
    switch (m) {
      case MetodoPagoEvento.nequi:
        return 'Nequi';
      case MetodoPagoEvento.daviplata:
        return 'Daviplata';
      case MetodoPagoEvento.efectivo:
        return 'Efectivo (Efecty / Baloto)';
      case MetodoPagoEvento.tarjeta:
        return 'Tarjeta Débito / PSE';
    }
  }

  String _generarReferencia(MetodoPagoEvento m) {
    final prefix = m == MetodoPagoEvento.nequi
        ? 'NEQ'
        : m == MetodoPagoEvento.daviplata
            ? 'DAV'
            : m == MetodoPagoEvento.efectivo
                ? 'EFY'
                : 'PSE';
    final randomDigits = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '#$prefix-$randomDigits';
  }

  Future<void> _iniciarPago() async {
    if (_metodoSeleccionado == MetodoPagoEvento.nequi) {
      if (_telefonoCtrl.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un número de celular Nequi válido (10 dígitos)')),
        );
        return;
      }

      setState(() {
        _procesando = true;
        _esperandoAprobacionNequi = true;
      });

      // Simular notificación push de Nequi al celular
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() => _procesando = false);
      return;
    }

    if (_metodoSeleccionado == MetodoPagoEvento.daviplata) {
      if (_telefonoCtrl.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa tu número celular Daviplata (10 dígitos)')),
        );
        return;
      }
    }

    await _confirmarPagoFinal();
  }

  Future<void> _confirmarPagoFinal() async {
    setState(() => _procesando = true);
    final metodoNombre = _nombreMetodo(_metodoSeleccionado);
    final ref = _referenciaGenerada ?? _generarReferencia(_metodoSeleccionado);
    _referenciaGenerada = ref;

    try {
      // Registrar la entrada en Firestore con los datos del pago
      final error = await EventoRepository().agregarEntrada(
        widget.evento,
        metodoPago: metodoNombre,
        referenciaPago: ref,
      );

      if (!mounted) return;
      setState(() => _procesando = false);

      if (error != null) {
        mostrarDialogoError(context, error: error);
        return;
      }

      // Redirigir a Registro Exitoso con la entrada generada
      final ultimaInscripcion = EventoRepository().obtenerUltimaInscripcion(widget.evento.id);
      Navigator.pushReplacementNamed(
        context,
        '/registro-exitoso',
        arguments: {
          'evento': widget.evento,
          'inscripcion': ultimaInscripcion,
          'pagoConfirmado': true,
          'metodoPago': metodoNombre,
          'referenciaPago': ref,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      mostrarDialogoError(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evento;

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        backgroundColor: Colores.azulOscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirmar y Pagar Entrada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _procesando ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----- Resumen del Evento -----
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: ImagenAsset(ruta: e.imagen),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📅 ${e.fechaCorta} · 📍 ${e.lugar}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colores.grisTexto),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.precio,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulBrillante,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ----- Desglose de Pago -----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD5D8E0)),
                ),
                child: Column(
                  children: [
                    _filaResumen('1x Entrada General', e.precio),
                    const SizedBox(height: 8),
                    _filaResumen('Comisión de servicio EventBQ', 'GRATIS (\$ 0)'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a Pagar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colores.azulOscuro,
                          ),
                        ),
                        Text(
                          e.precio,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colores.azulOscuro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Selecciona cómo deseas pagar:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                ),
              ),
              const SizedBox(height: 12),

              // ----- Opciones de Pago -----
              _tarjetaOpcion(
                metodo: MetodoPagoEvento.nequi,
                titulo: 'Nequi',
                subtitulo: 'Paga al instante con tu número de celular',
                icono: Icons.phone_android_rounded,
                colorIcono: const Color(0xFF6C2D82),
                colorFondoIcono: const Color(0xFFF5E6FA),
              ),
              const SizedBox(height: 10),

              _tarjetaOpcion(
                metodo: MetodoPagoEvento.daviplata,
                titulo: 'Daviplata',
                subtitulo: 'Billetera móvil sin comisiones ni tarjeta',
                icono: Icons.account_balance_wallet_rounded,
                colorIcono: const Color(0xFFD82424),
                colorFondoIcono: const Color(0xFFFFEEEE),
              ),
              const SizedBox(height: 10),

              _tarjetaOpcion(
                metodo: MetodoPagoEvento.efectivo,
                titulo: 'Efectivo en Efecty / Puntos de Pago',
                subtitulo: 'Paga con PIN de recaudo en efectivo en cualquier punto',
                icono: Icons.storefront_rounded,
                colorIcono: const Color(0xFFD97706),
                colorFondoIcono: const Color(0xFFFEF3C7),
              ),
              const SizedBox(height: 10),

              _tarjetaOpcion(
                metodo: MetodoPagoEvento.tarjeta,
                titulo: 'Tarjeta Débito / PSE / Crédito',
                subtitulo: 'Paga con tarjeta bancaria o PSE nacional',
                icono: Icons.credit_card_rounded,
                colorIcono: Colores.azulBrillante,
                colorFondoIcono: const Color(0xFFE8EEF8),
              ),

              const SizedBox(height: 20),

              // ----- Formulario dinámico según el método -----
              if (_esperandoAprobacionNequi && _metodoSeleccionado == MetodoPagoEvento.nequi)
                _seccionAprobacionNequi()
              else
                _seccionFormularioMetodo(),

              const SizedBox(height: 24),

              // Botón de Pago Principal
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _procesando
                      ? null
                      : (_esperandoAprobacionNequi ? _confirmarPagoFinal : _iniciarPago),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.azulOscuro,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _procesando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _esperandoAprobacionNequi
                              ? 'Ya aprobé en Nequi · Finalizar Compra'
                              : 'Pagar ${e.precio}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '🔒 Pago protegido con cifrado SSL. Si no completas el pago, no se emitirá el ticket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colores.grisTexto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaResumen(String concepto, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(concepto, style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A55))),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.azulOscuro)),
      ],
    );
  }

  Widget _tarjetaOpcion({
    required MetodoPagoEvento metodo,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorIcono,
    required Color colorFondoIcono,
  }) {
    final seleccionada = _metodoSeleccionado == metodo;

    return GestureDetector(
      onTap: () {
        setState(() {
          _metodoSeleccionado = metodo;
          _esperandoAprobacionNequi = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada ? Colores.azulOscuro : const Color(0xFFE2E5EC),
            width: seleccionada ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colorFondoIcono, shape: BoxShape.circle),
              child: Icon(icono, color: colorIcono, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: seleccionada ? Colores.azulOscuro : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 11, color: Colores.grisTexto)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: seleccionada ? Colores.azulOscuro : const Color(0xFFB0B5C1),
                  width: 2,
                ),
              ),
              child: seleccionada
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colores.azulOscuro,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionFormularioMetodo() {
    if (_metodoSeleccionado == MetodoPagoEvento.nequi ||
        _metodoSeleccionado == MetodoPagoEvento.daviplata) {
      final nombre = _metodoSeleccionado == MetodoPagoEvento.nequi ? 'Nequi' : 'Daviplata';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD5D8E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Número celular de $nombre:',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colores.azulOscuro),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Colores.azulOscuro),
                hintText: 'Ej: 3001234567',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF3F5FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Te enviaremos una notificación a tu app $nombre para autorizar el cobro.',
              style: const TextStyle(fontSize: 11, color: Colores.grisTexto),
            ),
          ],
        ),
      );
    }

    if (_metodoSeleccionado == MetodoPagoEvento.efectivo) {
      final pin = (widget.evento.id.hashCode.abs() % 900000 + 100000).toString();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 22),
                SizedBox(width: 8),
                Text(
                  'Instrucciones de Pago en Efectivo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Acércate a cualquier punto Efecty o Baloto a nivel nacional.\n'
              '2. Indica el número de convenio: Convenio EventBQ #110825.\n'
              '3. Entrega el PIN de recaudo para cancelar tu entrada en efectivo.',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                children: [
                  const Text('PIN DE RECAUDO EN EFECTIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                  const SizedBox(height: 4),
                  Text(
                    pin,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colores.azulOscuro),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tarjeta Débito / PSE
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5D8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Número de Tarjeta o Cuenta Bancaria:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colores.azulOscuro)),
          const SizedBox(height: 8),
          TextField(
            controller: _tarjetaCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card, color: Colores.azulOscuro),
              hintText: '4000 1234 5678 9010',
              filled: true,
              fillColor: const Color(0xFFF3F5FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionAprobacionNequi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD08CE8), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF6C2D82), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            '¡Solicitud enviada a tu Nequi!',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A105D)),
          ),
          const SizedBox(height: 6),
          Text(
            'Revisa la notificación en tu celular (${_telefonoCtrl.text}) y acepta el cobro de ${widget.evento.precio}.\nUna vez aprobado, presiona el botón abajo para confirmar tu ticket.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A105D), height: 1.35),
          ),
        ],
      ),
    );
  }
}
