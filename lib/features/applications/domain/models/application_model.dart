import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Application status enum matching SRS Section 3.5.2 (APP-01-06)
enum ApplicationStatus {
  pending('pending', 'Chờ duyệt', 'Hồ sơ đã được gửi và đang chờ nhà tuyển dụng xem xét'),
  reviewed('reviewed', 'Đã xem', 'Nhà tuyển dụng đã mở xem chi tiết hồ sơ ứng tuyển'),
  shortlisted('shortlisted', 'Phù hợp', 'Hồ sơ đã được đưa vào danh sách ứng viên tiềm năng'),
  accepted('accepted', 'Trúng tuyển', 'Chúc mừng! Hồ sơ ứng tuyển của bạn đã được chấp thuận'),
  rejected('rejected', 'Từ chối', 'Rất tiếc, hồ sơ chưa phù hợp với yêu cầu hiện tại');

  final String value;
  final String displayName;
  final String description;

  const ApplicationStatus(this.value, this.displayName, this.description);

  static ApplicationStatus fromString(String value) {
    return ApplicationStatus.values.firstWhere(
      (e) =>
          e.value.toLowerCase() == value.toLowerCase() ||
          e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => ApplicationStatus.pending,
    );
  }

  /// Theme color for badges and indicators
  Color get color {
    switch (this) {
      case ApplicationStatus.pending:
        return const Color(0xFFF59E0B); // Amber / Warning
      case ApplicationStatus.reviewed:
        return AppColors.primary; // Blue / Info
      case ApplicationStatus.shortlisted:
        return const Color(0xFF8B5CF6); // Purple / Violet
      case ApplicationStatus.accepted:
        return AppColors.success; // Emerald Green
      case ApplicationStatus.rejected:
        return AppColors.error; // Red / Error
    }
  }

  /// Background tint color for badges
  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }

  /// Associated Material icon
  IconData get icon {
    switch (this) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.reviewed:
        return Icons.visibility_outlined;
      case ApplicationStatus.shortlisted:
        return Icons.stars_rounded;
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}

/// History log entry for status changes (APP-01-04)
@immutable
class ApplicationStatusHistoryItem {
  final ApplicationStatus status;
  final String? note;
  final DateTime changedAt;
  final String? changedBy;

  const ApplicationStatusHistoryItem({
    required this.status,
    this.note,
    required this.changedAt,
    this.changedBy,
  });

  factory ApplicationStatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusHistoryItem(
      status: ApplicationStatus.fromString(json['status']?.toString() ?? 'pending'),
      note: json['note'] as String?,
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'].toString()) ?? DateTime.now()
          : (json['changed_at'] != null
              ? DateTime.tryParse(json['changed_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      changedBy: json['changedBy'] as String? ?? json['changed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'note': note,
      'changedAt': changedAt.toIso8601String(),
      'changedBy': changedBy,
    };
  }
}

/// Application Entity Model according to SRS 3.5.4 & MOB-01-06
@immutable
class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String? applicantPhone;
  final String? coverLetter;
  final String cvUrl;
  final String cvFileName;
  final int? cvFileSize;
  final ApplicationStatus status;
  final String? recruiterNotes;
  final double? score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ApplicationStatusHistoryItem> statusHistory;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    this.applicantPhone,
    this.coverLetter,
    required this.cvUrl,
    required this.cvFileName,
    this.cvFileSize,
    this.status = ApplicationStatus.pending,
    this.recruiterNotes,
    this.score,
    required this.createdAt,
    required this.updatedAt,
    this.statusHistory = const [],
  });

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    String? companyLogo,
    String? applicantId,
    String? applicantName,
    String? applicantEmail,
    String? applicantPhone,
    String? coverLetter,
    String? cvUrl,
    String? cvFileName,
    int? cvFileSize,
    ApplicationStatus? status,
    String? recruiterNotes,
    double? score,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ApplicationStatusHistoryItem>? statusHistory,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      coverLetter: coverLetter ?? this.coverLetter,
      cvUrl: cvUrl ?? this.cvUrl,
      cvFileName: cvFileName ?? this.cvFileName,
      cvFileSize: cvFileSize ?? this.cvFileSize,
      status: status ?? this.status,
      recruiterNotes: recruiterNotes ?? this.recruiterNotes,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    var rawHistory = json['statusHistory'] ?? json['status_history'];
    List<ApplicationStatusHistoryItem> historyList = [];
    if (rawHistory is List) {
      historyList = rawHistory
          .map((item) => ApplicationStatusHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString() ?? json['job_title']?.toString() ?? 'Vị trí tuyển dụng',
      companyName: json['companyName']?.toString() ?? json['company_name']?.toString() ?? 'Doanh nghiệp',
      companyLogo: json['companyLogo'] as String? ?? json['company_logo'] as String?,
      applicantId: json['applicantId']?.toString() ?? json['applicant_id']?.toString() ?? '',
      applicantName: json['applicantName']?.toString() ?? json['applicant_name']?.toString() ?? '',
      applicantEmail: json['applicantEmail']?.toString() ?? json['applicant_email']?.toString() ?? '',
      applicantPhone: json['applicantPhone'] as String? ?? json['applicant_phone'] as String?,
      coverLetter: json['coverLetter'] as String? ?? json['cover_letter'] as String?,
      cvUrl: json['cvUrl']?.toString() ?? json['cv_url']?.toString() ?? '',
      cvFileName: json['cvFileName']?.toString() ?? json['cv_file_name']?.toString() ?? 'CV_Ung_Tuyen.pdf',
      cvFileSize: json['cvFileSize'] as int? ?? json['cv_file_size'] as int?,
      status: ApplicationStatus.fromString(json['status']?.toString() ?? 'pending'),
      recruiterNotes: json['recruiterNotes'] as String? ?? json['recruiter_notes'] as String?,
      score: (json['score'] as num?)?.toDouble(),
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
      statusHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'coverLetter': coverLetter,
      'cvUrl': cvUrl,
      'cvFileName': cvFileName,
      'cvFileSize': cvFileSize,
      'status': status.value,
      'recruiterNotes': recruiterNotes,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    };
  }
}

/// Request parameters for submitting an application (APP-01-01)
@immutable
class ApplyJobParams {
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final String? coverLetter;
  final String cvFileName;
  final String? cvFilePath;
  final int? cvFileSize;
  final List<int>? cvBytes;

  const ApplyJobParams({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    this.coverLetter,
    required this.cvFileName,
    this.cvFilePath,
    this.cvFileSize,
    this.cvBytes,
  });
}
