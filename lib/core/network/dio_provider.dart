import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';

const _baseUrl = String.fromEnvironment(
  'FLUTTER_API_URL',
  defaultValue: 'https://jp-gateway.onrender.com',
);

/// Singleton Dio with Queued AuthInterceptor (401 → refresh → retry, concurrency-safe).
class DioProvider {
  DioProvider._();
  static final DioProvider _instance = DioProvider._();
  static DioProvider get instance => _instance;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

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
            } catch (_) {}
            return handler.next(err);
          }

          _isRefreshing = true;
          _refreshCompleter = Completer<void>();
          try {
            final res = await Dio(
              BaseOptions(baseUrl: _baseUrl),
            ).post('/api/auth/refresh', data: {'refreshToken': refreshToken});
            final auth = AuthResult.fromJson(res.data as Map<String, dynamic>);
            await AuthSession.instance.setSession(auth);
            _refreshCompleter?.complete();
            // Retry original with new token
            err.requestOptions.headers['Authorization'] =
                'Bearer ${auth.token}';
            final retry = await d.fetch(err.requestOptions);
            return handler.resolve(retry);
          } catch (e) {
            _refreshCompleter?.completeError(e);
            await AuthSession.instance.clearSession();
            return handler.next(err);
          } finally {
            _isRefreshing = false;
            _refreshCompleter = null;
          }
        },
      ),
    );

    return d;
  }

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;
}

/// Riverpod provider for DI/testing overrides (P1 Arch 4)
final dioProvider = Provider<Dio>((ref) => DioProvider.instance.dio);
