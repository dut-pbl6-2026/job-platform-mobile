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
  if (code == 429) {
    return AuthFailure(
      code: AuthFailure.rateLimited,
      statusCode: 429,
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
    // The backend tags each 422 with a stable errorCode. They mean different
    // things to the user, so they must not collapse into one message.
    final errorCode = data is Map ? data['errorCode']?.toString() : null;
    if (errorCode == 'WORK_EMAIL_REQUIRED') {
      return AuthFailure(
        code: AuthFailure.workEmailRequired,
        statusCode: 422,
        rawMessage: raw,
      );
    }
    if (errorCode == 'VERIFICATION_TOKEN_INVALID') {
      return AuthFailure(
        code: AuthFailure.verificationTokenInvalid,
        statusCode: 422,
        rawMessage: raw,
      );
    }
    if (errorCode == 'INVITE_EMAIL_INVALID') {
      return AuthFailure(
        code: AuthFailure.invalidInviteCode,
        statusCode: 422,
        rawMessage: raw,
      );
    }
    if (errorCode == null && data is Map && data['errors'] is Map) {
      // ValidationProblem (e.g. password too weak), not an invite-code error.
      return AuthFailure(
        code: AuthFailure.requestInvalid,
        statusCode: 422,
        rawMessage: raw,
      );
    }
    return AuthFailure(
      code: AuthFailure.invalidInviteCode,
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

/// Login 401 copy. The server returns the same 401 for a wrong password and for
/// an account that is not verified yet, so the client cannot tell them apart.
const String loginCredentialsOrVerifyMessage =
    'Check your credentials or verify your email';

/// Shown when the server answers 429 (too many requests from this IP).
const String rateLimitedMessage =
    'Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau.';

String authFailureToMessage(AuthFailure f) {
  switch (f.code) {
    case AuthFailure.rateLimited:
      return rateLimitedMessage;
    case AuthFailure.invalidCredentials:
      return loginCredentialsOrVerifyMessage;
    case AuthFailure.emailExists:
      return 'Email đã được đăng ký';
    case AuthFailure.accountLocked:
      return 'Tài khoản bị khóa';
    case AuthFailure.invalidInviteCode:
      return 'Mã mời không hợp lệ, đã dùng hoặc đã hết hạn';
    case AuthFailure.inviteUnavailable:
      return 'Chưa kiểm tra được mã mời, vui lòng thử lại sau';
    case AuthFailure.weakPassword:
      return 'Mật khẩu phải có ít nhất 8 ký tự, 1 chữ hoa và 1 chữ số';
    case AuthFailure.tokenExpired:
      return 'Phiên đăng nhập đã hết hạn';
    case AuthFailure.tokenRevoked:
      return 'Phiên đăng nhập đã bị thu hồi, vui lòng đăng nhập lại';
    case AuthFailure.invalidToken:
      return 'Mã xác thực không hợp lệ hoặc đã hết hạn';
    case AuthFailure.verificationTokenInvalid:
      return 'Liên kết xác minh không hợp lệ, đã hết hạn hoặc đã được sử dụng.';
    case AuthFailure.workEmailRequired:
      return 'Cần dùng email công ty để đăng ký doanh nghiệp.';
    case AuthFailure.serviceUnavailable:
      return 'Hệ thống tạm thời không khả dụng. Vui lòng thử lại sau.';
    case AuthFailure.requestInvalid:
      return 'Dữ liệu chưa hợp lệ, vui lòng kiểm tra lại.';
    case AuthFailure.networkError:
      return 'Lỗi kết nối mạng, vui lòng thử lại';
    default:
      return f.rawMessage ?? 'Đã xảy ra lỗi';
  }
}
