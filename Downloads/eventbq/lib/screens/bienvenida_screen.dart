import 'package:flutter/material.dart';
import '../theme/colores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/imagen_asset.dart';
import '../widgets/logo_flor.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.azulMedio,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const LogoFlor(tamano: 30),
              const SizedBox(height: 4),
              const Text(
                'EventBQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Ilustración (placeholder hasta que agregues assets/images/bienvenida.png)
              const Expanded(
                child: ImagenAsset(
                  ruta: 'assets/images/bienvenida.png',
                  fit: BoxFit.contain,
                  colorPlaceholder: Color(0xFF0F2A6B),
                  iconoPlaceholder: Icons.celebration,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ingresa a tu cuenta para\nunirte al grupo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              BotonPrincipal(
                texto: 'Iniciar Sesión',
                colorFondo: Colores.azulOscuro,
                colorTexto: Colors.white,
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 14),
              BotonPrincipal(
                texto: 'Registrarse',
                colorFondo: Colores.fondo,
                colorTexto: Colores.azulOscuro,
                onPressed: () => Navigator.pushNamed(context, '/registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
