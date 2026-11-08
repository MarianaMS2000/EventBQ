import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import '../config/fcm_credentials.dart';

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

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  /// Obtiene o renueva el OAuth2 Access Token de Google para FCM v1
  /// Es 100% multiplataforma: funciona tanto en Flutter Web (localhost) como en Android e iOS.
  Future<String?> _obtenerAccessTokenGoogle() async {
    final now = DateTime.now().toUtc();
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final clientEmail = fcmServiceAccountCredentials['client_email'] as String?;
      final privateKeyStr = fcmServiceAccountCredentials['private_key'] as String?;
      if (clientEmail == null || privateKeyStr == null) return null;

      final jwt = JWT(
        {
          'iss': clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'exp': now.add(const Duration(minutes: 55)).millisecondsSinceEpoch ~/ 1000,
          'iat': now.millisecondsSinceEpoch ~/ 1000,
        },
      );

      final pemKey = RSAPrivateKey(privateKeyStr);
      final tokenSigned = jwt.sign(pemKey, algorithm: JWTAlgorithm.RS256);

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': tokenSigned,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = now.add(Duration(seconds: expiresIn - 120));
        return _cachedAccessToken;
      } else {
        debugPrint('[PUSH ERROR] Error al obtener OAuth2 de Google: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[PUSH EXCEPCION] Error al generar JWT para Google: $e');
      return null;
    }
  }

  /// Despacha un mensaje a la API v1 de FCM usando la cuenta de servicio oficial
  Future<void> enviarPushDirecto({
    required String fcmToken,
    required String titulo,
    required String cuerpo,
    Map<String, String>? datos,
  }) async {
    try {
      final accessToken = await _obtenerAccessTokenGoogle();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('[PUSH ERROR] No se pudo obtener Access Token de Google para FCM');
        return;
      }

      final projectId = fcmServiceAccountCredentials['project_id'] ?? 'eventobq-3a405';
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': titulo,
            'body': cuerpo,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': _canalAndroid.id,
              'sound': 'default',
              'default_sound': true,
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_MAX',
            },
          },
          if (datos != null && datos.isNotEmpty) 'data': datos,
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('[PUSH EXITOSO] Entregado a FCM para token $fcmToken: "$titulo"');
      } else {
        debugPrint('[PUSH ERROR] FCM HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[PUSH EXCEPCION] Error al enviar a FCM: $e');
    }
  }

  /// Envía una notificación push a un usuario destinatario utilizando su fcmToken registrado.
  /// Funciona en segundo plano y con la app completamente cerrada en el Plan Spark ($0).
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

      // 2. Despachar a la API v1 de FCM
      await enviarPushDirecto(
        fcmToken: fcmToken,
        titulo: titulo,
        cuerpo: cuerpo,
        datos: datos,
      );
    } catch (e) {
      debugPrint('[PUSH] Aviso al despachar push: $e');
    }
  }
}
