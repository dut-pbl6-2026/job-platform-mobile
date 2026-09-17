import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/hive_cache_service.dart';
import 'core/session/auth_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load session safely without blocking app render
  try {
    await AuthSession.instance.load();
  } catch (e) {
    debugPrint('[Main] AuthSession load error: $e');
  }

  // Initialize Hive offline cache asynchronously (OFFLINE-01)
  unawaited(
    HiveCacheService.instance.init().catchError((e) {
      debugPrint('[Main] Hive initialization error: $e');
    }),
  );

  // Lock orientation to portrait on mobile devices (per SRS 7.2.2)
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(const ProviderScope(child: App()));
}
