import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/hive_cache_service.dart';
import '../../domain/models/job_filter_params.dart';
import '../../domain/models/job_model.dart';
import '../../domain/models/recommended_job_model.dart';
import '../../domain/repositories/job_repository.dart';

import 'mock_job_repository.dart';

/// Remote API Implementation of [IJobRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Prohibits direct access to internal microservice ports.
///
/// Mock data is only reachable when the build enables it
/// (`--dart-define=ENABLE_MOCKS=true`) *and* the failure is a transport failure
/// or a 5xx. A 4xx never yields fabricated jobs.
class ApiJobRepository implements IJobRepository {
  static final RegExp _sha256HexPattern = RegExp(r'^[0-9a-fA-F]{64}$');

  final Dio _dio;
  final MockJobRepository _fallbackMockRepository = MockJobRepository();
  final bool _enableMocks;
  final Map<String, JobModel> _searchResultCache = {};

  ApiJobRepository({Dio? dio, String? gatewayBaseUrl, bool? enableMockFallback})
    : _dio =
          dio ??
          (gatewayBaseUrl != null && gatewayBaseUrl.isNotEmpty
              ? Dio(
                  BaseOptions(
                    baseUrl: gatewayBaseUrl,
                    connectTimeout: const Duration(seconds: 5),
                    receiveTimeout: const Duration(seconds: 5),
                    headers: {'Accept': 'application/json'},
                  ),
                )
              : DioProvider.instance.dio),
      _enableMocks = enableMockFallback ?? kEnableMocks;

  @override
  Future<PaginatedJobs> getJobs(JobFilterParams params) async {
    var useMock = false;
    try {
      final queryParams = <String, dynamic>{
        'page': params.page.toString(),
        'size': params.pageSize.toString(),
      };

      if (params.keyword != null && params.keyword!.isNotEmpty) {
        queryParams['q'] = params.keyword!;
      }
      if (params.location != null && params.location!.isNotEmpty) {
        queryParams['location'] = params.location!;
      }
      if (params.category != null && params.category!.isNotEmpty) {
        queryParams['category'] = params.category!;
      }
      // search-svc takes employmentType / experienceLevel with canonical
      // backend values. Options without a backend value are not sent at all.
      final employmentType = params.jobType?.backendValue;
      if (employmentType != null) {
        queryParams['employmentType'] = employmentType;
      }
      final experienceLevel = params.experienceLevel?.backendValue;
      if (experienceLevel != null) {
        queryParams['experienceLevel'] = experienceLevel;
      }
      if (params.skills.isNotEmpty) {
        queryParams['skills'] = params.skills.join(',');
        queryParams['skillOp'] = 'or';
      }
      // search-svc has no parameter for specialization, workplaceType, country,
      // region, salaryRange, currency or includeNegotiable, so those filters are
      // not sent. They stay in the UI state until the backend supports them.
      if (params.salaryMin != null) {
        queryParams['minSalary'] = params.salaryMin.toString();
      }
      if (params.salaryMax != null) {
        queryParams['maxSalary'] = params.salaryMax.toString();
      }
      // search-svc accepts created_at_desc/asc and salary_desc/asc. Mobile's
      // 'newest' and 'relevance' have no exact match, so they are omitted and
      // search-svc applies its default ordering.
      if (const {
        'created_at_desc',
        'created_at_asc',
        'salary_desc',
        'salary_asc',
      }.contains(params.sortBy)) {
        queryParams['sortBy'] = params.sortBy;
      }

      final response = await _dio.get(
        '/api/search/jobs',
        queryParameters: queryParams,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw StateError(
          'Unexpected job search response (${response.statusCode})',
        );
      }

      final Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        data = Map<String, dynamic>.from(response.data as Map);
      } else {
        data = jsonDecode(response.data.toString()) as Map<String, dynamic>;
      }

      final items =
          (data['items'] as List<dynamic>?)
              ?.map(
                (item) => JobModel.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          [];

      // Cache jobs in memory and Hive for offline browsing and crawled detail lookup.
      for (final job in items) {
        if (job.id.trim().isNotEmpty) {
          _searchResultCache[job.id] = job;
        }
      }
      if (items.isNotEmpty) {
        await HiveCacheService.instance.saveJobs(items);
        for (final job in items) {
          if (job.id.trim().isNotEmpty) {
            await HiveCacheService.instance.saveJobDetail(job);
          }
        }
      }

      return PaginatedJobs(
        items: items,
        total: data['total'] as int? ?? items.length,
        page: data['page'] as int? ?? params.page,
        size: data['size'] as int? ?? params.pageSize,
        totalPages: data['totalPages'] as int? ?? 1,
      );
    } on DioException catch (e) {
      debugPrint(
        '[ApiJobRepository] getJobs failed: ${e.type} ${e.response?.statusCode}',
      );
      // Cached jobs were fetched from the server earlier, so they stay usable
      // when the gateway is unreachable. A server answer (4xx/5xx) is not
      // unreachable: it must reach the caller.
      if (e.response == null) {
        final cached = await _cachedJobsPage(params);
        if (cached != null) return cached;
      }
      useMock = shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      );
      if (!useMock) rethrow;
    }

