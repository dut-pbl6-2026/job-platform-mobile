import 'package:flutter/foundation.dart';

import '../../../../core/utils/format_utils.dart';

/// Job category option returned by `GET /api/categories`.
@immutable
class JobCategoryItem {
  final String id;
  final String name;
  final String? slug;

  const JobCategoryItem({required this.id, required this.name, this.slug});

  factory JobCategoryItem.fromJson(Map<String, dynamic> json) {
    return JobCategoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
    );
  }
}

/// Candidate application data model for recruiter candidate review (APP-01-05).
@immutable
class CandidateApplication {
  final String id;
  final String jobId;
  final String applicantId;
  final String name;
  final String title;
  final String experience;
  final String status;
  final String cvName;
  final String? cvUrl;
  final String appliedDate;
  final List<String> skills;
  final int? matchScore;
  final String? scoreStatus;

  const CandidateApplication({
    required this.id,
    this.jobId = '',
    this.applicantId = '',
    required this.name,
    required this.title,
    this.experience = '',
    required this.status,
    required this.cvName,
    this.cvUrl,
    required this.appliedDate,
    this.skills = const [],
    this.matchScore,
    this.scoreStatus,
  });

  CandidateApplication copyWith({
    String? id,
    String? jobId,
    String? applicantId,
    String? name,
    String? title,
    String? experience,
    String? status,
    String? cvName,
    String? cvUrl,
    String? appliedDate,
    List<String>? skills,
    int? matchScore,
    String? scoreStatus,
  }) {
    return CandidateApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      name: name ?? this.name,
      title: title ?? this.title,
      experience: experience ?? this.experience,
      status: status ?? this.status,
      cvName: cvName ?? this.cvName,
      cvUrl: cvUrl ?? this.cvUrl,
      appliedDate: appliedDate ?? this.appliedDate,
      skills: skills ?? this.skills,
      matchScore: matchScore ?? this.matchScore,
      scoreStatus: scoreStatus ?? this.scoreStatus,
    );
  }

  static String normalizeCandidateStatus(String? raw) {
    if (raw == null) return 'Chờ xem';
    switch (raw.trim().toLowerCase()) {
      case 'pending':
      case 'chờ xem':
        return 'Chờ xem';
      case 'reviewed':
      case 'đã xem':
        return 'Đã xem';
      case 'shortlisted':
      case 'phù hợp':
        return 'Phù hợp';
      case 'accepted':
      case 'được nhận':
        return 'Được nhận';
      case 'rejected':
      case 'từ chối':
        return 'Từ chối';
      default:
        return raw;
    }
  }

  bool get isPending =>
      status == 'Chờ xem' || status.toLowerCase() == 'pending';
  bool get isShortlisted =>
      status == 'Phù hợp' || status.toLowerCase() == 'shortlisted';
  bool get isScorePending =>
      matchScore == null || scoreStatus?.toLowerCase() == 'pending';

  factory CandidateApplication.fromJson(Map<String, dynamic> json) {
    final cvUrl = json['cvUrl']?.toString();
    return CandidateApplication(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      applicantId: json['applicantId']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['applicantName']?.toString() ??
          'Ứng viên',
      title:
          json['title']?.toString() ??
          json['jobTitle']?.toString() ??
          'Ứng viên tiềm năng',
      experience: json['experience']?.toString() ?? '',
      status: normalizeCandidateStatus(json['status']?.toString()),
      cvName:
          json['cvName']?.toString() ??
          json['cvFileName']?.toString() ??
          cvUrl?.split('/').last ??
          'CV.pdf',
      cvUrl: cvUrl,
      appliedDate:
          json['appliedDate']?.toString() ??
          json['createdAt']?.toString().split('T').first ??
          '',
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      matchScore: _parseScore(json['score'] ?? json['matchScore']),
      scoreStatus: json['scoreStatus']?.toString(),
    );
  }

  static int? _parseScore(Object? raw) {
    if (raw is num) {
      if (raw > 0 && raw <= 1.0) {
        return (raw * 100).round();
      }
      return raw.round().clamp(0, 100);
    }
    if (raw is String) {
      final parsed = double.tryParse(raw.trim());
      if (parsed != null) {
        return parsed > 0 && parsed <= 1.0
            ? (parsed * 100).round()
            : parsed.round().clamp(0, 100);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'applicantId': applicantId,
      'name': name,
      'title': title,
      'experience': experience,
      'status': status,
      'cvName': cvName,
      'cvUrl': cvUrl,
      'appliedDate': appliedDate,
      'skills': skills,
      'matchScore': matchScore,
      if (scoreStatus != null) 'scoreStatus': scoreStatus,
    };
  }
}

