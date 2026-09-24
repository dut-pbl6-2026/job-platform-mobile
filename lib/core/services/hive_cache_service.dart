import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/jobs/domain/models/job_model.dart';

/// Offline local caching service powered by Hive (OFFLINE-01)
class HiveCacheService {
  HiveCacheService._();
  static final HiveCacheService _instance = HiveCacheService._();
  static HiveCacheService get instance => _instance;

  static const String jobsBoxName = 'jobs_cache_box';
  static const String jobDetailsBoxName = 'job_details_cache_box';
  static const String recentSearchesBoxName = 'recent_searches_box';

  static const String _kCachedJobsKey = 'cached_jobs_list';
  static const String _kCachedAtKey = 'cached_at_timestamp';
  static const String _kRecentSearchesKey = 'recent_searches_history';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Box? _jobsBox;
  Box? _jobDetailsBox;
  Box? _recentSearchesBox;

  /// Initialize Hive and open all local cache boxes
  Future<void> init({HiveInterface? hive}) async {
    if (_isInitialized &&
        _jobsBox != null &&
        _jobsBox!.isOpen &&
        _jobDetailsBox != null &&
        _jobDetailsBox!.isOpen &&
        _recentSearchesBox != null &&
        _recentSearchesBox!.isOpen) {
      return;
    }

    try {
      final h = hive ?? Hive;
      try {
        await h.initFlutter();
      } catch (e) {
        // May occur in non-device test environment where Hive.init(dir) was already invoked
        debugPrint('[HiveCacheService] initFlutter platform note: $e');
      }

      _jobsBox = await h.openBox(jobsBoxName);
      _jobDetailsBox = await h.openBox(jobDetailsBoxName);
      _recentSearchesBox = await h.openBox(recentSearchesBoxName);

      _isInitialized = true;
      debugPrint('[HiveCacheService] Initialized successfully.');
    } catch (e) {
      debugPrint('[HiveCacheService] Initialization fallback: $e');
      _isInitialized = false;
    }
  }

  /// Reset internal state (useful in test teardown)
  void resetState() {
    _isInitialized = false;
    _jobsBox = null;
    _jobDetailsBox = null;
    _recentSearchesBox = null;
  }

  /// Cache a list of jobs retrieved from the API Gateway
  Future<void> saveJobs(List<JobModel> jobs) async {
    if (!_isInitialized || _jobsBox == null) return;
    try {
      final serializedList = jobs.map((job) => job.toJson()).toList();
      await _jobsBox?.put(_kCachedJobsKey, serializedList);
      await _jobsBox?.put(_kCachedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[HiveCacheService] saveJobs error: $e');
    }
  }

  /// Retrieve cached jobs when offline or network fails
  Future<List<JobModel>> getCachedJobs() async {
    if (!_isInitialized || _jobsBox == null) return [];
    try {
      final raw = _jobsBox?.get(_kCachedJobsKey);
      if (raw is List) {
        return raw.map((item) {
          if (item is Map<String, dynamic>) {
            return JobModel.fromJson(item);
          } else if (item is Map) {
            return JobModel.fromJson(Map<String, dynamic>.from(item));
          } else if (item is String) {
            return JobModel.fromJson(jsonDecode(item) as Map<String, dynamic>);
          }
          throw UnsupportedError('Invalid cached job format: $item');
        }).toList();
      }
    } catch (e) {
      debugPrint('[HiveCacheService] getCachedJobs error: $e');
    }
    return [];
  }

  /// Get the timestamp when jobs were last cached
  DateTime? getLastCachedTime() {
    if (!_isInitialized || _jobsBox == null) return null;
    try {
      final ms = _jobsBox?.get(_kCachedAtKey) as int?;
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    return null;
  }

  /// Cache single job detail
  Future<void> saveJobDetail(JobModel job) async {
    if (!_isInitialized || _jobDetailsBox == null) return;
    try {
      await _jobDetailsBox?.put(job.id, job.toJson());
    } catch (e) {
      debugPrint('[HiveCacheService] saveJobDetail error: $e');
    }
  }

  /// Retrieve single job detail from cache
  Future<JobModel?> getCachedJobDetail(String id) async {
    if (!_isInitialized || _jobDetailsBox == null) return null;
    try {
      final raw = _jobDetailsBox?.get(id);
      if (raw is Map<String, dynamic>) {
        return JobModel.fromJson(raw);
      } else if (raw is Map) {
        return JobModel.fromJson(Map<String, dynamic>.from(raw));
      } else if (raw is String) {
        return JobModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[HiveCacheService] getCachedJobDetail error: $e');
    }
    return null;
  }

  /// Save recent search keyword (max 10, newest first, deduplicated)
  Future<void> saveRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    if (!_isInitialized || _recentSearchesBox == null) return;

    try {
      final current = await getRecentSearches();
      current.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
      current.insert(0, clean);

      // Keep only top 10 recent searches
      final trimmed = current.take(10).toList();
      await _recentSearchesBox?.put(_kRecentSearchesKey, trimmed);
    } catch (e) {
      debugPrint('[HiveCacheService] saveRecentSearch error: $e');
    }
  }

  /// Get recent search queries
  Future<List<String>> getRecentSearches() async {
    if (!_isInitialized || _recentSearchesBox == null) return [];
    try {
      final raw = _recentSearchesBox?.get(_kRecentSearchesKey);
      if (raw is List) {
        return List<String>.from(raw);
      }
    } catch (e) {
      debugPrint('[HiveCacheService] getRecentSearches error: $e');
    }
    return [];
  }

  /// Remove single recent search query
  Future<void> removeRecentSearch(String query) async {
    if (!_isInitialized || _recentSearchesBox == null) return;
    try {
      final current = await getRecentSearches();
      current.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      await _recentSearchesBox?.put(_kRecentSearchesKey, current);
    } catch (e) {
      debugPrint('[HiveCacheService] removeRecentSearch error: $e');
    }
  }

  /// Clear all recent search queries
  Future<void> clearRecentSearches() async {
    if (!_isInitialized || _recentSearchesBox == null) return;
    try {
      await _recentSearchesBox?.delete(_kRecentSearchesKey);
    } catch (e) {
      debugPrint('[HiveCacheService] clearRecentSearches error: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      await _jobsBox?.clear();
      await _jobDetailsBox?.clear();
      await _recentSearchesBox?.clear();
    } catch (e) {
      debugPrint('[HiveCacheService] clearAllCache error: $e');
    }
  }
}
