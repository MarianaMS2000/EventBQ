import 'package:flutter/material.dart';
import '../preferences/preferencias_usuario.dart';
import '../theme/colores.dart';
import '../widgets/logo_flor.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _decidirDestino);
  }

  // Usa SharedPreferences para saber a dónde ir
  void _decidirDestino() {
    if (!mounted) return;
    String ruta;
    if (!PreferenciasUsuario.sesionIniciada) {
      ruta = '/bienvenida';
    } else if (!PreferenciasUsuario.onboardingCompletado) {
      ruta = '/onboarding';
    } else {
      ruta = '/home';
    }
    Navigator.pushReplacementNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.azulMedio,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              LogoFlor(tamano: 90),
              SizedBox(height: 8),
              Text(
                'EventBQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tu espacio para encontrarnos,\nhablar y celebrar juntos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
