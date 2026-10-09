import 'package:flutter/material.dart';
import 'flor_encabezado.dart';
import 'pago_suscripcion_screen.dart';

class PlanesScreen extends StatelessWidget {
  const PlanesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si llegan desde "¡Límite alcanzado!" solo se muestra el plan de
    // Organizador (arguments: 'organizador').
    final soloOrganizador =
        ModalRoute.of(context)?.settings.arguments == 'organizador';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5324D7), // Púrpura intenso superior
              Color(0xFF7A4EE6),
              Color(0xFF915CEB), // Violeta claro inferior
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Flor Premium
                    const FlorEncabezado(tamano: 56),
                    const SizedBox(height: 8),

                    // Título Principal
                    const Text(
                      'EventBQ Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo
                    const Text(
                      'Lleva tu experiencia al\nsiguiente nivel con\nbeneficios exclusivos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (!soloOrganizador) ...[
                    // ===== Tarjeta Asistente Pro =====
                    _buildTarjetaPlan(
                      titulo: 'Asistente Pro',
                      subtitulo: 'Para amantes de los eventos',
                      precio: '\$9.900',
                      frecuencia: '/ mes Pro',
                      colorTitulo: Colors.white,
                      gradientBoton: const LinearGradient(
                        colors: [Color(0xFFB03FB3), Color(0xFF8B128E)],
                      ),
                      beneficios: const [
                        'Acceso anticipado a eventos con aforo limitado',
                        'Entradas digitales con validación rápida sin filas',
                        'Descuentos exclusivos en la compra de entradas para eventos',
                        'Opción de ceder o transferir tu cupo/entrada digital fácilmente a un amigo si no puedes asistir',
                      ],
                      onSuscribirme: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings:
                                const RouteSettings(name: '/pago-suscripcion'),
                            builder: (_) => const PagoSuscripcionScreen(
                              nombrePlan: 'Asistente Pro',
                              precio: 9900,
                              icono: Icons.confirmation_number_rounded,
                              imagen: 'assets/images/plan_asistente.png',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    ],

                    // ===== Tarjeta Organizador Pro =====
                    _buildTarjetaPlan(
                      titulo: 'Organizador Pro',
                      subtitulo: 'Para creadores y marcas',
                      precio: '\$180.000',
                      frecuencia: '/ mes Pro',
                      colorTitulo:
                          const Color(0xFF38E0FD), // Azul cian brillante
                      gradientBoton: const LinearGradient(
                        colors: [Color(0xFF4C87CA), Color(0xFF1B3B82)],
                      ),
                      beneficios: const [
                        'Publicación de eventos ilimitados (supera el límite gratis de 2 eventos / 6 meses)',
                        'Tus eventos aparecerán destacados en los primeros lugares de la pantalla principal (Home)',
                        'Escaneo simultáneo de códigos digitales en puertas de entrada con múltiples miembros de tu equipo.',
                      ],
                      onSuscribirme: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            settings:
                                const RouteSettings(name: '/pago-suscripcion'),
                            builder: (_) => const PagoSuscripcionScreen(
                              nombrePlan: 'Organizador Pro',
                              precio: 180000,
                              icono: Icons.support_agent_rounded,
                              imagen: 'assets/images/plan_organizador.png',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Botón para volver
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaPlan({
    required String titulo,
    required String subtitulo,
    required String precio,
    required String frecuencia,
    required Color colorTitulo,
    required LinearGradient gradientBoton,
    required List<String> beneficios,
    required VoidCallback onSuscribirme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6E56E8).withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: colorTitulo,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          // Precio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                precio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                frecuencia,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón Suscribirme
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradientBoton,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onSuscribirme,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Suscribirme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Beneficios
          Column(
            children: beneficios.map((beneficio) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        beneficio,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
