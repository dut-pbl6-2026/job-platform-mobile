import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/auth_session.dart';
import '../../features/auth/domain/models/auth_result.dart';

const _baseUrl = String.fromEnvironment('FLUTTER_API_URL', defaultValue: 'https://jp-gateway.onrender.com');

/// Singleton Dio with AuthInterceptor (401 → refresh → retry).
class DioProvider {
  DioProvider._();
  static final DioProvider _instance = DioProvider._();
  static DioProvider get instance => _instance;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final d = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Skip auth header for anonymous endpoints
        final path = options.path;
        final isAnonymous = path.contains('/api/auth/login') ||
            path.contains('/api/auth/register') ||
            path.contains('/api/auth/forgot-password') ||
            path.contains('/api/auth/reset-password') ||
            path.contains('/api/auth/refresh');
        if (!isAnonymous) {
          final token = AuthSession.instance.token;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        final status = err.response?.statusCode;
        final isRefreshCall = err.requestOptions.path.contains('/api/auth/refresh');
        final refreshToken = AuthSession.instance.refreshToken;

        // 401 → try refresh once (AUTH-01-04)
        if (status == 401 && !isRefreshCall && refreshToken != null && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final res = await Dio(BaseOptions(baseUrl: _baseUrl)).post(
              '/api/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            final auth = AuthResult.fromJson(res.data as Map<String, dynamic>);
            await AuthSession.instance.setSession(auth);
            // Retry original
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${auth.token}';
            final retry = await d.fetch(opts);
            _isRefreshing = false;
            return handler.resolve(retry);
          } catch (e) {
            await AuthSession.instance.clearSession();
            _isRefreshing = false;
            return handler.next(err);
          }
        }
        return handler.next(err);
      },
    ));

    return d;
  }

  bool _isRefreshing = false;
}

/// Riverpod provider for DI/testing overrides (P1 Arch 4)
final dioProvider = Provider<Dio>((ref) => DioProvider.instance.dio);
