import 'package:dio/dio.dart';

import '../../../../core/constants/company_self_serve_strings.dart';
import '../../../../core/network/dio_provider.dart';

/// An invite code issued by the company creator (SRS AUTH-01-09). The server keeps only a hash;
/// [code] is shown once. The code is bound to [email] (AUTH-01-15), so only an
/// account registering with that address can redeem it.
class IssuedInviteCode {
  final String id;
  final String code;
  final String email;
  final DateTime expiresAt;

  const IssuedInviteCode({
    required this.id,
    required this.code,
    required this.email,
    required this.expiresAt,
  });

  factory IssuedInviteCode.fromJson(Map<String, dynamic> json) {
    return IssuedInviteCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
    );
  }
}

/// User-facing failure for the issue call. [message] is Vietnamese copy.
class InviteCodeException implements Exception {
  final String message;

  const InviteCodeException(this.message);

  @override
  String toString() => 'InviteCodeException: $message';
}

/// Creator-only issue call through the gateway. The body is `{ email }` and the
/// plain code comes back once. The server answers 403 when the caller is not the
/// creator (`INVITE_CODE_NOT_CREATOR`), 404 for an unknown company and 422
/// (`INVITE_EMAIL_INVALID`) for an unusable address.
class ApiInviteCodeRepository {
  final Dio _dio;

  ApiInviteCodeRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;

  Future<IssuedInviteCode> createInviteCode({
    required String companyId,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/api/companies/$companyId/invite-codes',
        data: {'email': email.trim()},
      );
      final data = response.data;
      if (data is! Map) {
        throw const InviteCodeException(InviteCodeStrings.failed);
      }
      return IssuedInviteCode.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      if (e.response == null) {
        throw const InviteCodeException('Lỗi kết nối mạng, vui lòng thử lại');
      }
      switch (e.response!.statusCode) {
        case 403:
          throw const InviteCodeException(InviteCodeStrings.notCreator);
        case 404:
          throw const InviteCodeException(
            'Không tìm thấy công ty của bạn. Vui lòng thử lại sau.',
          );
        case 422:
          throw const InviteCodeException(InviteCodeStrings.emailRejected);
        case 429:
          throw const InviteCodeException(
            'Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau.',
          );
      }
      throw const InviteCodeException(InviteCodeStrings.failed);
    }
  }
}
