import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Singleton cache service for minimizing Supabase API calls
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory cache with TTL
  final Map<String, _CacheEntry> _memoryCache = {};

  // Cache durations
  static const Duration userProfileTTL = Duration(hours: 1);
  static const Duration timetableTTL = Duration(minutes: 30);
  static const Duration subjectsTTL = Duration(hours: 2);
  static const Duration studentListTTL = Duration(minutes: 15);
  static const Duration scheduleTTL = Duration(minutes: 30);

  /// Get cached data with automatic expiry check
  T? get<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Set data with TTL
  void set<T>(String key, T data, Duration ttl) {
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Check if key exists and is valid
  bool has(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _memoryCache.remove(key);
      return false;
    }
    return true;
  }

  /// Invalidate specific cache
  void invalidate(String key) => _memoryCache.remove(key);

  /// Invalidate by prefix (e.g., all attendance caches)
  void invalidatePrefix(String prefix) {
    _memoryCache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cache
  void clearAll() => _memoryCache.clear();

  /// Persistent cache for user session
  Future<void> persistUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_profile', jsonEncode(profile));
    await prefs.setInt(
      'cached_user_profile_ts',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get persisted user profile (for offline/quick access)
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('cached_user_profile_ts') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;

    // Return cached if less than 1 hour old
    if (age < 3600000) {
      final json = prefs.getString('cached_user_profile');
      if (json != null) {
        try {
          return jsonDecode(json) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Clear persisted user profile
  Future<void> clearPersistedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
    await prefs.remove('cached_user_profile_ts');
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  _CacheEntry({required this.data, required this.expiresAt});
}
