import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../router/app_router.dart';
import '../session/auth_session.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/notifications/data/repositories/api_notification_repository.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Background message Firebase init fallback: $e');
    }
  }
  if (kDebugMode) {
    debugPrint('FCM background message received: ${message.messageId}');
  }
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
  String? _pendingRoute;

  static const List<String> _allowedRoutePrefixes = [
    '/home',
    '/jobs',
    '/search',
    '/applications',
    '/profile',
    '/my-join-request',
    '/recruiter/dashboard',
    '/recruiter/jobs',
    '/recruiter/candidates',
    '/recruiter/company',
    '/recruiter/invite-codes',
    '/recruiter/join-requests',
  ];

  final StreamController<AppNotification> _notificationStreamController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotificationReceived =>
      _notificationStreamController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'job_platform_high_importance',
    'Job Platform Notifications',
    description:
        'Notifications for job alerts, application updates and interviews',
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

    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile && messagingOverride == null) {
      if (kDebugMode) {
        debugPrint(
          'Push notifications are supported on Mobile platforms (Android/iOS). '
          'Skipping on ${kIsWeb ? 'web' : defaultTargetPlatform.name}.',
        );
      }
      return;
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
      if (kDebugMode) {
        debugPrint(
          'FCM notification authorization status: ${settings?.authorizationStatus}',
        );
      }

      // 4. Setup Local Notifications for Foreground Presentation
      await _setupLocalNotifications();

      // 5. Setup message listeners
      _setupMessageListeners();

      // 6. Retrieve & register device token
      await _setupToken();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('PushNotificationService initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService initialization error (gracefully handled): $e',
        );
      }
      _isInitialized = false;
    }
  }

  Future<void> _setupLocalNotifications() async {
    if (_localNotifications == null) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
          AndroidFlutterLocalNotificationsPlugin
        >()
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
      if (kDebugMode) {
        debugPrint('FCM foreground message received: ${message.messageId}');
      }
      final notification = message.notification;
      final data = message.data;

      final appNotification = AppNotification(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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
      if (kDebugMode) {
        debugPrint('App opened via FCM notification: ${message.messageId}');
      }
      handleNotificationNavigation(message.data);
    });

    // C. App opened from terminated state via notification tap
    _messaging?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          debugPrint(
            'App launched from terminated state via FCM: ${message.messageId}',
          );
        }
        handleNotificationNavigation(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    final route = resolveNotificationRoute(
      data,
      role: AuthSession.instance.resolvedRole,
    );
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
        if (kDebugMode) {
          debugPrint('FCM token obtained (len=${_fcmToken!.length}).');
        }
        await syncTokenWithBackend();
      }

      // Listen for token updates (never log raw token in release — SEC-03)
      _messaging?.onTokenRefresh.listen((String newToken) async {
        if (kDebugMode) {
          debugPrint('FCM token refreshed (len=${newToken.length}).');
        }
        _fcmToken = newToken;
        await syncTokenWithBackend();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to retrieve FCM token: $e');
      }
    }
  }

  /// Syncs current FCM token to API Gateway when authenticated (PUSH-01-02)
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken == null || !AuthSession.instance.isAuthenticated) return;
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : (defaultTargetPlatform == TargetPlatform.iOS
                    ? 'ios'
                    : defaultTargetPlatform.name));

    try {
      await _repository.registerDeviceToken(
        token: _fcmToken!,
        platform: platform,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to sync FCM token with API Gateway: $e');
      }
    }
  }

  /// Unregisters FCM token from backend on logout
  Future<void> unregisterTokenOnLogout() async {
    if (_fcmToken != null) {
      try {
        await _repository.unregisterDeviceToken(_fcmToken!);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to unregister FCM token: $e');
        }
      }
    }
  }

  /// Consumes any cold-start notification route queued before session load finished.
  String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  /// Resolves and sanitizes route path from notification payload data (PUSH-01-06, SEC-05).
  @visibleForTesting
  static String resolveNotificationRoute(
    Map<String, dynamic> data, {
    UserRole? role,
  }) {
    final rawRoute =
        (data['route'] ?? data['deepLink'] ?? data['deep_link'] ?? data['link'])
            ?.toString()
            .trim();

    if (rawRoute != null && rawRoute.isNotEmpty) {
      final fromScheme = _parseCustomSchemeRoute(rawRoute, role: role);
      if (fromScheme != null) return fromScheme;

      if (_isSafeInternalRoute(rawRoute)) {
        if (role == UserRole.recruiter &&
            rawRoute.startsWith('/applications')) {
          return AppRoutes.recruiterCandidates;
        }
        return rawRoute;
      }
    }

    final jobId = _sanitizeSegment(data['job_id'] ?? data['jobId']);
    final applicationId = _sanitizeSegment(
      data['application_id'] ?? data['applicationId'] ?? data['appId'],
    );

    if (role == UserRole.recruiter) {
      if (applicationId != null || data['type'] == 'new_application') {
        return jobId != null
            ? '${AppRoutes.recruiterCandidates}?jobId=$jobId'
            : AppRoutes.recruiterCandidates;
      }
    }

    if (jobId != null && applicationId == null) {
      return '/jobs/$jobId';
    }
    if (applicationId != null) {
      return '/applications/$applicationId';
    }
    return AppRoutes.home;
  }

  static String? _parseCustomSchemeRoute(String raw, {UserRole? role}) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.toLowerCase() != 'job') return null;
    final host = uri.host.toLowerCase();
    final firstSeg = uri.pathSegments.isNotEmpty
        ? _sanitizeSegment(uri.pathSegments.first)
        : null;

    if ((host == 'job' || host == 'jobs') && firstSeg != null) {
      return '/jobs/$firstSeg';
    }
    if ((host == 'application' || host == 'applications') && firstSeg != null) {
      if (role == UserRole.recruiter) {
        return AppRoutes.recruiterCandidates;
      }
      return '/applications/$firstSeg';
    }
    return null;
  }

  static bool _isSafeInternalRoute(String route) {
    if (!route.startsWith('/') || route.startsWith('//')) return false;
    final uri = Uri.tryParse(route);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
    final path = uri.path;
    if (path.contains('..')) return false;
    return _allowedRoutePrefixes.any(
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    );
  }

  static String? _sanitizeSegment(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.contains('/') || text.contains('..')) return null;
    return Uri.encodeComponent(text);
  }

  /// Navigates user to target screen based on notification payload
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final route = resolveNotificationRoute(
      data,
      role: AuthSession.instance.resolvedRole,
    );
    if (!AuthSession.instance.isLoaded) {
      _pendingRoute = route;
      return;
    }
    if (kDebugMode) {
      debugPrint('Navigating to notification route: $route');
    }
    try {
      AppRouter.router.push(route);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Navigation error from notification: $e');
      }
    }
  }

  void dispose() {
    _notificationStreamController.close();
  }
}
