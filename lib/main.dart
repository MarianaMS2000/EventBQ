import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'preferences/preferencias_usuario.dart';
import 'repositories/usuario_repository.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // SharedPreferences debe estar listo antes de arrancar la app
  await PreferenciasUsuario.init();
  await UsuarioRepository().inicializar();
  await PushNotificationService().inicializar();

  runApp(const EventBQApp());
}
