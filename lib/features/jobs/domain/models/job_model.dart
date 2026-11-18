import 'package:flutter/foundation.dart';

/// Employment type enum. Backend values (job-svc, api-conventions §6) are
/// FullTime, PartTime, Contract and Internship; the other entries are mobile
/// UI categories kept for filters and mock data.
enum JobType {
  fullTime('Full-time', 'Toàn thời gian'),
  partTime('Part-time', 'Bán thời gian'),
  contract('Contract', 'Hợp đồng'),
  internship('Internship', 'Thực tập'),
  remote('Remote', 'Từ xa'),
  hybrid('Hybrid', 'Linh hoạt'),
  freelance('Freelance', 'Tự do'),

  /// A value the client does not recognise. Never shown as [fullTime].
  other('Other', 'Khác');

  final String value;
  final String displayName;

  const JobType(this.value, this.displayName);

  /// Canonical `employmentType` value for search-svc (api-conventions §6), or
  /// null when job-svc has no equivalent (remote, hybrid, freelance, other).
  /// Callers must omit the filter for null instead of sending a guess.
  String? get backendValue => switch (this) {
    JobType.fullTime => 'FullTime',
    JobType.partTime => 'PartTime',
    JobType.contract => 'Contract',
    JobType.internship => 'Internship',
    JobType.remote ||
    JobType.hybrid ||
    JobType.freelance ||
    JobType.other => null,
  };

  /// Matches case-insensitively and ignores spaces, hyphens and underscores, so
  /// the backend enum spelling "FullTime" maps to [fullTime] like "Full-time".
  /// Unknown or empty values map to [other], never to [fullTime].
  static JobType fromString(String value) {
    final key = _normalizeKey(value);
    return JobType.values.firstWhere(
      (e) =>
          _normalizeKey(e.value) == key || _normalizeKey(e.displayName) == key,
      orElse: () => JobType.other,
    );
  }

  static String _normalizeKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
}

/// Candidate experience level enum
enum ExperienceLevel {
  intern('Intern', 'Thực tập sinh'),
  fresher('Fresher', 'Mới tốt nghiệp'),
  junior('Junior', '1 - 2 năm'),
  middle('Middle', '2 - 4 năm'),
  senior('Senior', '5+ năm'),
  lead('Lead', 'Trưởng nhóm / Quản lý'),

  /// A value the client does not recognise. Never shown as [junior].
  other('Other', 'Khác');

  final String value;
  final String displayName;

  const ExperienceLevel(this.value, this.displayName);

  /// Canonical `experienceLevel` value for search-svc (api-conventions §6), or
  /// null when job-svc has no equivalent. Junior (SRS open decision) and intern
  /// are not mapped to a guessed level, so callers must omit the filter.
  String? get backendValue => switch (this) {
    ExperienceLevel.fresher => 'Entry',
    ExperienceLevel.middle => 'Mid',
    ExperienceLevel.senior => 'Senior',
    ExperienceLevel.lead => 'Lead',
    ExperienceLevel.intern ||
    ExperienceLevel.junior ||
    ExperienceLevel.other => null,
  };

  /// Maps backend values explicitly: "Entry" to [fresher] and "Mid" to
  /// [middle]. "Senior" and "Lead" match by name. Mobile's own spellings are
  /// still accepted so cached entries keep their values. Unknown or empty values
  /// map to [other], never to [junior].
  static ExperienceLevel fromString(String value) {
    final key = value.trim().toLowerCase();
    switch (key) {
      case 'entry':
        return ExperienceLevel.fresher;
      case 'mid':
        return ExperienceLevel.middle;
    }
    return ExperienceLevel.values.firstWhere(
      (e) => e.value.toLowerCase() == key || e.displayName.toLowerCase() == key,
      orElse: () => ExperienceLevel.other,
    );
  }
}

