import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/evento_repository.dart';
import 'flor_encabezado.dart';
import 'suscripcion_activa_screen.dart';

/// Pantalla "Pagar y suscribirme".
/// Se abre desde PlanesScreen al tocar "Suscribirme" en cualquier plan.
class PagoSuscripcionScreen extends StatefulWidget {
  final String nombrePlan; // Ej: 'Asistente Pro'
  final int precio; // Ej: 9900
  final IconData icono;
  final String? imagen; // ilustración del plan (si no existe, se usa el ícono)

  const PagoSuscripcionScreen({
    super.key,
    required this.nombrePlan,
    required this.precio,
    required this.icono,
    this.imagen,
  });

  @override
  State<PagoSuscripcionScreen> createState() => _PagoSuscripcionScreenState();
}

class _PagoSuscripcionScreenState extends State<PagoSuscripcionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _vencimientoCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _vencimientoCtrl.dispose();
    _cvvCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  /// 180000 -> "180.000"
  String _formatearPrecio(int valor) {
    final texto = valor.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
      buffer.write(texto[i]);
    }
    return buffer.toString();
  }

  void _pagar() {
    if (!_formKey.currentState!.validate()) return;

    // Pago correcto -> pantalla de suscripción activa
    // Si pagó el plan Organizador Pro, ya puede publicar sin límite.
    if (widget.nombrePlan == 'Organizador Pro') {
      EventoRepository().activarPlanOrganizador();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/suscripcion-activa'),
        builder: (_) => const SuscripcionActivaScreen(),
      ),
    );
  }

  InputDecoration _decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFF6E7BEA).withOpacity(0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      errorStyle: const TextStyle(color: Color(0xFFFFB4C8), fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFB4C8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFB4C8), width: 1.4),
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final precioTxt = 'COP \$${_formatearPrecio(widget.precio)}';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4A1FA8),
              Color(0xFF7A4EE6),
              Color(0xFF6B3FA8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flecha de volver
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),

                  // Flor (centrada)
                  const FlorEncabezado(tamano: 64),
                  const SizedBox(height: 10),

                  // Título (centrado)
                  const Center(
                    child: Text(
                      'Pagar y suscribirme',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ===== Resumen =====
                  const Text(
                    'Resumen de suscripción:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E7BEA).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              widget.imagen == null
                                  ? Icon(widget.icono,
                                      color: Colors.white, size: 44)
                                  : Image.asset(
                                      widget.imagen!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) =>
                                          Icon(widget.icono,
                                              color: Colors.white, size: 44),
                                    ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Plan ${widget.nombrePlan}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$precioTxt / mes',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1, color: Colors.white.withOpacity(0.4)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Column(
                            children: [
                              _filaTotal('Subtotal:', precioTxt),
                              const SizedBox(height: 2),
                              _filaTotal('Impuestos (mes):', 'COP \$0.00'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ===== Método de pago =====
                  const Text(
                    'Método de pago:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Número de Tarjeta:'),
                        TextFormField(
                          controller: _numeroCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          inputFormatters: [_FormatoTarjeta()],
                          decoration: _decoracion('#### #### #### ####'),
                          validator: (v) {
                            final digitos = (v ?? '').replaceAll(' ', '');
                            if (digitos.length != 16) {
                              return 'Ingresa los 16 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _etiqueta('Vencimiento:'),
                                  TextFormField(
                                    controller: _vencimientoCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    inputFormatters: [_FormatoVencimiento()],
                                    decoration: _decoracion('MM/AA'),
                                    validator: (v) {
                                      final t = v ?? '';
                                      if (t.length != 5) return 'MM/AA';
                                      final mes =
                                          int.tryParse(t.substring(0, 2));
                                      if (mes == null || mes < 1 || mes > 12) {
                                        return 'Mes inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _etiqueta('CVV:'),
                                  TextFormField(
                                    controller: _cvvCtrl,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    decoration: _decoracion('•••'),
                                    validator: (v) {
                                      final t = v ?? '';
                                      if (t.length < 3) return '3 o 4 dígitos';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _etiqueta('Nombre en la Tarjeta:'),
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoracion('Nombre del titular'),
                          validator: (v) {
                            if ((v ?? '').trim().length < 3) {
                              return 'Ingresa el nombre del titular';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ===== Botón pagar =====
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB85CC4), Color(0xFF8B128E)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _pagar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Pagar y suscribirme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaTotal(String izquierda, String derecha) {
    const estilo = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(izquierda, style: estilo),
        Text(derecha, style: estilo),
      ],
    );
  }
}

/// Formatea el número de tarjeta como "#### #### #### ####".
class _FormatoTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    var digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 16) digitos = digitos.substring(0, 16);

    final buffer = StringBuffer();
    for (int i = 0; i < digitos.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Formatea el vencimiento como "MM/AA".
class _FormatoVencimiento extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    var digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 4) digitos = digitos.substring(0, 4);

    var texto = digitos;
    if (digitos.length > 2) {
      texto = '${digitos.substring(0, 2)}/${digitos.substring(2)}';
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
