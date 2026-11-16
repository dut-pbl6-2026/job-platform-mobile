import 'package:flutter/foundation.dart';

/// Centralized Cross-Platform API Gateway Configuration.
/// Respects environmental overrides (--dart-define=FLUTTER_API_URL=...)
/// and provides intelligent platform-aware defaults without any `dart:io` dependencies.
class ApiConfig {
  ApiConfig._();

  /// Environmental override passed via `--dart-define=FLUTTER_API_URL=...`
  static const String envApiUrl = String.fromEnvironment('FLUTTER_API_URL');

  /// Resolves the Gateway Base URL dynamically across platforms.
  /// Priority order:
  /// 1. [envOverride] or `FLUTTER_API_URL` (passed via --dart-define)
  /// 2. Release build with no override -> throws; a shipped build must never
  ///    silently point at localhost.
  /// 3. Flutter Web (kIsWeb) -> http://127.0.0.1:5000
  /// 4. Desktop (Windows, macOS, Linux) or iOS -> http://127.0.0.1:5000
  /// 5. Android Emulator (TargetPlatform.android) -> http://10.0.2.2:5000
  static String resolveBaseUrl({
    String? envOverride,
    bool? isWebOverride,
    TargetPlatform? platformOverride,
    bool? isReleaseOverride,
  }) {
    final env = (envOverride ?? envApiUrl).trim();
    if (env.isNotEmpty) {
      return env;
    }

    // `assert` is stripped in release, so this is a real guard: a release build
    // without FLUTTER_API_URL has no reachable gateway (Android 9+ also blocks
    // the cleartext localhost fallback). Fail at startup with a message an
    // engineer can act on instead of shipping a client that cannot connect.
    if (isReleaseOverride ?? kReleaseMode) {
      throw StateError(
        'FLUTTER_API_URL is required in a release build. '
        'Pass --dart-define=FLUTTER_API_URL=https://<gateway-host>.',
      );
    }

    final isWeb = isWebOverride ?? kIsWeb;
    if (isWeb) {
      return 'http://127.0.0.1:5000';
    }

    final platform = platformOverride ?? defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:5000';
    }
  }

  /// Default active Base URL for the current platform/environment.
  ///
  /// Throws [StateError] in a release build without `FLUTTER_API_URL`; [main]
  /// turns that into a visible configuration error.
  static String get defaultBaseUrl => resolveBaseUrl();
}
