import 'package:flutter/material.dart';
import '../navegacion.dart';

/// Pantalla "¡Bienvenido a EventBQ Premium!".
/// Se abre al terminar el pago en PagoSuscripcionScreen.
class SuscripcionActivaScreen extends StatelessWidget {
  const SuscripcionActivaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Evita volver al formulario de pago con el botón atrás.
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF4A1FA8),
                Color(0xFF8B5FD6),
                Color(0xFF6B3FA8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Carita feliz con destellos: assets/images/premium_activo.png
                  // (si no existe, se dibuja con íconos).
                  SizedBox(
                    width: 150,
                    height: 130,
                    child: Image.asset(
                      'assets/images/premium_activo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Stack(
                      clipBehavior: Clip.none,
                      children: const [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.sentiment_very_satisfied_rounded,
                            color: Color(0xFFEDEDED),
                            size: 110,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 0,
                          child: Icon(Icons.auto_awesome,
                              color: Colors.white, size: 38),
                        ),
                        Positioned(
                          right: 34,
                          top: 4,
                          child: Icon(Icons.star_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    '¡Bienvenido a\nEventBQ Premium!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Tu suscripción se ha\nactivado correctamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.35,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Flecha para continuar -> Inicio
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      iconSize: 34,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      onPressed: () => irAPestana(context, 0),
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
}
