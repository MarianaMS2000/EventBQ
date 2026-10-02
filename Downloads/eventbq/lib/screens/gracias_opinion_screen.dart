import 'package:flutter/material.dart';
import '../navegacion.dart';
import '../theme/colores.dart';
import '../widgets/mascota_gracias.dart';

class GraciasOpinionScreen extends StatelessWidget {
  const GraciasOpinionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.azulOscuro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        MascotaGracias(tamano: 150),
                        SizedBox(height: 40),
                        Text(
                          '¡Gracias por tu\nopinión!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 26),
                        Text(
                          'Tu valoración ayuda al organizador a mejorar sus futuros eventos y a la comunidad a descubrir las mejores experiencias',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => irAPestana(context, 0),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
