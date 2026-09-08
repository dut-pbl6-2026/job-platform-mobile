import 'package:flutter/foundation.dart';

/// Skill entity model according to SRS 3.6.4 (PROFILE-01-02)
@immutable
class SkillModel {
  final String id;
  final String name;
  final int proficiency; // 1 to 5
  final int yearsOfExperience;

  const SkillModel({
    required this.id,
    required this.name,
    this.proficiency = 3,
    this.yearsOfExperience = 1,
  });

  SkillModel copyWith({
    String? id,
    String? name,
    int? proficiency,
    int? yearsOfExperience,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    );
  }

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      proficiency: json['proficiency'] as int? ?? 3,
      yearsOfExperience: json['yearsOfExperience'] as int? ??
          json['years_of_experience'] as int? ??
          1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'proficiency': proficiency,
      'yearsOfExperience': yearsOfExperience,
    };
  }
}

/// Work Experience entity model according to SRS 3.6.4 (PROFILE-01-03)
@immutable
class WorkExperienceModel {
  final String id;
  final String company;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  const WorkExperienceModel({
    required this.id,
    required this.company,
    required this.title,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  /// User-friendly formatted period, e.g. "01/2022 - Hiện tại" or "06/2020 - 12/2021"
  String get formattedPeriod {
    final startStr = '${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
    if (isCurrent || endDate == null) {
      return '$startStr - Hiện tại';
    }
    final endStr = '${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}';
    return '$startStr - $endStr';
  }

  WorkExperienceModel copyWith({
    String? id,
    String? company,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? description,
  }) {
    return WorkExperienceModel(
      id: id ?? this.id,
      company: company ?? this.company,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      description: description ?? this.description,
    );
  }

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return WorkExperienceModel(
      id: json['id']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : (json['start_date'] != null
              ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
              : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : (json['end_date'] != null
              ? DateTime.tryParse(json['end_date'].toString())
              : null),
      isCurrent: json['isCurrent'] as bool? ?? json['is_current'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
      'description': description,
    };
  }
}

/// Education history model according to SRS 3.6.4 (PROFILE-01-04)
@immutable
class EducationModel {
  final String id;
  final String institution;
  final String degree;
  final String field;
  final DateTime startDate;
  final DateTime? endDate;
  final String? grade;

  const EducationModel({
    required this.id,
    required this.institution,
    required this.degree,
    required this.field,
    required this.startDate,
    this.endDate,
    this.grade,
  });

  /// User-friendly formatted period, e.g. "2016 - 2020"
  String get formattedPeriod {
    final startYear = startDate.year.toString();
    final endYear = endDate != null ? endDate!.year.toString() : 'Hiện tại';
    return '$startYear - $endYear';
  }

  EducationModel copyWith({
    String? id,
    String? institution,
    String? degree,
    String? field,
    DateTime? startDate,
    DateTime? endDate,
    String? grade,
  }) {
    return EducationModel(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      field: field ?? this.field,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      grade: grade ?? this.grade,
    );
  }

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      degree: json['degree']?.toString() ?? '',
      field: json['field']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : (json['start_date'] != null
              ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
              : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : (json['end_date'] != null
              ? DateTime.tryParse(json['end_date'].toString())
              : null),
      grade: json['grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'field': field,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'grade': grade,
    };
  }
}

/// Full Profile entity model according to SRS 3.6.4 (PROFILE-01, MOB-01-05)
@immutable
class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? address;
  final String? headline;
  final String? summary;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final List<SkillModel> skills;
  final List<WorkExperienceModel> experiences;
  final List<EducationModel> educations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.address,
    this.headline,
    this.summary,
    this.avatarUrl,
    this.dateOfBirth,
    this.skills = const [],
    this.experiences = const [],
    this.educations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Profile completion score (0 to 100%)
  int get completionPercentage {
    int score = 0;
    if (fullName.isNotEmpty) score += 20;
    if (phone != null && phone!.isNotEmpty) score += 15;
    if (address != null && address!.isNotEmpty) score += 10;
    if (headline != null && headline!.isNotEmpty) score += 15;
    if (summary != null && summary!.isNotEmpty) score += 10;
    if (skills.isNotEmpty) score += 10;
    if (experiences.isNotEmpty) score += 10;
    if (educations.isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? address,
    String? headline,
    String? summary,
    String? avatarUrl,
    DateTime? dateOfBirth,
    List<SkillModel>? skills,
    List<WorkExperienceModel>? experiences,
    List<EducationModel>? educations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      skills: skills ?? this.skills,
      experiences: experiences ?? this.experiences,
      educations: educations ?? this.educations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    var rawSkills = json['skills'];
    List<SkillModel> skillsList = [];
    if (rawSkills is List) {
      skillsList = rawSkills
          .map((item) => SkillModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var rawExp = json['experiences'] ?? json['work_experiences'];
    List<WorkExperienceModel> expList = [];
    if (rawExp is List) {
      expList = rawExp
          .map((item) => WorkExperienceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var rawEdu = json['educations'] ?? json['education_history'];
    List<EducationModel> eduList = [];
    if (rawEdu is List) {
      eduList = rawEdu
          .map((item) => EducationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      headline: json['headline'] as String?,
      summary: json['summary'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : (json['date_of_birth'] != null
              ? DateTime.tryParse(json['date_of_birth'].toString())
              : null),
      skills: skillsList,
      experiences: expList,
      educations: eduList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : (json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'headline': headline,
      'summary': summary,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'skills': skills.map((e) => e.toJson()).toList(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'educations': educations.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
