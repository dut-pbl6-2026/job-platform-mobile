import 'package:dio/dio.dart';
import '../../../core/session/auth_session.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements IAuthRepository {
  final Dio _dio;
  static const _baseUrl = String.fromEnvironment('FLUTTER_API_URL', defaultValue: 'http://localhost:5000');

  ApiAuthRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthSession.instance.token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }

  @override
  Future<AuthResult> login({required String email, required String password, bool rememberMe = false}) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {'email': email, 'password': password, 'rememberMe': rememberMe});
      final auth = AuthResult.fromJson(res.data as Map<String, dynamic>);
      await AuthSession.instance.setSession(auth);
      return auth;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<AuthResult> register({required String name, required String email, required String password, required UserRole role}) async {
    try {
      await _dio.post('/api/auth/register', data: {'email': email, 'password': password, 'fullName': name, 'role': role.value});
      // Best practice: register returns 201 userId, then explicit login
      return await login(email: email, password: password);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final rt = AuthSession.instance.refreshToken;
      if (rt != null) await _dio.post('/api/auth/logout', data: {'refreshToken': rt});
    } catch (_) {}
    await AuthSession.instance.clearSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get('/api/auth/me');
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String msg = e.message ?? 'Unknown error';
    if (data is Map && data['detail'] != null) msg = data['detail'].toString();
    if (data is Map && data['title'] != null) msg = data['title'].toString();
    if (code == 401) return Exception('Email hoặc mật khẩu không chính xác');
    if (code == 409) return Exception('Email đã được đăng ký');
    if (code == 403) return Exception('Tài khoản bị khóa');
    if (code == 400 && msg.contains('Password')) return Exception('Mật khẩu phải có ít nhất 8 ký tự, 1 chữ hoa và 1 chữ số');
    return Exception(msg);
  }
}
