/// Typed failure for auth domain — presentation maps code to l10n.
class AuthFailure implements Exception {
  final String code;
  final int? statusCode;
  final String? rawMessage;

  const AuthFailure({required this.code, this.statusCode, this.rawMessage});

  @override
  String toString() => 'AuthFailure($code, $statusCode): $rawMessage';

  // Registry of known codes (aligns with backend ProblemDetails mapping)
  static const invalidCredentials = 'invalid_credentials';
  static const emailExists = 'email_exists';
  static const accountLocked = 'account_locked';
  static const invalidCompanyId = 'invalid_company_id';
  static const weakPassword = 'weak_password';
  static const tokenExpired = 'token_expired';
  static const tokenRevoked = 'token_revoked';
  static const invalidToken = 'invalid_token';
  static const networkError = 'network_error';
  static const unknown = 'unknown';
}
