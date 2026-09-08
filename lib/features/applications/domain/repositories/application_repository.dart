import '../models/application_model.dart';

/// Abstract contract for Application repository (APP-01, MOB-01-04, MOB-01-06)
abstract class IApplicationRepository {
  /// Submit application for a job (APP-01-01, MOB-01-04)
  Future<ApplicationModel> applyJob(ApplyJobParams params);

  /// Fetch candidate's application history with optional status filter (APP-01-03, MOB-01-06)
  Future<List<ApplicationModel>> getMyApplications({
    ApplicationStatus? status,
    int page = 0,
    int size = 20,
  });

  /// Get detailed information of a specific application (APP-01-04)
  Future<ApplicationModel?> getApplicationById(String id);

  /// Check if user has already applied for a job to prevent duplicates (APP-01-02)
  Future<bool> hasApplied(String jobId);
}
