import 'package:flutter/foundation.dart';

/// Company detail returned by `GET /api/companies/mine`.
///
/// Field names mirror the job-svc contract: `id`, `name`, `taxCode`,
/// `verified`, `logoUrl`, `website`, `description`, `address`, `industry`,
/// `size` and `isCompanyAdmin`.
@immutable
class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    this.taxCode,
    this.verified = false,
    this.logoUrl,
    this.website,
    this.description,
    this.address,
    this.industry,
    this.size,
    this.isCompanyAdmin = false,
  });

  final String id;
  final String name;
  final String? taxCode;
  final bool verified;
  final String? logoUrl;
  final String? website;
  final String? description;
  final String? address;
  final String? industry;
  final String? size;

  /// Whether the signed-in account may edit this company.
  final bool isCompanyAdmin;

  /// Both fields are required by the UI; a response without them is treated as
  /// malformed so the screen can show a retry instead of a blank company.
  bool get isUsable => id.trim().isNotEmpty && name.trim().isNotEmpty;

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? taxCode,
    bool? verified,
    String? logoUrl,
    String? website,
    String? description,
    String? address,
    String? industry,
    String? size,
    bool? isCompanyAdmin,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      taxCode: taxCode ?? this.taxCode,
      verified: verified ?? this.verified,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      description: description ?? this.description,
      address: address ?? this.address,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      isCompanyAdmin: isCompanyAdmin ?? this.isCompanyAdmin,
    );
  }

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: _string(json['id']),
      name: _string(json['name']),
      taxCode: _optional(json['taxCode'] ?? json['tax_code']),
      verified: _bool(json['verified']),
      logoUrl: _optional(json['logoUrl'] ?? json['logo_url']),
      website: _optional(json['website']),
      description: _optional(json['description']),
      address: _optional(json['address']),
      industry: _optional(json['industry']),
      size: _optional(json['size']),
      isCompanyAdmin: _bool(json['isCompanyAdmin'] ?? json['is_company_admin']),
    );
  }

  /// Body for `PUT /api/companies/{id}`, using the backend field names.
  /// `name` is required; optional fields are sent as null when cleared.
  Map<String, dynamic> toApiJson() {
    return {
      'name': name.trim(),
      'taxCode': _nullIfEmpty(taxCode),
      'logoUrl': _nullIfEmpty(logoUrl),
      'website': _nullIfEmpty(website),
      'description': _nullIfEmpty(description),
      'address': _nullIfEmpty(address),
      'industry': _nullIfEmpty(industry),
      'size': _nullIfEmpty(size),
    };
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static String? _optional(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _nullIfEmpty(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }
}
