import 'package:flutter/foundation.dart';
import 'job_model.dart';

/// Filter and search parameters for querying jobs (SEARCH-01, MOB-01-02)
@immutable
class JobFilterParams {
  final String? keyword;
  final String? location;
  final String? category;
  final JobType? jobType;
  final ExperienceLevel? experienceLevel;
  final num? salaryMin;
  final num? salaryMax;
  final bool onlySaved;
  final int page;
  final int pageSize;
  final String sortBy; // 'newest', 'salary_desc', 'relevance'

  const JobFilterParams({
    this.keyword,
    this.location,
    this.category,
    this.jobType,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.onlySaved = false,
    this.page = 0,
    this.pageSize = 10,
    this.sortBy = 'newest',
  });

  /// Check whether any non-pagination filter is currently applied
  bool get hasActiveFilters {
    return (keyword != null && keyword!.trim().isNotEmpty) ||
        (location != null && location!.trim().isNotEmpty) ||
        (category != null && category!.trim().isNotEmpty) ||
        jobType != null ||
        experienceLevel != null ||
        salaryMin != null ||
        salaryMax != null ||
        onlySaved;
  }

  /// Number of active categorical filters (excluding search keyword)
  int get activeFilterCount {
    int count = 0;
    if (location != null && location!.trim().isNotEmpty) count++;
    if (category != null && category!.trim().isNotEmpty) count++;
    if (jobType != null) count++;
    if (experienceLevel != null) count++;
    if (salaryMin != null || salaryMax != null) count++;
    if (onlySaved) count++;
    return count;
  }

  JobFilterParams copyWith({
    String? keyword,
    bool clearKeyword = false,
    String? location,
    bool clearLocation = false,
    String? category,
    bool clearCategory = false,
    JobType? jobType,
    bool clearJobType = false,
    ExperienceLevel? experienceLevel,
    bool clearExperienceLevel = false,
    num? salaryMin,
    bool clearSalaryMin = false,
    num? salaryMax,
    bool clearSalaryMax = false,
    bool? onlySaved,
    int? page,
    int? pageSize,
    String? sortBy,
  }) {
    return JobFilterParams(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      location: clearLocation ? null : (location ?? this.location),
      category: clearCategory ? null : (category ?? this.category),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      experienceLevel: clearExperienceLevel
          ? null
          : (experienceLevel ?? this.experienceLevel),
      salaryMin: clearSalaryMin ? null : (salaryMin ?? this.salaryMin),
      salaryMax: clearSalaryMax ? null : (salaryMax ?? this.salaryMax),
      onlySaved: onlySaved ?? this.onlySaved,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Reset all filters back to default empty criteria while maintaining pageSize
  JobFilterParams clearAllFilters() {
    return JobFilterParams(pageSize: pageSize, page: 0, sortBy: 'newest');
  }
}
