import 'package:flutter/material.dart';

OverlayEntry? _avisoActual;

/// Muestra un aviso verde pequeño arriba de la pantalla ("¡Cambio exitoso!")
/// que baja con una animación, se queda un momento y se va solo.
///
/// Uso:  mostrarAvisoExito(context, '¡Datos actualizados con éxito!');
void mostrarAvisoExito(BuildContext context, String mensaje) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // Si todavía hay uno en pantalla, se reemplaza por el nuevo.
  _avisoActual?.remove();
  _avisoActual = null;

  late OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => _AvisoExito(
      mensaje: mensaje,
      alTerminar: () {
        if (identical(_avisoActual, entrada)) _avisoActual = null;
        entrada.remove();
      },
    ),
  );
  _avisoActual = entrada;
  overlay.insert(entrada);
}

class _AvisoExito extends StatefulWidget {
  final String mensaje;
  final VoidCallback alTerminar;

  const _AvisoExito({required this.mensaje, required this.alTerminar});

  @override
  State<_AvisoExito> createState() => _AvisoExitoState();
}

class _AvisoExitoState extends State<_AvisoExito>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<Offset> _desliza = Tween<Offset>(
    begin: const Offset(0, -0.8),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  ));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2400), _salir);
  }

  Future<void> _salir() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.alTerminar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position: _desliza,
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2FB877), Color(0xFF1E9C62)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 16, color: Color(0xFF1E9C62)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.mensaje,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
