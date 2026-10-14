import 'package:flutter/material.dart';
import '../preferences/preferencias_usuario.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto_auth.dart';
import '../widgets/encabezado_auth.dart';
import '../widgets/enlace_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _usuarioRepo = UsuarioRepository();

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _ingresar() {
    FocusScope.of(context).unfocus();
    final error = _usuarioRepo.iniciarSesion(_usuario.text, _clave.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final ruta = PreferenciasUsuario.onboardingCompletado ? '/home' : '/onboarding';
    Navigator.pushNamedAndRemoveUntil(context, ruta, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.azulOscuro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoAuth(
                titulo: 'Hola\nBienvenido!',
                subtitulo: 'Es un gusto tenerte devuelta',
              ),
              const SizedBox(height: 40),
              CampoTextoAuth(hint: 'Usuario o Email', controller: _usuario),
              const SizedBox(height: 14),
              CampoTextoAuth(hint: 'Contraseña', controller: _clave, esClave: true),
              const SizedBox(height: 16),
              BotonPrincipal(
                texto: 'Ingresa',
                colorFondo: Colores.fondo,
                onPressed: _ingresar,
              ),
              const SizedBox(height: 12),
              EnlaceAuth(
                pregunta: 'No tienes una cuenta?',
                accion: 'Registrate',
                onPressed: () => Navigator.pushReplacementNamed(context, '/registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
