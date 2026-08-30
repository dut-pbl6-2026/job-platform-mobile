import 'package:flutter/foundation.dart';
import '../models/job_filter_params.dart';
import '../models/job_model.dart';

/// Paginated list of jobs returned from repository / API Gateway
@immutable
class PaginatedJobs {
  final List<JobModel> items;
  final int total;
  final int page;
  final int size;
  final int totalPages;

  const PaginatedJobs({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.totalPages,
  });

  bool get hasNextPage => (page + 1) < totalPages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Abstract interface for Job Repository (MOB-01-02, JOB-01, SEARCH-01)
abstract class IJobRepository {
  /// Fetch a paginated list of jobs based on filters and search query
  Future<PaginatedJobs> getJobs(JobFilterParams params);

  /// Get detailed job by its unique ID
  Future<JobModel?> getJobById(String id);

  /// Toggle bookmark status of a job (returns new isSaved state)
  Future<bool> toggleSaveJob(String id);

  /// Get search auto-complete keyword suggestions
  Future<List<String>> getSearchSuggestions(String query);
}
