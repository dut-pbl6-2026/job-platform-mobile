import 'package:dio/dio.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/core/network/dio_provider.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/utils/password_validator.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/auth/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements IAuthRepository {
  final Dio _dio;

  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password, 'rememberMe': rememberMe},
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data as Map);
      final auth = AuthResult.fromJson(data);
      await AuthSession.instance.setSession(auth);
      return auth;
    } on DioException catch (e) {
      throw mapDioToFailure(e);
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
  }) async {
    if (!isPasswordStrong(password)) {
      throw const AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 400,
        rawMessage: 'Weak password',
      );
    }
    if (role == UserRole.recruiter &&
        (companyId == null || companyId.isEmpty)) {
      throw const AuthFailure(
        code: AuthFailure.invalidCompanyId,
        statusCode: 422,
        rawMessage: 'companyId required for Recruiter',
      );
    }
    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        'fullName': name,
        'role': role.value,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
      };
      await _dio.post('/api/auth/register', data: payload);
      return await login(email: email, password: password);
    } on DioException catch (e) {
      throw mapDioToFailure(e);
    } on AuthFailure {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw mapDioToFailure(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (!isPasswordStrong(newPassword)) {
      throw const AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 400,
        rawMessage: 'Weak password',
      );
    }
    try {
      await _dio.post(
        '/api/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw mapDioToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final rt = AuthSession.instance.refreshToken;
      if (rt != null) {
        await _dio.post('/api/auth/logout', data: {'refreshToken': rt});
      }
    } catch (_) {}
    await AuthSession.instance.clearSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get('/api/auth/me');
      // backend returns UserMeDto {id,email,fullName,role,isActive}
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data as Map);
      // Normalize to UserModel shape
      final userMap = data.containsKey('user') && data['user'] is Map
          ? (data['user'] is Map<String, dynamic>
                ? data['user'] as Map<String, dynamic>
                : Map<String, dynamic>.from(data['user'] as Map))
          : data;
      return UserModel.fromJson(userMap);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      throw mapDioToFailure(e);
    }
  }
}
