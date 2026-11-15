import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';

import 'api_config.dart';
import 'gateway_circuit_breaker.dart';

/// Singleton Dio with:
/// 1. Platform-aware Gateway base URL ([ApiConfig.defaultBaseUrl])
/// 2. SLA-compliant timeouts (connect: 3s, receive: 5s, send: 5s)
/// 3. Gateway Circuit Breaker (CLOSED / OPEN / HALF_OPEN with fast-fail)
/// 4. Queued AuthInterceptor (401 -> refresh -> retry, concurrency-safe).
///    Only a rejected refresh (401/403) ends the session; 429 and transient failures keep it.
class DioProvider {
  DioProvider._();
  static final DioProvider _instance = DioProvider._();
  static DioProvider get instance => _instance;

  late final Dio dio = _createDio();

  /// Client used only for `/api/auth/refresh`, so the refresh bypasses the auth interceptor.
  late final Dio _refreshDio = Dio(_baseOptions());

  @visibleForTesting
  Dio get refreshDio => _refreshDio;

  BaseOptions _baseOptions() => BaseOptions(
    baseUrl: ApiConfig.defaultBaseUrl,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    headers: {'Content-Type': 'application/json'},
  );

  Dio _createDio() {
    final d = Dio(_baseOptions());

    // 1. Gateway Circuit Breaker Interceptor (Fast-fail when Gateway is offline)
    d.interceptors.add(
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
          if (GatewayCircuitBreaker.instance.isGatewayConnectionFailure(err)) {
            GatewayCircuitBreaker.instance.recordFailure();
          } else if (err.response != null) {
            // An HTTP error response (even 4xx/5xx) proves the Gateway/Service is reachable
            GatewayCircuitBreaker.instance.recordSuccess();
          } else if (err.type == DioExceptionType.sendTimeout ||
              err.type == DioExceptionType.receiveTimeout) {
            // In HALF_OPEN probe state, a timeout indicates the gateway probe failed
            if (GatewayCircuitBreaker.instance.state == CircuitState.halfOpen) {
              GatewayCircuitBreaker.instance.recordFailure();
            } else {
              GatewayCircuitBreaker.instance.recordProbeAborted();
            }
          } else {
            GatewayCircuitBreaker.instance.recordProbeAborted();
          }
          return handler.next(err);
        },
      ),
    );

    // 2. Queued Auth & Token Refresh Interceptor
    d.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          // Skip auth header for anonymous endpoints
          final path = options.path;
          final isAnonymous =
              path.contains('/api/auth/login') ||
              path.contains('/api/auth/register') ||
              path.contains('/api/auth/forgot-password') ||
              path.contains('/api/auth/reset-password') ||
              path.contains('/api/auth/refresh');
          if (!isAnonymous) {
            final token = AuthSession.instance.token;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final status = err.response?.statusCode;
          final isRefreshCall = err.requestOptions.path.contains(
            '/api/auth/refresh',
          );

          // Only handle 401 for non-refresh calls when we have a refresh token
          if (status != 401 || isRefreshCall) {
            return handler.next(err);
          }
          final refreshToken = AuthSession.instance.refreshToken;
          if (refreshToken == null) {
            return handler.next(err);
          }

          // If refresh already in progress, wait for it then retry with new token
          if (_isRefreshing) {
            try {
              await _refreshCompleter?.future;
              final newToken = AuthSession.instance.token;
              if (newToken != null) {
                err.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final retry = await d.fetch(err.requestOptions);
                return handler.resolve(retry);
              }
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            } catch (_) {
              return handler.next(err);
            }
            return handler.next(err);
          }

          _isRefreshing = true;
          _refreshCompleter = Completer<void>();
          // Waiters receive the error through the future; with none, it must not be reported as unhandled.
          _refreshCompleter!.future.catchError((Object _) {});
          late final AuthResult auth;
          try {
            final res = await _postRefresh(refreshToken);
            final data = res.data is Map<String, dynamic>
                ? res.data as Map<String, dynamic>
                : Map<String, dynamic>.from(res.data as Map);
            auth = AuthResult.fromJson(data);
            await AuthSession.instance.setSession(auth);
            _refreshCompleter?.complete();
          } catch (e) {
            if (!(_refreshCompleter?.isCompleted ?? true)) {
              _refreshCompleter?.completeError(e);
            }
            // Only a rejected refresh token (401/403) ends the session. A 429, a 5xx or a network
            // error keeps the tokens. The refresh error is passed on instead of the original 401,
            // so the caller does not treat it as a logout.
            if (_isRejectedRefresh(e)) {
              await AuthSession.instance.clearSession();
              return handler.next(err);
            }
            return handler.next(e is DioException ? e : err);
          } finally {
            _isRefreshing = false;
            _refreshCompleter = null;
          }

          // Retry original request with newly refreshed token
          try {
            err.requestOptions.headers['Authorization'] =
                'Bearer ${auth.token}';
            final retry = await d.fetch(err.requestOptions);
            return handler.resolve(retry);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          } catch (_) {
            return handler.next(err);
          }
        },
      ),
    );

    return d;
  }

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  static const _maxRefreshAttempts = 3;
  static const _maxRefreshBackoff = Duration(seconds: 5);

  /// POST /api/auth/refresh. A 429 is retried after a bounded backoff (Retry-After when sent). The
  /// per-IP rate limiter rejects the call before the token family is touched, so the refresh token
  /// is still valid for the next attempt.
  Future<Response<dynamic>> _postRefresh(String refreshToken) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _refreshDio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 429 || attempt >= _maxRefreshAttempts) {
          rethrow;
        }
        await Future<void>.delayed(_refreshBackoff(e.response, attempt));
      }
    }
  }

  static Duration _refreshBackoff(Response<dynamic>? response, int attempt) {
    final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
    final delay = seconds != null && seconds >= 0
        ? Duration(seconds: seconds)
        : Duration(seconds: 1 << (attempt - 1));
    return delay > _maxRefreshBackoff ? _maxRefreshBackoff : delay;
  }

  static bool _isRejectedRefresh(Object e) {
    if (e is! DioException) return false;
    final status = e.response?.statusCode;
    return status == 401 || status == 403;
  }
}

/// Riverpod provider for DI/testing overrides (P1 Arch 4)
final dioProvider = Provider<Dio>((ref) => DioProvider.instance.dio);
