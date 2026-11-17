import 'package:flutter/foundation.dart';

import '../../../../core/constants/company_self_serve_strings.dart';

/// Backend status of a company join request (job-svc `CompanyJoinRequestStatus`).
/// A request whose stored status is Pending but whose `expiresAt` has passed is
/// reported by the server as Expired, so [JoinRequestStatus.tryParse] is the only
/// place the raw value is interpreted.
enum JoinRequestStatus {
  pending('Pending', JoinRequestStrings.statusPending),
  approved('Approved', JoinRequestStrings.statusApproved),
  rejected('Rejected', JoinRequestStrings.statusRejected),
  expired('Expired', JoinRequestStrings.statusExpired),
  escalated('Escalated', JoinRequestStrings.statusEscalated),
  supportApproved('SupportApproved', JoinRequestStrings.statusSupportApproved),
  supportRejected('SupportRejected', JoinRequestStrings.statusSupportRejected),
  unknown('Unknown', JoinRequestStrings.statusUnknown);

  const JoinRequestStatus(this.apiValue, this.label);

  /// Value used by job-svc in JSON.
  final String apiValue;

  /// Vietnamese label shown in the UI.
  final String label;

  static JoinRequestStatus tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return JoinRequestStatus.unknown;
    for (final status in JoinRequestStatus.values) {
      if (status.apiValue.toLowerCase() == value) return status;
    }
    return JoinRequestStatus.unknown;
  }

  /// True while an admin can still approve or reject the request (AUTH-01-12,
  /// AUTH-01-13). An expired request cannot be decided.
  bool get isPending => this == JoinRequestStatus.pending;
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// A join request as seen by the company admin (AUTH-01-12 to AUTH-01-14).
@immutable
class CompanyJoinRequest {
  final String id;
  final String companyId;
  final String userId;
  final JoinRequestStatus status;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final String? decisionReason;

  const CompanyJoinRequest({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.status,
    this.expiresAt,
    this.createdAt,
    this.decidedAt,
    this.decisionReason,
  });

  factory CompanyJoinRequest.fromJson(Map<String, dynamic> json) {
    return CompanyJoinRequest(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: JoinRequestStatus.tryParse(json['status']?.toString()),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
      decidedAt: _parseDate(json['decidedAt']),
      decisionReason: json['decisionReason']?.toString(),
    );
  }
}

/// The requester's own join request (AUTH-01-13, AUTH-01-14). [canEscalate] is
/// decided by the server so the client never guesses from the clock.
@immutable
class MyJoinRequest {
  final String id;
  final String companyId;
  final JoinRequestStatus status;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final bool canEscalate;

  const MyJoinRequest({
    required this.id,
    required this.companyId,
    required this.status,
    this.expiresAt,
    this.createdAt,
    this.canEscalate = false,
  });

  factory MyJoinRequest.fromJson(Map<String, dynamic> json) {
    return MyJoinRequest(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      status: JoinRequestStatus.tryParse(json['status']?.toString()),
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']),
      canEscalate: json['canEscalate'] == true,
    );
  }
}

/// One page of a company's join requests. The endpoint is paginated
/// (`JoinRequestPage {items,total,page,size}` in job-svc); [total] is kept so the
/// admin screen can tell "no requests" apart from "more requests than shown".
@immutable
class CompanyJoinRequestPage {
  final List<CompanyJoinRequest> items;
  final int total;
  final int page;
  final int size;

  const CompanyJoinRequestPage({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  /// True while the server reports requests beyond the ones already loaded.
  bool get hasMore => (page - 1) * size + items.length < total;

  factory CompanyJoinRequestPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = (rawItems is List ? rawItems : const [])
        .whereType<Map>()
        .map(
          (item) =>
              CompanyJoinRequest.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    return CompanyJoinRequestPage(
      items: items,
      total: _parseInt(json['total']) ?? items.length,
      page: _parseInt(json['page']) ?? 1,
      size: _parseInt(json['size']) ?? items.length,
    );
  }
}

int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}
