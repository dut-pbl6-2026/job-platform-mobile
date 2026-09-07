import 'package:dio/dio.dart';
import 'failures.dart';

AuthFailure mapDioToFailure(DioException e) {
  final code = e.response?.statusCode;
  final data = e.response?.data;
  String? detail;
  String? title;
  if (data is Map) {
    detail = data['detail']?.toString();
    title = data['title']?.toString();
  }
  final raw = detail ?? title ?? e.message ?? 'Unknown error';

  if (code == 401) {
    if (raw.toLowerCase().contains('expired')) {
      return AuthFailure(
        code: AuthFailure.tokenExpired,
        statusCode: 401,
        rawMessage: raw,
      );
    }
    if (raw.toLowerCase().contains('revoked')) {
      return AuthFailure(
        code: AuthFailure.tokenRevoked,
        statusCode: 401,
        rawMessage: raw,
      );
    }
    return AuthFailure(
      code: AuthFailure.invalidCredentials,
      statusCode: 401,
      rawMessage: raw,
    );
  }
  if (code == 409) {
    return AuthFailure(
      code: AuthFailure.emailExists,
      statusCode: 409,
      rawMessage: raw,
    );
  }
  if (code == 403) {
    return AuthFailure(
      code: AuthFailure.accountLocked,
      statusCode: 403,
      rawMessage: raw,
    );
  }
  if (code == 422) {
    return AuthFailure(
      code: AuthFailure.invalidCompanyId,
      statusCode: 422,
      rawMessage: raw,
    );
  }
  if (code == 400) {
    final lower = raw.toLowerCase();
    if (lower.contains('password')) {
      return AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 400,
        rawMessage: raw,
      );
    }
    if (lower.contains('token')) {
      return AuthFailure(
        code: AuthFailure.invalidToken,
        statusCode: 400,
        rawMessage: raw,
      );
    }
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return AuthFailure(
      code: AuthFailure.networkError,
      statusCode: code,
      rawMessage: raw,
    );
  }
  return AuthFailure(
    code: AuthFailure.unknown,
    statusCode: code,
    rawMessage: raw,
  );
}

String authFailureToMessage(AuthFailure f) {
  switch (f.code) {
    case AuthFailure.invalidCredentials:
      return 'Email hoặc mật khẩu không chính xác';
    case AuthFailure.emailExists:
      return 'Email đã được đăng ký';
    case AuthFailure.accountLocked:
      return 'Tài khoản bị khóa';
    case AuthFailure.invalidCompanyId:
      return 'Mã công ty không hợp lệ';
    case AuthFailure.weakPassword:
      return 'Mật khẩu phải có ít nhất 8 ký tự, 1 chữ hoa và 1 chữ số';
    case AuthFailure.tokenExpired:
      return 'Phiên đăng nhập đã hết hạn';
    case AuthFailure.tokenRevoked:
      return 'Phiên đăng nhập đã bị thu hồi, vui lòng đăng nhập lại';
    case AuthFailure.invalidToken:
      return 'Mã xác thực không hợp lệ hoặc đã hết hạn';
    case AuthFailure.networkError:
      return 'Lỗi kết nối mạng, vui lòng thử lại';
    default:
      return f.rawMessage ?? 'Đã xảy ra lỗi';
  }
}
