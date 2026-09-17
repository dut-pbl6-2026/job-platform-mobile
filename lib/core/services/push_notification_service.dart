import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../router/app_router.dart';
import '../../features/notifications/data/repositories/api_notification_repository.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Background message Firebase init fallback: $e');
  }
  debugPrint('FCM background message received: ${message.messageId}');
}

/// Core service managing Firebase Cloud Messaging (FCM) push notifications (PUSH-01)
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  INotificationRepository _repository = ApiNotificationRepository();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final StreamController<AppNotification> _notificationStreamController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotificationReceived =>
      _notificationStreamController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'job_platform_high_importance',
    'Job Platform Notifications',
    description: 'Notifications for job alerts, application updates and interviews',
    importance: Importance.high,
  );

  /// Initializes Firebase and Push Notification handlers
  Future<void> initialize({
    INotificationRepository? repository,
    FirebaseMessaging? messagingOverride,
    FlutterLocalNotificationsPlugin? localNotificationsOverride,
  }) async {
    if (_isInitialized) return;
    if (repository != null) {
      _repository = repository;
    }

    try {
      // 1. Initialize Firebase Core if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _messaging = messagingOverride ?? FirebaseMessaging.instance;
      _localNotifications =
          localNotificationsOverride ?? FlutterLocalNotificationsPlugin();

      // 2. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions (especially required on iOS & Android 13+)
      final settings = await _messaging?.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint(
        'FCM notification authorization status: ${settings?.authorizationStatus}',
      );

      // 4. Setup Local Notifications for Foreground Presentation
      await _setupLocalNotifications();

      // 5. Setup message listeners
      _setupMessageListeners();

      // 6. Retrieve & register device token
      await _setupToken();

      _isInitialized = true;
      debugPrint('PushNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('PushNotificationService initialization error (gracefully handled): $e');
      _isInitialized = false;
    }
  }

  Future<void> _setupLocalNotifications() async {
    if (_localNotifications == null) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          handleNotificationNavigation({'route': payload});
        }
      },
    );

    // Create default channel on Android
    await _localNotifications
        ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground notification options for iOS
    await _messaging?.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupMessageListeners() {
    // A. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message received: ${message.messageId}');
      final notification = message.notification;
      final data = message.data;

      final appNotification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification?.title ?? data['title'] ?? 'Thông báo mới',
        body: notification?.body ?? data['body'] ?? '',
        type: NotificationType.fromString(data['type']),
        data: data,
        createdAt: DateTime.now(),
      );

      _notificationStreamController.add(appNotification);

      // Display heads-up banner via Local Notifications
      if (notification != null) {
        _showLocalNotification(notification, data);
      }
    });

    // B. App opened from background state via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via FCM notification: ${message.data}');
      handleNotificationNavigation(message.data);
    });

    // C. App opened from terminated state via notification tap
    _messaging?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from terminated state via FCM: ${message.data}');
        handleNotificationNavigation(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    final route = data['route'] ?? _resolveRoute(data);
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications?.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: route,
    );
  }

  Future<void> _setupToken() async {
    try {
      _fcmToken = await _messaging?.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token obtained: $_fcmToken');
        await syncTokenWithBackend();
      }

      // Listen for token updates
      _messaging?.onTokenRefresh.listen((String newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        await syncTokenWithBackend();
      });
    } catch (e) {
      debugPrint('Failed to retrieve FCM token: $e');
    }
  }

  /// Syncs current FCM token to API Gateway
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken == null) return;
    final platform = kIsWeb
        ? 'web'
        : (Platform.isAndroid
            ? 'android'
            : (Platform.isIOS ? 'ios' : 'desktop'));

    try {
      await _repository.registerDeviceToken(
        token: _fcmToken!,
        platform: platform,
      );
    } catch (e) {
      debugPrint('Failed to sync FCM token with API Gateway: $e');
    }
  }

  /// Unregisters FCM token from backend on logout
  Future<void> unregisterTokenOnLogout() async {
    if (_fcmToken != null) {
      try {
        await _repository.unregisterDeviceToken(_fcmToken!);
      } catch (e) {
        debugPrint('Failed to unregister FCM token: $e');
      }
    }
  }

  /// Resolves route path from notification payload data
  String _resolveRoute(Map<String, dynamic> data) {
    if (data['route'] != null && data['route'].toString().isNotEmpty) {
      return data['route'].toString();
    }
    final jobId = data['job_id'] ?? data['jobId'];
    if (jobId != null) {
      return '/jobs/$jobId';
    }
    final applicationId = data['application_id'] ?? data['applicationId'];
    if (applicationId != null) {
      return '/applications/$applicationId';
    }
    return AppRoutes.notifications;
  }

  /// Navigates user to target screen based on notification payload
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final route = _resolveRoute(data);
    debugPrint('Navigating to notification route: $route');
    try {
      AppRouter.router.push(route);
    } catch (e) {
      debugPrint('Navigation error from notification: $e');
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
