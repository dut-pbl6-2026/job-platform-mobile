import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/core/network/dio_provider.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/utils/password_validator.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'mock_auth_repository.dart';

class ApiAuthRepository implements IAuthRepository {
  final Dio _dio;
  final MockAuthRepository _fallbackMockRepository = MockAuthRepository();

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
      // If server responded with a status code (e.g. 400 Bad Request, 401 Unauthorized), respect it
      if (e.response != null && e.response!.statusCode != null) {
        throw mapDioToFailure(e);
      }
      debugPrint(
        '[ApiAuthRepository] Gateway offline or CORS blocked, falling back to mock: ${e.message}',
      );
      return _fallbackMockRepository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
    } catch (e) {
      debugPrint(
        '[ApiAuthRepository] Unexpected error, falling back to mock: $e',
      );
      return _fallbackMockRepository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
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
      if (e.response != null && e.response!.statusCode != null) {
        throw mapDioToFailure(e);
      }
      debugPrint(
        '[ApiAuthRepository] Gateway offline or CORS blocked during register, falling back to mock: ${e.message}',
      );
      return _fallbackMockRepository.register(
        name: name,
        email: email,
        password: password,
        role: role,
        companyId: companyId,
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint(
        '[ApiAuthRepository] Unexpected error during register, falling back to mock: $e',
      );
      return _fallbackMockRepository.register(
        name: name,
        email: email,
        password: password,
        role: role,
        companyId: companyId,
      );
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode != null) {
        throw mapDioToFailure(e);
      }
      debugPrint(
        '[ApiAuthRepository] Gateway offline, falling back to mock forgotPassword: ${e.message}',
      );
      return _fallbackMockRepository.forgotPassword(email: email);
    } catch (e) {
      debugPrint(
        '[ApiAuthRepository] Unexpected error, falling back to mock forgotPassword: $e',
      );
      return _fallbackMockRepository.forgotPassword(email: email);
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
      if (e.response != null && e.response!.statusCode != null) {
        throw mapDioToFailure(e);
      }
      debugPrint(
        '[ApiAuthRepository] Gateway offline, falling back to mock resetPassword: ${e.message}',
      );
      return _fallbackMockRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
    } catch (e) {
      debugPrint(
        '[ApiAuthRepository] Unexpected error, falling back to mock resetPassword: $e',
      );
      return _fallbackMockRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
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
      if (e.response == null) {
        return AuthSession.instance.currentUser;
      }
      throw mapDioToFailure(e);
    } catch (_) {
      return AuthSession.instance.currentUser;
    }
  }
}
