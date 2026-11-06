import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones predeterminadas de Firebase para EventBQ.
///
/// Para generar las configuraciones de Android e iOS:
/// 1. Instala FlutterFire CLI: `dart pub global activate flutterfire_cli`
/// 2. Ejecuta: `flutterfire configure --project=eventobq-3a405`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están soportadas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC7CN1eF09dATOYGfGvFyHPcLiXM2NNNqk',
    appId: '1:9182276602:web:c59717f2754dbc8530d243',
    messagingSenderId: '9182276602',
    projectId: 'eventobq-3a405',
    authDomain: 'eventobq-3a405.firebaseapp.com',
    storageBucket: 'eventobq-3a405.firebasestorage.app',
    measurementId: 'G-VRN0CCX8KJ',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5uBWNkQiZJ47h_fe4WtBC1ObVFLZ6Zkc',
    appId: '1:9182276602:ios:43cdebab1e6955d530d243',
    messagingSenderId: '9182276602',
    projectId: 'eventobq-3a405',
    storageBucket: 'eventobq-3a405.firebasestorage.app',
    iosBundleId: 'com.example.helloWorld',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSjgvaIkMB9tln_Zi9MRS4_4ZykcMzrKk',
    appId: '1:9182276602:android:22c461ff63ea26cb30d243',
    messagingSenderId: '9182276602',
    projectId: 'eventobq-3a405',
    storageBucket: 'eventobq-3a405.firebasestorage.app',
  );
}
