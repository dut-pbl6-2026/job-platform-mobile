import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_config.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A release build without `--dart-define=FLUTTER_API_URL=...` has no reachable
  // gateway: ApiConfig throws instead of falling back to localhost. Show that as
  // a configuration error and do not start the app.
  String? configurationError;
  try {
    ApiConfig.defaultBaseUrl;
  } on StateError catch (error) {
    configurationError = error.message;
  }
  if (configurationError != null) {
    runApp(_ConfigurationErrorApp(detail: configurationError));
    return;
  }

  // Lock orientation to portrait on mobile devices (per SRS 7.2.2 - Portrait primary)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Mount App widget tree immediately so UI renders without white screen delay
  runApp(const ProviderScope(child: App()));

  // Initialize Push Notification Service asynchronously in background (PUSH-01)
  unawaited(
    PushNotificationService.instance.initialize().catchError((e) {
      debugPrint('Push notification service initialization error: $e');
    }),
  );
}

/// Shown when the build is missing its gateway address. There is no usable app
/// behind it, so this replaces the whole widget tree instead of the splash.
class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp({required this.detail});

  /// The technical cause (`FLUTTER_API_URL` missing) for the release engineer.
  final String detail;

  static const title = 'Không kết nối được máy chủ';
  static const body =
      'Ứng dụng chưa được cấu hình địa chỉ máy chủ. '
      'Vui lòng cài đặt bản phát hành đúng hoặc liên hệ bộ phận hỗ trợ.';

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_ethernet, size: 48),
                const SizedBox(height: 16),
                const Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(body, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
