import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/network/api_config.dart';
import 'package:job_platform_mobile/core/network/gateway_circuit_breaker.dart';

void main() {
  group('ApiConfig Cross-Platform URL Resolution Tests', () {
    test('Default URL on Web is 127.0.0.1:5000', () {
      final url = ApiConfig.resolveBaseUrl(
        envOverride: '',
        isWebOverride: true,
      );
      expect(url, 'http://127.0.0.1:5000');
    });

    test('Default URL on Android Emulator is 10.0.2.2:5000', () {
      final url = ApiConfig.resolveBaseUrl(
        envOverride: '',
        isWebOverride: false,
        platformOverride: TargetPlatform.android,
      );
      expect(url, 'http://10.0.2.2:5000');
    });

    test('Default URL on Windows is 127.0.0.1:5000', () {
      final url = ApiConfig.resolveBaseUrl(
        envOverride: '',
        isWebOverride: false,
        platformOverride: TargetPlatform.windows,
      );
      expect(url, 'http://127.0.0.1:5000');
    });

    test('Default URL on iOS is 127.0.0.1:5000', () {
      final url = ApiConfig.resolveBaseUrl(
        envOverride: '',
        isWebOverride: false,
        platformOverride: TargetPlatform.iOS,
      );
      expect(url, 'http://127.0.0.1:5000');
    });

    test('FLUTTER_API_URL environment override takes highest priority', () {
      const customLanIp = 'http://192.168.1.100:5000';
      final url = ApiConfig.resolveBaseUrl(
        envOverride: customLanIp,
        isWebOverride: false,
        platformOverride: TargetPlatform.android,
      );
      expect(url, customLanIp);
    });
  });

  group('GatewayCircuitBreaker State & Transition Tests', () {
    late GatewayCircuitBreaker breaker;
    late DateTime simulatedTime;

    setUp(() {
      simulatedTime = DateTime(2026, 11, 5, 10, 0, 0);
      breaker = GatewayCircuitBreaker(
        cooldown: const Duration(seconds: 30),
        clock: () => simulatedTime,
      );
    });

    test('Initial state is CLOSED and allows requests', () {
      expect(breaker.state, CircuitState.closed);
      expect(breaker.canExecute(), isTrue);
      expect(breaker.isOpen, isFalse);
    });

    test('Transitions CLOSED -> OPEN on connection failure', () {
      breaker.recordFailure();

      expect(breaker.state, CircuitState.open);
      expect(breaker.isOpen, isTrue);
      expect(breaker.canExecute(), isFalse);
      expect(breaker.lastFailureTime, simulatedTime);
    });

    test('Fast-fails requests while OPEN during cooldown period', () {
      breaker.recordFailure();

      // Advance time by 15 seconds (within 30s cooldown)
      simulatedTime = simulatedTime.add(const Duration(seconds: 15));

      expect(breaker.state, CircuitState.open);
      expect(breaker.canExecute(), isFalse);
    });

    test('Transitions OPEN -> HALF_OPEN after 30s cooldown expires', () {
      breaker.recordFailure();

      // Advance time by 31 seconds (cooldown expired)
      simulatedTime = simulatedTime.add(const Duration(seconds: 31));

      expect(breaker.state, CircuitState.halfOpen);
    });

    test(
      'HALF_OPEN allows exactly ONE probe and rejects concurrent requests',
      () {
        breaker.recordFailure();
        simulatedTime = simulatedTime.add(const Duration(seconds: 30));

        // First request is allowed as the probe
        expect(breaker.canExecute(), isTrue);

        // Concurrent second and third requests must fast-fail without probe spam
        expect(breaker.canExecute(), isFalse);
        expect(breaker.canExecute(), isFalse);
      },
    );

    test('HALF_OPEN probe success transitions to CLOSED and resets state', () {
      breaker.recordFailure();
      simulatedTime = simulatedTime.add(const Duration(seconds: 30));

      // Probe is allowed
      expect(breaker.canExecute(), isTrue);

      // Probe succeeds
      breaker.recordSuccess();

      expect(breaker.state, CircuitState.closed);
      expect(breaker.lastFailureTime, isNull);
      expect(breaker.canExecute(), isTrue);
    });

    test(
      'HALF_OPEN probe failure transitions back to OPEN with new cooldown',
      () {
        breaker.recordFailure();
        simulatedTime = simulatedTime.add(const Duration(seconds: 30));

        // Probe is allowed
        expect(breaker.canExecute(), isTrue);

        // Probe fails
        breaker.recordFailure();

        expect(breaker.state, CircuitState.open);
        expect(breaker.canExecute(), isFalse);

        // New 30s cooldown begins from failure time
        simulatedTime = simulatedTime.add(const Duration(seconds: 15));
        expect(breaker.canExecute(), isFalse);

        simulatedTime = simulatedTime.add(const Duration(seconds: 16));
        expect(breaker.canExecute(), isTrue); // Next probe allowed
      },
    );

    test(
      'Manual reset on Pull-to-refresh transitions OPEN -> CLOSED immediately',
      () {
        breaker.recordFailure();
        expect(breaker.state, CircuitState.open);
        expect(breaker.canExecute(), isFalse);

        // User pulls to refresh
        breaker.reset();

        expect(breaker.state, CircuitState.closed);
        expect(breaker.canExecute(), isTrue);
        expect(breaker.lastFailureTime, isNull);
      },
    );

    test('Aborted/cancelled probe releases probing lock in HALF_OPEN', () {
      breaker.recordFailure();
      simulatedTime = simulatedTime.add(const Duration(seconds: 30));

      // Probe starts
      expect(breaker.canExecute(), isTrue);
      // Concurrent blocked
      expect(breaker.canExecute(), isFalse);

      // Probe request is cancelled
      breaker.recordProbeAborted();

      // Another probe can now be attempted
      expect(breaker.canExecute(), isTrue);
    });
  });

  group('GatewayCircuitBreaker Failure Classification Tests', () {
    late GatewayCircuitBreaker breaker;

    setUp(() {
      breaker = GatewayCircuitBreaker();
    });

    test('connectionTimeout trips the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(breaker.isGatewayConnectionFailure(err), isTrue);
    });

    test('connectionError (refused/unreachable) trips the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.connectionError,
      );
      expect(breaker.isGatewayConnectionFailure(err), isTrue);
    });

    test('HTTP 400 Bad Request does NOT trip the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/jobs'),
          statusCode: 400,
        ),
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });

    test('HTTP 401 Unauthorized does NOT trip the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/jobs'),
          statusCode: 401,
        ),
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });

    test('HTTP 403 Forbidden does NOT trip the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/jobs'),
          statusCode: 403,
        ),
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });

    test('HTTP 404 Not Found does NOT trip the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/jobs'),
          statusCode: 404,
        ),
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });

    test(
      'HTTP 500 Internal Server Error does NOT trip the circuit breaker',
      () {
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/jobs'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/jobs'),
            statusCode: 500,
          ),
        );
        expect(breaker.isGatewayConnectionFailure(err), isFalse);
      },
    );

    test('Client-side cancel does NOT trip the circuit breaker', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.cancel,
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });

    test('Circuit breaker fast-fail exception does not re-trip', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/jobs'),
        type: DioExceptionType.connectionError,
        error: const GatewayCircuitBreakerException('Already open'),
      );
      expect(breaker.isGatewayConnectionFailure(err), isFalse);
    });
  });
}
