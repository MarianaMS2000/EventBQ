import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'preferences/preferencias_usuario.dart';
import 'repositories/usuario_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // SharedPreferences debe estar listo antes de arrancar la app
  await PreferenciasUsuario.init();
  await UsuarioRepository().inicializar();

  runApp(const EventBQApp());
}
