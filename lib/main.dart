import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/push_notification_service.dart';
import 'core/session/auth_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.load();

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
