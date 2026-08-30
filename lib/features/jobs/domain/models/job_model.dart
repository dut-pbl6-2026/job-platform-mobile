import 'package:flutter/foundation.dart';

/// Employment type enum
enum JobType {
  fullTime('Full-time', 'Toàn thời gian'),
  partTime('Part-time', 'Bán thời gian'),
  remote('Remote', 'Từ xa'),
  hybrid('Hybrid', 'Linh hoạt'),
  freelance('Freelance', 'Tự do');

  final String value;
  final String displayName;

  const JobType(this.value, this.displayName);

  static JobType fromString(String value) {
    return JobType.values.firstWhere(
      (e) =>
          e.value.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => JobType.fullTime,
    );
  }
}

/// Candidate experience level enum
enum ExperienceLevel {
  intern('Intern', 'Thực tập sinh'),
  fresher('Fresher', 'Mới tốt nghiệp'),
  junior('Junior', '1 - 2 năm'),
  middle('Middle', '2 - 4 năm'),
  senior('Senior', '5+ năm'),
  lead('Lead', 'Trưởng nhóm / Quản lý');

  final String value;
  final String displayName;

  const ExperienceLevel(this.value, this.displayName);

  static ExperienceLevel fromString(String value) {
    return ExperienceLevel.values.firstWhere(
      (e) =>
          e.value.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ExperienceLevel.junior,
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
  final bool isSalaryNegotiable;
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
    this.isSalaryNegotiable = false,
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

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      companyLogo: json['companyLogo'] as String?,
      location: json['location'] as String? ?? '',
      salaryMin: json['salaryMin'] as num?,
      salaryMax: json['salaryMax'] as num?,
      isSalaryNegotiable: json['isSalaryNegotiable'] as bool? ?? false,
      category: json['category'] as String? ?? 'Khác',
      jobType: JobType.fromString(json['jobType'] as String? ?? 'Full-time'),
      experienceLevel: ExperienceLevel.fromString(
        json['experienceLevel'] as String? ?? 'Junior',
      ),
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      requirements: json['requirements'] as String? ?? '',
      benefits: json['benefits'] as String? ?? '',
      postedAt: json['postedAt'] != null
          ? DateTime.parse(json['postedAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isSaved: json['isSaved'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      applicationCount: json['applicationCount'] as int? ?? 0,
    );
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
      'isSalaryNegotiable': isSalaryNegotiable,
      'category': category,
      'jobType': jobType.value,
      'experienceLevel': experienceLevel.value,
      'skills': skills,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'postedAt': postedAt.toIso8601String(),
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
    bool? isSalaryNegotiable,
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
      isSalaryNegotiable: isSalaryNegotiable ?? this.isSalaryNegotiable,
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
