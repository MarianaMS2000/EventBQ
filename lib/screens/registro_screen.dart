import 'package:flutter/material.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto_auth.dart';
import '../widgets/encabezado_auth.dart';
import '../widgets/enlace_auth.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  final _usuarioRepo = UsuarioRepository();

  @override
  void dispose() {
    _nombre.dispose();
    _usuario.dispose();
    _email.dispose();
    _clave.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _crearCuenta() {
    if (_nombre.text.trim().isEmpty ||
        _usuario.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _clave.text.isEmpty) {
      _mensaje('Completa todos los campos');
      return;
    }
    if (_clave.text != _confirmar.text) {
      _mensaje('Las contraseñas no coinciden');
      return;
    }
    final error = _usuarioRepo.registrar(
      nombre: _nombre.text,
      usuario: _usuario.text,
      correo: _email.text,
      clave: _clave.text,
    );
    if (error != null) {
      _mensaje(error);
      return;
    }
    // Cuenta nueva: siempre empieza con los 3 onboarding.
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
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
                titulo: 'Registrarse',
                subtitulo: 'Crea una cuenta, es gratis',
              ),
              const SizedBox(height: 30),
              CampoTextoAuth(hint: 'Nombre completo', controller: _nombre),
              const SizedBox(height: 14),
              CampoTextoAuth(hint: 'Usuario', controller: _usuario),
              const SizedBox(height: 14),
              CampoTextoAuth(
                hint: 'Email',
                controller: _email,
                tipoTeclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              CampoTextoAuth(hint: 'Contraseña', controller: _clave, esClave: true),
              const SizedBox(height: 14),
              CampoTextoAuth(
                hint: 'Confirmar Contraseña',
                controller: _confirmar,
                esClave: true,
              ),
              const SizedBox(height: 22),
              BotonPrincipal(
                texto: 'Crear cuenta',
                colorFondo: Colores.fondo,
                onPressed: _crearCuenta,
              ),
              const SizedBox(height: 12),
              EnlaceAuth(
                pregunta: 'Ya tienes una cuenta?',
                accion: 'Ingresa',
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
