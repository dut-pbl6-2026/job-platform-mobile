import 'dart:typed_data';

import '../models/recruiter_models.dart';

/// Abstract repository interface for Recruiter features (JOB-01, APP-01).
abstract class IRecruiterRepository {
  /// Whether the repository is providing mock/prototype data.
  bool get isMock;

  /// Fetch list of candidates who applied to recruiter's jobs.
  Future<List<CandidateApplication>> getCandidateApplications({
    String? jobId,
    String? status,
  });

  /// Update a candidate's application status (pending, reviewed, shortlisted, accepted, rejected).
  Future<bool> updateCandidateStatus(String applicationId, String newStatus);

  /// Download CV bytes via authenticated gateway path or verified HTTPS URL.
  Future<Uint8List> downloadCvBytes(String cvUrl);

  /// Fetch recruiter's own posted jobs.
  Future<List<RecruiterJob>> getMyJobs({
    String? status,
    int? page,
    int? pageSize,
  });

  /// Fetch available job categories (`GET /api/categories`).
  Future<List<JobCategoryItem>> getCategories();

  /// Fetch recruiter overview metrics.
  Future<RecruiterStats> getDashboardStats();

  /// Post a new job posting to job-svc via Gateway (`POST /api/jobs`).
  Future<String> postJob(PostJobParams params);

  /// Update an existing job posting (`PUT /api/jobs/{id}`).
  Future<void> updateJob(String jobId, PostJobParams params);

  /// Delete / close an existing job posting (`DELETE /api/jobs/{id}`).
  Future<void> deleteJob(String jobId);
}
