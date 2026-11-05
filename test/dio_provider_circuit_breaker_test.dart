import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/network/gateway_circuit_breaker.dart';

void main() {
  group('DioProvider Circuit Breaker Interceptor Integration', () {
    late Dio dio;
    late GatewayCircuitBreaker breaker;

    setUp(() {
      breaker = GatewayCircuitBreaker(cooldown: const Duration(seconds: 30));
      GatewayCircuitBreaker.instance = breaker;

      dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:5000',
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      // Add Circuit Breaker interceptor matching DioProvider
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final isBypass = options.extra['bypass_circuit_breaker'] == true;
            if (!isBypass && !GatewayCircuitBreaker.instance.canExecute()) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: const GatewayCircuitBreakerException(
                    'Gateway is offline (Circuit Breaker OPEN). Fast-failing network call.',
                  ),
                ),
              );
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            GatewayCircuitBreaker.instance.recordSuccess();
            return handler.next(response);
          },
          onError: (err, handler) {
            if (GatewayCircuitBreaker.instance.isGatewayConnectionFailure(
              err,
            )) {
              GatewayCircuitBreaker.instance.recordFailure();
            } else if (err.response != null) {
              GatewayCircuitBreaker.instance.recordSuccess();
            } else if (err.type == DioExceptionType.cancel) {
              GatewayCircuitBreaker.instance.recordProbeAborted();
            }
            return handler.next(err);
          },
        ),
      );
    });

    tearDown(() {
      GatewayCircuitBreaker.instance.reset();
    });

    test(
      'When circuit is OPEN, Dio rejects request immediately without network call',
      () async {
        // Simulate that gateway went offline
        breaker.recordFailure();
        expect(breaker.isOpen, isTrue);

        final stopwatch = Stopwatch()..start();
        try {
          await dio.get('/api/jobs');
          fail('Should have thrown DioException');
        } on DioException catch (e) {
          stopwatch.stop();
          expect(e.type, DioExceptionType.connectionError);
          expect(e.error, isA<GatewayCircuitBreakerException>());
          // Must reject in less than 50 milliseconds (0ms network delay)
          expect(stopwatch.elapsedMilliseconds, lessThan(50));
        }
      },
    );

    test(
      'When circuit is manually reset, requests are allowed to proceed',
      () async {
        breaker.recordFailure();
        expect(breaker.isOpen, isTrue);

        // Pull-to-refresh reset
        breaker.reset();
        expect(breaker.state, CircuitState.closed);

        // Add mock adapter that simulates successful 200 response
        dio.httpClientAdapter = _MockSuccessAdapter();

        final res = await dio.get('/api/jobs');
        expect(res.statusCode, 200);
        expect(breaker.state, CircuitState.closed);
      },
    );

    test('HTTP 401 response does not open circuit breaker', () async {
      dio.httpClientAdapter = _MockErrorAdapter(401);

      try {
        await dio.get('/api/jobs');
      } on DioException {
        // Ignored
      }

      expect(breaker.state, CircuitState.closed);
    });

    test('HTTP 500 response does not open circuit breaker', () async {
      dio.httpClientAdapter = _MockErrorAdapter(500);

      try {
        await dio.get('/api/jobs');
      } on DioException {
        // Ignored
      }

      expect(breaker.state, CircuitState.closed);
    });
  });
}

class _MockSuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"items": []}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockErrorAdapter implements HttpClientAdapter {
  final int statusCode;
  _MockErrorAdapter(this.statusCode);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error": "Simulated"}',
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
