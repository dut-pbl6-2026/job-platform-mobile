import '../models/join_request.dart';

/// Company join-request contract (SRS AUTH-01-12 to AUTH-01-14).
///
/// Admin calls are restricted by job-svc to the company creator (the only
/// admin in this version) and go through the gateway under `/api/companies`.
/// The requester calls act on the signed-in account, so they take no company or
/// request id.
abstract class ICompanyJoinRequestRepository {
  /// Lists one page of the requests of [companyId]. Only the company admin may
  /// call this. [CompanyJoinRequestPage.total] tells the screen whether more
  /// requests exist beyond the loaded page.
  Future<CompanyJoinRequestPage> listForCompany(
    String companyId, {
    int page = 1,
    int size = 20,
  });

  /// Approves a pending request (AUTH-01-12). Throws [JoinRequestException] on
  /// `409` when the request is no longer pending or has expired.
  Future<void> approve({required String companyId, required String requestId});

  /// Rejects a pending request (AUTH-01-12). A reason is optional.
  Future<void> reject({
    required String companyId,
    required String requestId,
    String? reason,
  });

  /// Returns the signed-in account's request, or null when it has none
  /// (`404 JOIN_REQUEST_NOT_FOUND`, AUTH-01-13).
  Future<MyJoinRequest?> getMine();

  /// Escalates an expired request to support, once (AUTH-01-14).
  Future<void> escalate();
}

/// Failure of a join-request call. [message] is Vietnamese copy ready for the UI.
class JoinRequestException implements Exception {
  final String message;

  const JoinRequestException(this.message);

  @override
  String toString() => 'JoinRequestException: $message';
}
