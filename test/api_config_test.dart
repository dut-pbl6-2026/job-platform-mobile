import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/config/mock_fallback.dart';
import 'package:job_platform_mobile/core/network/api_config.dart';

void main() {
  group('ApiConfig gateway address', () {
    test('a release build without FLUTTER_API_URL fails at startup', () {
      // `assert` is stripped in release, so the guard has to be real code: the
      // app must not silently point a store build at localhost.
      expect(
        () =>
            ApiConfig.resolveBaseUrl(envOverride: '', isReleaseOverride: true),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('FLUTTER_API_URL'),
          ),
        ),
      );
    });

    test('a whitespace-only override counts as missing in release', () {
      expect(
        () => ApiConfig.resolveBaseUrl(
          envOverride: '   ',
          isReleaseOverride: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a release build uses the given FLUTTER_API_URL', () {
      expect(
        ApiConfig.resolveBaseUrl(
          envOverride: ' https://api.example.com ',
          isReleaseOverride: true,
        ),
        'https://api.example.com',
      );
    });

    test('debug builds keep the local emulator defaults', () {
      expect(
        ApiConfig.resolveBaseUrl(
          envOverride: '',
          isReleaseOverride: false,
          isWebOverride: false,
          platformOverride: TargetPlatform.android,
        ),
        'http://10.0.2.2:5000',
      );
      expect(
        ApiConfig.resolveBaseUrl(
          envOverride: '',
          isReleaseOverride: false,
          isWebOverride: false,
          platformOverride: TargetPlatform.iOS,
        ),
        'http://127.0.0.1:5000',
      );
      expect(
        ApiConfig.resolveBaseUrl(
          envOverride: '',
          isReleaseOverride: false,
          isWebOverride: true,
        ),
        'http://127.0.0.1:5000',
      );
    });
  });

  group('mock fallback gate', () {
    test('is off by default and never on for a 4xx', () {
      // The default `ENABLE_MOCKS` build value is false, so a plain run cannot
      // fabricate data. The per-call helper is covered here for the rules.
      expect(shouldUseMockFallback(enabled: false, statusCode: null), isFalse);
      expect(shouldUseMockFallback(enabled: false, statusCode: 500), isFalse);
    });

    test('allows transport and 5xx failures only when enabled', () {
      expect(shouldUseMockFallback(enabled: true, statusCode: null), isTrue);
      expect(shouldUseMockFallback(enabled: true, statusCode: 500), isTrue);
      expect(shouldUseMockFallback(enabled: true, statusCode: 599), isTrue);
      expect(shouldUseMockFallback(enabled: true, statusCode: 400), isFalse);
      expect(shouldUseMockFallback(enabled: true, statusCode: 401), isFalse);
      expect(shouldUseMockFallback(enabled: true, statusCode: 403), isFalse);
      expect(shouldUseMockFallback(enabled: true, statusCode: 404), isFalse);
      expect(shouldUseMockFallback(enabled: true, statusCode: 422), isFalse);
    });
  });
}
