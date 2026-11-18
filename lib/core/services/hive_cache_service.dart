import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/jobs/domain/models/job_model.dart';

/// Offline local caching service powered by Hive with AES-256 encryption (OFFLINE-01, SEC-08)
class HiveCacheService {
  HiveCacheService._();
  static final HiveCacheService _instance = HiveCacheService._();
  static HiveCacheService get instance => _instance;

  static const String jobsBoxName = 'jobs_cache_box';
  static const String jobDetailsBoxName = 'job_details_cache_box';
  static const String recentSearchesBoxName = 'recent_searches_box';
  static const String _kHiveEncryptionKey = 'hive_cache_aes_key';

  static const Duration defaultCacheTtl = Duration(hours: 24);
  static const String _kCachedJobsKey = 'cached_jobs_list';
  static const String _kCachedAtKey = 'cached_at_timestamp';
  static const String _kRecentSearchesKey = 'recent_searches_history';
  static const String _kAnonymousNamespace = 'anon';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Future<void>? _initFuture;
  String _activeUserNamespace = _kAnonymousNamespace;
  String get activeUserNamespace => _activeUserNamespace;

  Box? _jobsBox;
  Box? _jobDetailsBox;
  Box? _recentSearchesBox;

  /// Binds cached reads and writes to the active authenticated user ID (or anon).
  void setActiveUserNamespace(String? userId) {
    final clean = userId?.trim();
    _activeUserNamespace = (clean == null || clean.isEmpty)
        ? _kAnonymousNamespace
        : clean;
  }

  String _scopedKey(String base) => '${_activeUserNamespace}_$base';

  /// Initialize Hive and open all local cache boxes (encrypted at rest when SecureStorage is available)
  Future<void> init({
    HiveInterface? hive,
    List<int>? encryptionKeyOverride,
  }) async {
    if (_isInitialized &&
        _jobsBox != null &&
        _jobsBox!.isOpen &&
        _jobDetailsBox != null &&
        _jobDetailsBox!.isOpen &&
        _recentSearchesBox != null &&
        _recentSearchesBox!.isOpen) {
      return;
    }

    return _initFuture ??= _doInit(
      hive: hive,
      encryptionKeyOverride: encryptionKeyOverride,
    );
  }

  Future<void> _doInit({
    HiveInterface? hive,
    List<int>? encryptionKeyOverride,
  }) async {
    try {
      final h = hive ?? Hive;
      try {
        await h.initFlutter();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HiveCacheService] initFlutter platform note: $e');
        }
      }

