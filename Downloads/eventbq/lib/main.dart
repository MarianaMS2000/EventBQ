import 'package:flutter/material.dart';
import 'app.dart';
import 'preferences/preferencias_usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences debe estar listo antes de arrancar la app
  await PreferenciasUsuario.init();

  runApp(const EventBQApp());
}