    // Reachable only when mocks are enabled and the failure was transport/5xx.
    return _fallbackMockRepository.getJobs(params);
  }

  /// Applies the same filters the server would to the Hive cache. Returns null
  /// when there is no cached job to show.
  Future<PaginatedJobs?> _cachedJobsPage(JobFilterParams params) async {
    final cached = await HiveCacheService.instance.getCachedJobs();
    if (cached.isEmpty) return null;

    var filteredCached = List<JobModel>.from(cached);
    if (params.keyword != null && params.keyword!.trim().isNotEmpty) {
      final q = params.keyword!.trim().toLowerCase();
      filteredCached = filteredCached
          .where(
            (j) =>
                j.title.toLowerCase().contains(q) ||
                j.companyName.toLowerCase().contains(q) ||
                j.skills.any((s) => s.toLowerCase().contains(q)),
          )
          .toList();
    }
    if (params.location != null &&
        params.location!.trim().isNotEmpty &&
        params.location != 'Tất cả') {
      final loc = params.location!.trim().toLowerCase();
      filteredCached = filteredCached
          .where((j) => j.location.toLowerCase().contains(loc))
          .toList();
    }
    if (params.skills.isNotEmpty) {
      final filterSkillsLower = params.skills
          .map((s) => s.toLowerCase())
          .toSet();
      filteredCached = filteredCached.where((j) {
        final jobSkillsLower = j.skills.map((s) => s.toLowerCase()).toSet();
        return filterSkillsLower.any((fs) => jobSkillsLower.contains(fs));
      }).toList();
    }

    return PaginatedJobs(
      items: filteredCached,
      total: filteredCached.length,
      page: params.page,
      size: params.pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    final trimmedId = id.trim();
    if (_sha256HexPattern.hasMatch(trimmedId)) {
      final fromMemory = _searchResultCache[trimmedId];
      if (fromMemory != null) return fromMemory;
      final fromHive = await HiveCacheService.instance.getCachedJobDetail(
        trimmedId,
      );
      if (fromHive != null) return fromHive;
      return null;
    }
    var useMock = false;
    try {
      final response = await _dio.get(
        '/api/jobs/$trimmedId',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else {
          data = jsonDecode(response.data.toString()) as Map<String, dynamic>;
        }
        final job = JobModel.fromJson(data);
        // A detail without an id or title cannot be rendered. Treat it as a
        // failed response so the screen shows retry instead of a blank page.
        if (job.id.trim().isEmpty || job.title.trim().isEmpty) {
          throw StateError('Job detail is missing id or title');
        }
        await HiveCacheService.instance.saveJobDetail(job);
        return job;
      }
      throw StateError(
        'Unexpected job detail response (${response.statusCode})',
      );
    } on DioException catch (e) {
      debugPrint(
        '[ApiJobRepository] getJobById failed: '
        '${e.type} ${e.response?.statusCode}',
      );
      if (e.response == null) {
        final cached = await HiveCacheService.instance.getCachedJobDetail(id);
        if (cached != null) return cached;
      }
      useMock = shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      );
      if (!useMock) rethrow;
    }
    if (!useMock) return null;
    return _fallbackMockRepository.getJobById(id);
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    final q = query.trim();
    // An empty query has nothing to suggest; suggestions are fired per
    // keystroke and the UI only shows them from the first character.
    if (q.isEmpty) return const [];
    var useMock = false;
    try {
      final response = await _dio.get(
        '/api/search/suggest',
        queryParameters: {'q': q, 'limit': '8'},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic decoded = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        // API returns a bare array; tolerate { items: [...] } envelope too.
        final List<dynamic>? items = decoded is List<dynamic>
            ? decoded
            : (decoded is Map ? decoded['items'] as List<dynamic>? : null);
        if (items != null) {
          return items.map((e) => e.toString()).toList();
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[ApiJobRepository] getSearchSuggestions failed: '
        '${e.type} ${e.response?.statusCode}',
      );
      useMock = shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      );
      if (!useMock) rethrow;
    }
    if (!useMock) return const [];
    return _fallbackMockRepository.getSearchSuggestions(query);
  }

  @override
  Future<List<RecommendedJob>> getRecommendedJobs({
    int limit = 10,
    bool refresh = false,
  }) async {
    var useMock = false;
    try {
      final response = await _dio.get(
        '/api/jobs/recommended',
        queryParameters: {
          'limit': limit.toString(),
          if (refresh) 'refresh': 'true',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;

        final Map<String, dynamic> data;
        if (raw is Map<String, dynamic>) {
          data = raw;
        } else if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        } else if (raw is List) {
          return raw
              .map(
                (item) => RecommendedJob.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        } else {
          data = {};
        }

        final targetData =
            (data['data'] is Map
                ? data['data'] as Map<String, dynamic>
                : null) ??
            data;

        final itemsList =
            targetData['items'] as List<dynamic>? ??
            targetData['jobs'] as List<dynamic>? ??
            [];

        final reasonsMapRaw = targetData['reasons'];
        final Map<String, String> reasonsMap = {};
        if (reasonsMapRaw is Map) {
          for (final entry in reasonsMapRaw.entries) {
            reasonsMap[entry.key.toString()] = entry.value.toString();
          }
        }

        final List<RecommendedJob> recommendedJobs = [];
        for (var i = 0; i < itemsList.length; i++) {
          final item = itemsList[i];
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final jobId =
                map['id']?.toString() ??
                (map['job'] is Map
                    ? (map['job'] as Map)['id']?.toString()
                    : null) ??
                '';
            final reasonFromMap = reasonsMap[jobId];
            recommendedJobs.add(
              RecommendedJob.fromJson(map, defaultReason: reasonFromMap),
            );
          }
        }

        if (recommendedJobs.isNotEmpty) {
          return recommendedJobs;
        }
      }
    } on DioException catch (e) {
      debugPrint(
        '[ApiJobRepository] getRecommendedJobs failed: '
        '${e.type} ${e.response?.statusCode}',
      );
      // Real UUID jobs already cached stay usable when the gateway is down.
      if (e.response == null) {
        final cached = await HiveCacheService.instance.getCachedJobs();
        if (cached.isNotEmpty) {
          return cached.take(limit).map((job) {
            return RecommendedJob(
              job: job,
              reason: 'Phù hợp với kỹ năng và vị trí đã lưu của bạn',
              matchType: 'content',
            );
          }).toList();
        }
      }
      useMock = shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      );
      if (!useMock) rethrow;
    }

    // A 200 without recommendations is an empty answer, not a failure.
    if (!useMock) return const [];
    // Reachable only when mocks are enabled and the failure was transport/5xx.
    return _fallbackMockRepository.getRecommendedJobs(
      limit: limit,
      refresh: refresh,
    );
  }
}