      final cipher = await _resolveCipher(h, encryptionKeyOverride);
      _jobsBox = await _openBoxSafely(h, jobsBoxName, cipher);
      _jobDetailsBox = await _openBoxSafely(h, jobDetailsBoxName, cipher);
      _recentSearchesBox = await _openBoxSafely(
        h,
        recentSearchesBoxName,
        cipher,
      );

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[HiveCacheService] Initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HiveCacheService] Initialization fallback: $e');
      }
      _isInitialized = false;
    } finally {
      _initFuture = null;
    }
  }

  Future<HiveAesCipher?> _resolveCipher(
    HiveInterface h,
    List<int>? keyOverride,
  ) async {
    if (keyOverride != null && keyOverride.length == 32) {
      return HiveAesCipher(keyOverride);
    }
    try {
      final encoded = await _secureStorage.read(key: _kHiveEncryptionKey);
      if (encoded != null && encoded.isNotEmpty) {
        final decoded = base64Url.decode(encoded);
        if (decoded.length == 32) {
          return HiveAesCipher(decoded);
        }
      }
      final newKey = h.generateSecureKey();
      await _secureStorage.write(
        key: _kHiveEncryptionKey,
        value: base64UrlEncode(newKey),
      );
      return HiveAesCipher(newKey);
    } on MissingPluginException {
      // Headless unit test without mocked FlutterSecureStorage channel.
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Box> _openBoxSafely(
    HiveInterface h,
    String name,
    HiveAesCipher? cipher,
  ) async {
    try {
      return await h.openBox(name, encryptionCipher: cipher);
    } catch (_) {
      // Automatically wipe stale/unencrypted box on schema or cipher upgrade.
      await h.deleteBoxFromDisk(name);
      return await h.openBox(name, encryptionCipher: cipher);
    }
  }

  /// Reset internal state (useful in test teardown)
  void resetState() {
    _isInitialized = false;
    _initFuture = null;
    _activeUserNamespace = _kAnonymousNamespace;
    _jobsBox = null;
    _jobDetailsBox = null;
    _recentSearchesBox = null;
  }

  bool _isExpired(int cachedAtMs, Duration ttl, DateTime now) {
    return now.millisecondsSinceEpoch - cachedAtMs > ttl.inMilliseconds;
  }

  /// Cache a list of jobs retrieved from the API Gateway
  Future<void> saveJobs(List<JobModel> jobs, {DateTime? now}) async {
    if (!_isInitialized || _jobsBox == null) return;
    try {
      final serializedList = jobs.map((job) => job.toJson()).toList();
      await _jobsBox?.put(_scopedKey(_kCachedJobsKey), serializedList);
      await _jobsBox?.put(
        _scopedKey(_kCachedAtKey),
        (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[HiveCacheService] saveJobs error: $e');
    }
  }

  /// Retrieve cached jobs when offline or network fails (enforcing [ttl]).
  Future<List<JobModel>> getCachedJobs({
    Duration ttl = defaultCacheTtl,
    DateTime? now,
  }) async {
    if (!_isInitialized || _jobsBox == null) return [];
    try {
      final jobsKey = _scopedKey(_kCachedJobsKey);
      final tsKey = _scopedKey(_kCachedAtKey);
      final cachedAtMs = _jobsBox?.get(tsKey) as int?;
      if (cachedAtMs == null ||
          _isExpired(cachedAtMs, ttl, now ?? DateTime.now())) {
        await _jobsBox?.delete(jobsKey);
        await _jobsBox?.delete(tsKey);
        return [];
      }

      final raw = _jobsBox?.get(jobsKey);
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

  /// Get the timestamp when jobs were last cached (or null if expired)
  DateTime? getLastCachedTime({Duration ttl = defaultCacheTtl, DateTime? now}) {
    if (!_isInitialized || _jobsBox == null) return null;
    try {
      final ms = _jobsBox?.get(_scopedKey(_kCachedAtKey)) as int?;
      if (ms != null && !_isExpired(ms, ttl, now ?? DateTime.now())) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    return null;
  }

  /// Cache single job detail
  Future<void> saveJobDetail(JobModel job, {DateTime? now}) async {
    if (!_isInitialized || _jobDetailsBox == null) return;
    try {
      await _jobDetailsBox?.put(_scopedKey('job_${job.id}'), {
        'cachedAt': (now ?? DateTime.now()).millisecondsSinceEpoch,
        'job': job.toJson(),
      });
    } catch (e) {
      debugPrint('[HiveCacheService] saveJobDetail error: $e');
    }
  }

  /// Retrieve single job detail from cache (enforcing [ttl]).
  Future<JobModel?> getCachedJobDetail(
    String id, {
    Duration ttl = defaultCacheTtl,
    DateTime? now,
  }) async {
    if (!_isInitialized || _jobDetailsBox == null) return null;
    try {
      final key = _scopedKey('job_$id');
      final raw = _jobDetailsBox?.get(key);
      if (raw == null) return null;

      if (raw is Map && raw['cachedAt'] is int && raw['job'] is Map) {
        final cachedAtMs = raw['cachedAt'] as int;
        if (_isExpired(cachedAtMs, ttl, now ?? DateTime.now())) {
          await _jobDetailsBox?.delete(key);
          return null;
        }
        return JobModel.fromJson(Map<String, dynamic>.from(raw['job'] as Map));
      }
      // Legacy un-wrapped entries without TTL metadata are treated as stale.
      await _jobDetailsBox?.delete(key);
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
      await _recentSearchesBox?.put(_scopedKey(_kRecentSearchesKey), trimmed);
    } catch (e) {
      debugPrint('[HiveCacheService] saveRecentSearch error: $e');
    }
  }

  /// Get recent search queries
  Future<List<String>> getRecentSearches() async {
    if (!_isInitialized || _recentSearchesBox == null) return [];
    try {
      final raw = _recentSearchesBox?.get(_scopedKey(_kRecentSearchesKey));
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
      await _recentSearchesBox?.put(_scopedKey(_kRecentSearchesKey), current);
    } catch (e) {
      debugPrint('[HiveCacheService] removeRecentSearch error: $e');
    }
  }

  /// Clear all recent search queries
  Future<void> clearRecentSearches() async {
    if (!_isInitialized || _recentSearchesBox == null) return;
    try {
      await _recentSearchesBox?.delete(_scopedKey(_kRecentSearchesKey));
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