/// Recruiter job posting model (JOB-01-02).
@immutable
class RecruiterJob {
  final String id;
  final String title;
  final String status;
  final int applicationsCount;
  final int viewsCount;
  final String location;
  final String salary;
  final String postedDate;
  final String? description;
  final String? requirements;
  final String? benefits;
  final String? employmentType;
  final String? experienceLevel;
  final String? categoryId;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;

  const RecruiterJob({
    required this.id,
    required this.title,
    required this.status,
    this.applicationsCount = 0,
    this.viewsCount = 0,
    required this.location,
    required this.salary,
    required this.postedDate,
    this.description,
    this.requirements,
    this.benefits,
    this.employmentType,
    this.experienceLevel,
    this.categoryId,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'VND',
  });

  RecruiterJob copyWith({
    String? id,
    String? title,
    String? status,
    int? applicationsCount,
    int? viewsCount,
    String? location,
    String? salary,
    String? postedDate,
    String? description,
    String? requirements,
    String? benefits,
    String? employmentType,
    String? experienceLevel,
    String? categoryId,
    double? salaryMin,
    double? salaryMax,
    String? salaryCurrency,
  }) {
    return RecruiterJob(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      postedDate: postedDate ?? this.postedDate,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      employmentType: employmentType ?? this.employmentType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      categoryId: categoryId ?? this.categoryId,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
    );
  }

  /// Companies publish immediately, so a legacy `pending`/`draft` value is an
  /// active posting, not one waiting for approval. Unknown values are shown
  /// unchanged so a legacy API answer is not mislabelled.
  static String normalizeJobStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Active';
    switch (raw.trim().toLowerCase()) {
      case 'active':
      case 'published':
      case 'open':
      case 'đang mở':
      case 'draft':
      case 'pending':
      case 'chờ duyệt':
        return 'Active';
      case 'closed':
      case 'expired':
      case 'đã đóng':
        return 'Closed';
      default:
        return raw;
    }
  }

  bool get isOpen =>
      status == 'Active' ||
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'đang mở';
  bool get isClosed =>
      status == 'Closed' ||
      status.toLowerCase() == 'closed' ||
      status.toLowerCase() == 'đã đóng';

  factory RecruiterJob.fromJson(Map<String, dynamic> json) {
    final minVal = (json['salaryMin'] as num?)?.toDouble();
    final maxVal = (json['salaryMax'] as num?)?.toDouble();
    final currency = json['salaryCurrency']?.toString() ?? 'VND';
    final rawSalary = json['salary']?.toString();
    final resolvedSalary = (rawSalary != null && rawSalary.trim().isNotEmpty)
        ? rawSalary
        : FormatUtils.formatSalaryRange(
            min: minVal,
            max: maxVal,
            currency: currency,
          );

    return RecruiterJob(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: normalizeJobStatus(json['status']?.toString()),
      applicationsCount:
          (json['applications'] as num?)?.toInt() ??
          (json['applicationsCount'] as num?)?.toInt() ??
          (json['applicationCount'] as num?)?.toInt() ??
          0,
      viewsCount:
          (json['views'] as num?)?.toInt() ??
          (json['viewCount'] as num?)?.toInt() ??
          0,
      location: json['location']?.toString() ?? '',
      salary: resolvedSalary,
      postedDate:
          json['postedDate']?.toString() ??
          json['createdAt']?.toString().split('T').first ??
          '',
      description: json['description']?.toString(),
      requirements: json['requirements']?.toString(),
      benefits: json['benefits']?.toString(),
      employmentType: json['employmentType']?.toString(),
      experienceLevel: json['experienceLevel']?.toString(),
      categoryId: json['categoryId']?.toString(),
      salaryMin: minVal,
      salaryMax: maxVal,
      salaryCurrency: currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'applications': applicationsCount,
      'views': viewsCount,
      'location': location,
      'salary': salary,
      'postedDate': postedDate,
    };
  }
}

