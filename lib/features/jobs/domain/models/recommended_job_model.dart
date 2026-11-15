import 'package:flutter/foundation.dart';
import 'job_model.dart';

/// Personalized job recommendation entity (SRS RECOMMEND-01, W13).
///
/// The backend returns a `strategy` (Collaborative | Content | Popular) and no
/// score. The client therefore carries no match percentage.
@immutable
class RecommendedJob {
  final JobModel job;
  final String reason;

  /// Recommendation strategy, lowercased ("collaborative", "content",
  /// "popular") or a legacy mock tag. Null when the source did not provide one.
  final String? matchType;

  const RecommendedJob({
    required this.job,
    required this.reason,
    this.matchType,
  });

  factory RecommendedJob.fromJson(
    Map<String, dynamic> json, {
    String? defaultReason,
  }) {
    // Tolerant parser: supports both { job: {...}, reason: "..." } and flat job objects
    final JobModel parsedJob;
    if (json.containsKey('job') && json['job'] is Map<String, dynamic>) {
      parsedJob = JobModel.fromJson(json['job'] as Map<String, dynamic>);
    } else if (json.containsKey('job') && json['job'] is Map) {
      parsedJob = JobModel.fromJson(
        Map<String, dynamic>.from(json['job'] as Map),
      );
    } else {
      parsedJob = JobModel.fromJson(json);
    }

    final reason =
        json['reason'] as String? ??
        json['recommendationReason'] as String? ??
        defaultReason ??
        'Đề xuất phù hợp với hồ sơ và kỹ năng của bạn';

    // job-svc sends `strategy`; `matchType` / `type` are read for older payloads.
    final rawType =
        json['matchType'] as String? ??
        json['type'] as String? ??
        json['strategy'] as String?;
    final matchType = rawType?.trim().toLowerCase();

    return RecommendedJob(
      job: parsedJob,
      reason: reason,
      matchType: (matchType == null || matchType.isEmpty) ? null : matchType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job': job.toJson(),
      'reason': reason,
      if (matchType != null) 'matchType': matchType,
    };
  }

  RecommendedJob copyWith({JobModel? job, String? reason, String? matchType}) {
    return RecommendedJob(
      job: job ?? this.job,
      reason: reason ?? this.reason,
      matchType: matchType ?? this.matchType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendedJob &&
          runtimeType == other.runtimeType &&
          job == other.job &&
          reason == other.reason &&
          matchType == other.matchType;

  @override
  int get hashCode => job.hashCode ^ reason.hashCode ^ matchType.hashCode;
}

/// Detailed explanation for why a job was recommended (SRS RECOMMEND-01-04)
@immutable
class RecommendationExplanation {
  final String jobId;
  final String reason;
  final num score;

  const RecommendationExplanation({
    required this.jobId,
    required this.reason,
    required this.score,
  });

  factory RecommendationExplanation.fromJson(Map<String, dynamic> json) {
    return RecommendationExplanation(
      jobId: json['jobId'] as String? ?? json['job_id'] as String? ?? '',
      reason:
          json['reason'] as String? ??
          'Công việc này phù hợp với lịch sử ứng tuyển và kỹ năng của bạn.',
      score: json['score'] as num? ?? 85,
    );
  }

  Map<String, dynamic> toJson() {
    return {'jobId': jobId, 'reason': reason, 'score': score};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationExplanation &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          reason == other.reason &&
          score == other.score;

  @override
  int get hashCode => jobId.hashCode ^ reason.hashCode ^ score.hashCode;
}
