import 'package:flutter/foundation.dart';
import 'job_model.dart';

/// Filter and search parameters for querying jobs (SEARCH-01, MOB-01-02)
/// Aligned with commercial-grade multi-facet filters.
@immutable
class JobFilterParams {
  final String? keyword;
  final String? location; // Province name or code
  final String? country; // 'VN', 'JP'
  final String? internationalRegion; // 'Tokyo', 'Osaka', etc.
  final String? category; // Category id or name
  final String? specialization; // Sub-specialization id or name
  final JobType? jobType;
  final String?
  jobTypeId; // 'internship', 'part_time', 'full_time', 'freelance'
  final ExperienceLevel? experienceLevel;
  final String?
  experienceLevelId; // 'no_exp', 'fresher', 'junior', 'middle', 'senior'
  final String? workplaceType; // 'on_site', 'hybrid', 'remote'
  final List<String> skills;
  final String? salaryRangeId; // 'negotiable', '10m_20m', etc.
  final num? salaryMin;
  final num? salaryMax;
  final String currency; // 'VND', 'JPY'
  final bool onlySaved;
  final int page;
  final int pageSize;
  final String sortBy; // 'newest', 'salary_desc', 'relevance'

  const JobFilterParams({
    this.keyword,
    this.location,
    this.country,
    this.internationalRegion,
    this.category,
    this.specialization,
    this.jobType,
    this.jobTypeId,
    this.experienceLevel,
    this.experienceLevelId,
    this.workplaceType,
    this.skills = const [],
    this.salaryRangeId,
    this.salaryMin,
    this.salaryMax,
    this.currency = 'VND',
    this.onlySaved = false,
    this.page = 0,
    this.pageSize = 10,
    this.sortBy = 'newest',
  });

  /// Check whether any non-pagination filter is currently applied
  bool get hasActiveFilters {
    return (keyword != null && keyword!.trim().isNotEmpty) ||
        (location != null && location!.trim().isNotEmpty) ||
        (country != null && country!.trim().isNotEmpty) ||
        (internationalRegion != null &&
            internationalRegion!.trim().isNotEmpty) ||
        (category != null && category!.trim().isNotEmpty) ||
        (specialization != null && specialization!.trim().isNotEmpty) ||
        jobType != null ||
        (jobTypeId != null && jobTypeId!.trim().isNotEmpty) ||
        experienceLevel != null ||
        (experienceLevelId != null && experienceLevelId!.trim().isNotEmpty) ||
        (workplaceType != null && workplaceType!.trim().isNotEmpty) ||
        skills.isNotEmpty ||
        (salaryRangeId != null && salaryRangeId!.trim().isNotEmpty) ||
        salaryMin != null ||
        salaryMax != null ||
        onlySaved;
  }

  /// Number of active categorical filters (excluding search keyword)
  int get activeFilterCount {
    int count = 0;
    if ((location != null && location!.trim().isNotEmpty) ||
        (country != null && country!.trim().isNotEmpty) ||
        (internationalRegion != null &&
            internationalRegion!.trim().isNotEmpty)) {
      count++;
    }
    if ((category != null && category!.trim().isNotEmpty) ||
        (specialization != null && specialization!.trim().isNotEmpty)) {
      count++;
    }
    if (jobType != null ||
        (jobTypeId != null && jobTypeId!.trim().isNotEmpty)) {
      count++;
    }
    if (experienceLevel != null ||
        (experienceLevelId != null && experienceLevelId!.trim().isNotEmpty)) {
      count++;
    }
    if (workplaceType != null && workplaceType!.trim().isNotEmpty) count++;
    if (skills.isNotEmpty) count++;
    if ((salaryRangeId != null && salaryRangeId!.trim().isNotEmpty) ||
        salaryMin != null ||
        salaryMax != null) {
      count++;
    }
    if (onlySaved) count++;
    return count;
  }

  JobFilterParams copyWith({
    String? keyword,
    bool clearKeyword = false,
    String? location,
    bool clearLocation = false,
    String? country,
    bool clearCountry = false,
    String? internationalRegion,
    bool clearInternationalRegion = false,
    String? category,
    bool clearCategory = false,
    String? specialization,
    bool clearSpecialization = false,
    JobType? jobType,
    bool clearJobType = false,
    String? jobTypeId,
    bool clearJobTypeId = false,
    ExperienceLevel? experienceLevel,
    bool clearExperienceLevel = false,
    String? experienceLevelId,
    bool clearExperienceLevelId = false,
    String? workplaceType,
    bool clearWorkplaceType = false,
    List<String>? skills,
    bool clearSkills = false,
    String? salaryRangeId,
    bool clearSalaryRangeId = false,
    num? salaryMin,
    bool clearSalaryMin = false,
    num? salaryMax,
    bool clearSalaryMax = false,
    String? currency,
    bool? onlySaved,
    int? page,
    int? pageSize,
    String? sortBy,
  }) {
    return JobFilterParams(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      location: clearLocation ? null : (location ?? this.location),
      country: clearCountry ? null : (country ?? this.country),
      internationalRegion: clearInternationalRegion
          ? null
          : (internationalRegion ?? this.internationalRegion),
      category: clearCategory ? null : (category ?? this.category),
      specialization: clearSpecialization
          ? null
          : (specialization ?? this.specialization),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      jobTypeId: clearJobTypeId ? null : (jobTypeId ?? this.jobTypeId),
      experienceLevel: clearExperienceLevel
          ? null
          : (experienceLevel ?? this.experienceLevel),
      experienceLevelId: clearExperienceLevelId
          ? null
          : (experienceLevelId ?? this.experienceLevelId),
      workplaceType: clearWorkplaceType
          ? null
          : (workplaceType ?? this.workplaceType),
      skills: clearSkills ? const [] : (skills ?? this.skills),
      salaryRangeId: clearSalaryRangeId
          ? null
          : (salaryRangeId ?? this.salaryRangeId),
      salaryMin: clearSalaryMin ? null : (salaryMin ?? this.salaryMin),
      salaryMax: clearSalaryMax ? null : (salaryMax ?? this.salaryMax),
      currency: currency ?? this.currency,
      onlySaved: onlySaved ?? this.onlySaved,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Reset all filters back to default empty criteria while maintaining pageSize
  JobFilterParams clearAllFilters() {
    return JobFilterParams(
      pageSize: pageSize,
      page: 0,
      sortBy: 'newest',
      skills: const [],
    );
  }
}
