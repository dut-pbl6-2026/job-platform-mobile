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

  /// Fetch recruiter's own posted jobs.
  Future<List<RecruiterJob>> getMyJobs({String? status});

  /// Fetch recruiter overview metrics.
  Future<RecruiterStats> getDashboardStats();

  /// Post a new job posting to job-svc via Gateway.
  Future<String> postJob(PostJobParams params);
}
