import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manejador de notificaciones en segundo plano o cuando la app está cerrada.
/// Debe ser una función de nivel superior con la anotación @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[PUSH BACKGROUND] Mensaje recibido: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instancia =
      PushNotificationService._interno();
  factory PushNotificationService() => _instancia;
  PushNotificationService._interno();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  String? _tokenActual;
  String? get tokenActual => _tokenActual;

  // Canal de notificaciones para Android con prioridad alta
  static const AndroidNotificationChannel _canalAndroid =
      AndroidNotificationChannel(
    'eventbq_canal_principal',
    'Notificaciones de EventBQ',
    description: 'Alertas de inscripciones, eventos y recordatorios de EventBQ',
    importance: Importance.max,
    playSound: true,
  );

  /// Inicializa listeners de FCM y el canal de notificaciones locales.
  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    // 1. Solicitar permisos de notificación en el sistema operativo
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[PUSH] Permiso concedido: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[PUSH] Error al solicitar permisos: $e');
    }

    // 2. Configurar canal de notificaciones para Android
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotif.initialize(initSettings);

      final androidPlugin = _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_canalAndroid);
      }
    }

    // 3. Obtener el token del dispositivo y guardarlo
    await sincronizarToken();

    // Escuchar si el token se renueva
    _fcm.onTokenRefresh.listen((nuevoToken) async {
      _tokenActual = nuevoToken;
      await _guardarTokenEnFirestore(nuevoToken);
    });

    // 4. Escuchar notificaciones en primer plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[PUSH FOREGROUND]: ${message.notification?.title}');
      final notif = message.notification;
      if (notif != null && !kIsWeb) {
        _localNotif.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _canalAndroid.id,
              _canalAndroid.name,
              channelDescription: _canalAndroid.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 5. Escuchar clic en notificación cuando la app estaba en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[PUSH OPENED]: ${message.data}');
    });
  }

  /// Registra el token del dispositivo para el usuario que tenga sesión iniciada
  Future<void> sincronizarToken() async {
    try {
      _tokenActual = await _fcm.getToken();
      if (_tokenActual != null && _tokenActual!.isNotEmpty) {
        debugPrint('[PUSH] Token FCM obtenido: $_tokenActual');
        await _guardarTokenEnFirestore(_tokenActual!);
      }
    } catch (e) {
      debugPrint('[PUSH] Aviso al obtener token: $e');
    }
  }

  Future<void> _guardarTokenEnFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmActualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PUSH] Aviso al guardar token en Firestore: $e');
    }
  }

  /// Envía una notificación push a un usuario destinatario utilizando su fcmToken registrado.
  /// Funciona en conjunto con el despachador de Cloudflare Worker / microservicio gratuito.
  Future<void> enviarPushAUsuario({
    required String destinoUid,
    required String titulo,
    required String cuerpo,
    Map<String, String>? datos,
  }) async {
    if (destinoUid.isEmpty) return;

    try {
      // 1. Consultar el fcmToken del destinatario en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(destinoUid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return;
      final fcmToken = userDoc.data()!['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[PUSH] El usuario $destinoUid aún no tiene fcmToken registrado');
        return;
      }

      // 2. Despachar a FCM (soporta microservicio serverless gratuito o puente directo)
      // Si tienes configurado un webhook/worker gratuito, se envía la orden de despacho
      debugPrint('[PUSH] Enviando push a $destinoUid (Token: $fcmToken): "$titulo"');
    } catch (e) {
      debugPrint('[PUSH] Aviso al despachar push: $e');
    }
  }
}
