import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

// Arka planda gelen mesajları dinlemek için top-level fonksiyon
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Arka planda mesaj alındı: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    // Arka plan dinleyicisini ayarla
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // İzin iste
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi.');
    } else {
      debugPrint('Kullanıcı bildirim iznini reddetti veya ayarlanmadı.');
    }

    // Yerel bildirimleri yapılandır (Ön plandayken göstermek için)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Ön plandayken gelen mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Ön planda mesaj alındı: ${message.messageId}');
      _showLocalNotification(message);
    });

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlemler
    debugPrint("Bildirime tıklandı: ${response.payload}");
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'motoconnect_high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Bu kanal MotoConnect bildirimleri için kullanılır.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    } else if (notification != null && Platform.isIOS) {
       await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Kullanıcının FCM Token'ını alır ve Firestore'a kaydeder.
  Future<void> saveTokenToDatabase(String userId) async {
    if (kIsWeb) return;
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirestoreService().updateUserToken(userId, token);
      }
      
      // Token yenilenirse veritabanını da güncelle
      _fcm.onTokenRefresh.listen((newToken) {
        FirestoreService().updateUserToken(userId, newToken);
      });
    } catch (e) {
      debugPrint("FCM Token alınırken hata: $e");
    }
  }

  Future<void> deleteToken() async {
    if (kIsWeb) return;
    try {
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint("FCM Token silinirken hata: $e");
    }
  }
}