/// Summary statistics for Recruiter Dashboard.
@immutable
class RecruiterStats {
  final int activeJobsCount;
  final int newApplicationsCount;
  final int viewsCount;
  final int interviewsCount;

  const RecruiterStats({
    this.activeJobsCount = 0,
    this.newApplicationsCount = 0,
    this.viewsCount = 0,
    this.interviewsCount = 0,
  });

  factory RecruiterStats.fromJson(Map<String, dynamic> json) {
    return RecruiterStats(
      activeJobsCount: (json['activeJobsCount'] as num?)?.toInt() ?? 0,
      newApplicationsCount:
          (json['newApplicationsCount'] as num?)?.toInt() ?? 0,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      interviewsCount: (json['interviewsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeJobsCount': activeJobsCount,
      'newApplicationsCount': newApplicationsCount,
      'viewsCount': viewsCount,
      'interviewsCount': interviewsCount,
    };
  }
}

/// Parameters required to post a job in job-svc (JOB-01-01).
@immutable
class PostJobParams {
  final String title;
  final String location;
  final String employmentType;

  /// Canonical backend value (Entry, Mid, Senior, Lead). Required by the form.
  final String? experienceLevel;
  final String salaryText;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;
  final String description;
  final String? requirements;
  final String? benefits;
  final String? companyId;
  final String? categoryId;

  const PostJobParams({
    required this.title,
    required this.location,
    this.employmentType = 'Toàn thời gian',
    this.experienceLevel,
    this.salaryText = '',
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'VND',
    required this.description,
    this.requirements,
    this.benefits,
    this.companyId,
    this.categoryId,
  });

  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'description': description,
      if (companyId != null) 'companyId': companyId,
      'location': location,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      if (categoryId != null) 'categoryId': categoryId,
      if (requirements != null) 'requirements': requirements,
      if (benefits != null) 'benefits': benefits,
      'employmentType': employmentType,
      'experienceLevel': experienceLevel,
    };
  }

  /// Parses user-entered salary text (e.g. `15.000.000 - 25.000.000 ₫`, `20 - 35 triệu`,
  /// `1500 - 2500 USD`, `Thỏa thuận`) into structured numeric bounds (`salaryMin`, `salaryMax`, `currency`).
  /// Returns `isInvalidRange: true` when both bounds exist and `max < min`.
  static ({double? min, double? max, String currency, bool isInvalidRange})
  parseSalaryInput(String raw, {String defaultCurrency = 'VND'}) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    final isUsd = lower.contains('usd') || trimmed.contains('\$');
    final currency = isUsd ? 'USD' : defaultCurrency;

    if (trimmed.isEmpty ||
        lower.contains('thỏa thuận') ||
        lower.contains('thoả thuận') ||
        lower.contains('negotiable')) {
      return (min: null, max: null, currency: currency, isInvalidRange: false);
    }

    final isMillionUnit =
        !isUsd &&
        (lower.contains('triệu') ||
            RegExp(r'\d+\s*tr\b', caseSensitive: false).hasMatch(lower));
    final multiplier = isMillionUnit ? 1000000.0 : 1.0;

    // Split on common range separators (-, –, —, to, đến, tới)
    final parts = trimmed.split(
      RegExp(r'\s*(?:[-–—]|đến|tới|to)\s*', caseSensitive: false),
    );
    final numbers = <double>[];
    for (final part in parts) {
      final digitsOnly = part.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isNotEmpty) {
        final parsed = double.tryParse(digitsOnly);
        if (parsed != null) {
          numbers.add(parsed * multiplier);
        }
      }
    }

    if (numbers.isEmpty) {
      return (min: null, max: null, currency: currency, isInvalidRange: false);
    }
    if (numbers.length == 1) {
      if (lower.startsWith('tới') ||
          lower.startsWith('đến') ||
          lower.startsWith('dưới')) {
        return (
          min: null,
          max: numbers.first,
          currency: currency,
          isInvalidRange: false,
        );
      }
      return (
        min: numbers.first,
        max: null,
        currency: currency,
        isInvalidRange: false,
      );
    }

    final minVal = numbers[0];
    final maxVal = numbers[1];
    return (
      min: minVal,
      max: maxVal,
      currency: currency,
      isInvalidRange: maxVal < minVal,
    );
  }
}
