import 'package:flutter/foundation.dart';

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
  final int matchScore;

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
    this.matchScore = 0,
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

  factory CandidateApplication.fromJson(Map<String, dynamic> json) {
    return CandidateApplication(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString() ?? '',
      applicantId:
          json['applicantId']?.toString() ??
          json['applicant_id']?.toString() ??
          '',
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
          json['cv_url']?.toString().split('/').last ??
          'CV.pdf',
      cvUrl: json['cvUrl']?.toString() ?? json['cv_url']?.toString(),
      appliedDate:
          json['appliedDate']?.toString() ??
          json['createdAt']?.toString().split('T').first ??
          '',
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
    );
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

  const RecruiterJob({
    required this.id,
    required this.title,
    required this.status,
    this.applicationsCount = 0,
    this.viewsCount = 0,
    required this.location,
    required this.salary,
    required this.postedDate,
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
    );
  }

  static String normalizeJobStatus(String? raw) {
    if (raw == null) return 'Đang mở';
    switch (raw.trim().toLowerCase()) {
      case 'active':
      case 'đang mở':
        return 'Đang mở';
      case 'draft':
      case 'pending':
      case 'chờ duyệt':
        return 'Chờ duyệt';
      case 'closed':
      case 'đã đóng':
        return 'Đã đóng';
      default:
        return raw;
    }
  }

  bool get isOpen => status == 'Đang mở' || status.toLowerCase() == 'active';
  bool get isPending =>
      status == 'Chờ duyệt' ||
      status.toLowerCase() == 'draft' ||
      status.toLowerCase() == 'pending';
  bool get isClosed => status == 'Đã đóng' || status.toLowerCase() == 'closed';

  factory RecruiterJob.fromJson(Map<String, dynamic> json) {
    return RecruiterJob(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: normalizeJobStatus(json['status']?.toString()),
      applicationsCount:
          (json['applications'] as num?)?.toInt() ??
          (json['applicationsCount'] as num?)?.toInt() ??
          0,
      viewsCount:
          (json['views'] as num?)?.toInt() ??
          (json['viewCount'] as num?)?.toInt() ??
          0,
      location: json['location']?.toString() ?? '',
      salary: json['salary']?.toString() ?? 'Thoả thuận',
      postedDate:
          json['postedDate']?.toString() ??
          json['createdAt']?.toString().split('T').first ??
          '',
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
  final String experienceLevel;
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
    this.experienceLevel = 'Junior',
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
}
