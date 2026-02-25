import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
  }

  bool _isInitialized = false;
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android Notification Channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> _addAuthHeader() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _dio.options.headers['Accept'] = 'application/json';
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request FCM permission for iOS/Android 13+
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted FCM permission');
        }
      }

      // 2. Initialize Flutter Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
          if (kDebugMode) {
            print('Notification tapped: ${details.payload}');
          }
        },
      );

      // 3. Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // 4. Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // Show local notification if it contains a notification object
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android.smallIcon,
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // 6. Handle message open app from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
        }
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during NotificationService initialization: $e');
      }
      _isInitialized = false;
    }
  }

  Future<String?> getToken() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('getToken called but NotificationService not initialized');
      }
      return null;
    }
    try {
      String? token = await _fcm.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      await _addAuthHeader();
      if (kDebugMode) {
        print('Fetching notifications...');
      }
      final response = await _dio.get(ApiConfig.notifications);
      if (response.statusCode == 200) {
        final dynamic respData = response.data;
        if (respData is Map && respData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(respData['data']);
        }
        return List<Map<String, dynamic>>.from(respData ?? []);
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching notifications: $e');
      }
      return [];
    }
  }

  Future<bool> markAsRead({String? id}) async {
    try {
      await _addAuthHeader();
      if (kDebugMode) {
        print('Marking notification as read...');
      }
      final response = await _dio.post(
        ApiConfig.markNotificationsAsRead,
        data: id != null ? {'id': id} : {},
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      return false;
    }
  }
}

// Global background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}