/// Immutable Job entity model for job postings (MOB-01-02, JOB-01, SEARCH-01)
@immutable
class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String location;
  final num? salaryMin;
  final num? salaryMax;
  final String salaryCurrency;
  final bool isSalaryNegotiable;
  final bool isCompanyVerified;
  final String category;
  final JobType jobType;
  final ExperienceLevel experienceLevel;
  final List<String> skills;
  final String description;
  final String requirements;
  final String benefits;
  final DateTime postedAt;
  final DateTime? expiresAt;
  final bool isSaved;
  final int viewCount;
  final int applicationCount;

  const JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'VND',
    this.isSalaryNegotiable = false,
    this.isCompanyVerified = true,
    required this.category,
    this.jobType = JobType.fullTime,
    this.experienceLevel = ExperienceLevel.junior,
    this.skills = const [],
    required this.description,
    required this.requirements,
    this.benefits = '',
    required this.postedAt,
    this.expiresAt,
    this.isSaved = false,
    this.viewCount = 0,
    this.applicationCount = 0,
  });

  /// Crawled jobs indexed by `job-platform-crawler` use a 64-char SHA-256 hex ID.
  static final RegExp _sha256HexPattern = RegExp(r'^[0-9a-fA-F]{64}$');

  /// Whether this job originated from an external crawler feed rather than `job-svc`.
  bool get isExternalCrawledJob => _sha256HexPattern.hasMatch(id.trim());

  /// Parses a job from the search API (`/api/search/jobs` items) or the job
  /// detail API (`/api/jobs/{id}`). Both use canonical camelCase keys:
  /// `employmentType`, `createdAt`, `categoryName`, and `salaryCurrency`/`currency`.
  /// Legacy keys (`jobType`, `postedAt`, `category`) are still read for
  /// local Hive cache entries written by [toJson].
  factory JobModel.fromJson(Map<String, dynamic> json) {
    final nestedCompany = json['company'] is Map
        ? Map<String, dynamic>.from(json['company'] as Map)
        : null;
    final explicitVerified =
        json['isCompanyVerified'] as bool? ??
        json['verified'] as bool? ??
        nestedCompany?['verified'] as bool?;

    return JobModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      companyName:
          _readString(json, 'companyName') ??
          _readNestedName(json, 'company') ??
          '',
      companyLogo:
          _readString(json, 'companyLogo') ??
          _readString(json, 'logoUrl') ??
          (nestedCompany != null
              ? _readString(nestedCompany, 'logoUrl')
              : null),
      location: json['location']?.toString() ?? '',
      salaryMin: json['salaryMin'] as num?,
      salaryMax: json['salaryMax'] as num?,
      salaryCurrency:
          _readString(json, 'salaryCurrency') ??
          _readString(json, 'currency') ??
          'VND',
      isSalaryNegotiable: json['isSalaryNegotiable'] as bool? ?? false,
      isCompanyVerified: explicitVerified ?? true,
      category:
          _readString(json, 'categoryName') ??
          _readNestedName(json, 'category') ??
          _readString(json, 'category') ??
          'Khác',
      // A missing or unknown value becomes JobType.other / ExperienceLevel.other
      // (not a silent default).
      jobType: JobType.fromString(
        _readString(json, 'employmentType') ??
            _readString(json, 'jobType') ??
            '',
      ),
      experienceLevel: ExperienceLevel.fromString(
        _readString(json, 'experienceLevel') ?? '',
      ),
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString() ?? '',
      benefits: json['benefits']?.toString() ?? '',
      postedAt:
          _readDate(json, 'createdAt') ??
          _readDate(json, 'postedAt') ??
          DateTime.now(),
      expiresAt: _readDate(json, 'expiresAt'),
      isSaved: json['isSaved'] as bool? ?? false,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      applicationCount:
          (json['applicationCount'] as num? ??
                  json['applicationsCount'] as num?)
              ?.toInt() ??
          0,
    );
  }

  /// Returns [key] only when its value is a non-empty string. Other shapes
  /// (for example a nested `category` object from the recommendations API)
  /// are ignored instead of throwing a cast error.
  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  /// Returns the `name` of a nested reference object such as
  /// `{ "id": "...", "name": "..." }`, or null when absent or blank.
  static String? _readNestedName(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) {
      return _readString(Map<String, dynamic>.from(value), 'name');
    }
    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> json, String key) {
    final value = _readString(json, key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'location': location,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'isSalaryNegotiable': isSalaryNegotiable,
      'isCompanyVerified': isCompanyVerified,
      'category': category,
      'categoryName': category,
      'jobType': jobType.value,
      'employmentType': jobType.value,
      'experienceLevel': experienceLevel.value,
      'skills': skills,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'postedAt': postedAt.toIso8601String(),
      'createdAt': postedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isSaved': isSaved,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
    };
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? companyName,
    String? companyLogo,
    String? location,
    num? salaryMin,
    num? salaryMax,
    String? salaryCurrency,
    bool? isSalaryNegotiable,
    bool? isCompanyVerified,
    String? category,
    JobType? jobType,
    ExperienceLevel? experienceLevel,
    List<String>? skills,
    String? description,
    String? requirements,
    String? benefits,
    DateTime? postedAt,
    DateTime? expiresAt,
    bool? isSaved,
    int? viewCount,
    int? applicationCount,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      location: location ?? this.location,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      isSalaryNegotiable: isSalaryNegotiable ?? this.isSalaryNegotiable,
      isCompanyVerified: isCompanyVerified ?? this.isCompanyVerified,
      category: category ?? this.category,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      skills: skills ?? this.skills,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      postedAt: postedAt ?? this.postedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isSaved: isSaved ?? this.isSaved,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          companyName == other.companyName &&
          isSaved == other.isSaved;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isSaved.hashCode;
}
