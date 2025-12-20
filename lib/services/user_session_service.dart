import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

/// Singleton service for caching user session and role information
/// Reduces repeated API calls for role checks across screens
class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  final _supabase = Supabase.instance.client;
  final _cache = CacheService();

  // Cached user info - fetched ONCE per app lifecycle
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  /// Get user info with caching - only fetches from DB once
  Future<Map<String, dynamic>> getUserInfo({bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _userInfo != null) {
      return _userInfo!;
    }

    // Prevent duplicate parallel requests
    if (_isLoading) {
      // Wait for existing request to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _userInfo ?? {};
    }

    _isLoading = true;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _userInfo = {
          'role': 'guest',
          'isStaff': false,
          'isAdmin': false,
          'isHOD': false,
        };
        return _userInfo!;
      }

      // SINGLE query to get ALL user info - replaces 4+ separate queries
      final response = await _supabase
          .from('users')
          .select('id, name, email, role, is_admin, assigned_department')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final role = (response['role'] ?? 'student').toString().toLowerCase();
        _userInfo = {
          'id': response['id'],
          'name': response['name'],
          'email': response['email'] ?? user.email,
          'role': role,
          'isStaff': ['staff', 'admin', 'faculty', 'teacher', 'hod'].contains(role),
          'isAdmin': response['is_admin'] == true || role == 'admin',
          'isHOD': role == 'hod',
          'assignedDepartment': response['assigned_department'],
        };
      } else {
        _userInfo = {
          'id': user.id,
          'email': user.email,
          'role': 'student',
          'isStaff': false,
          'isAdmin': false,
          'isHOD': false,
        };
      }

      // Persist for offline access
      await _cache.persistUserProfile(_userInfo!);

      return _userInfo!;
    } catch (e) {
      print('Error fetching user info: $e');
      // Try to get from persistent cache
      final cached = await _cache.getCachedUserProfile();
      if (cached != null) {
        _userInfo = cached;
        return _userInfo!;
      }
      // Return default
      _userInfo = {
        'role': 'student',
        'isStaff': false,
        'isAdmin': false,
        'isHOD': false,
      };
      return _userInfo!;
    } finally {
      _isLoading = false;
    }
  }

  // Quick sync getters (no API call) - use after getUserInfo() is called once
  String get role => _userInfo?['role'] ?? 'student';
  bool get isStaff => _userInfo?['isStaff'] ?? false;
  bool get isAdmin => _userInfo?['isAdmin'] ?? false;
  bool get isHOD => _userInfo?['isHOD'] ?? false;
  String? get assignedDepartment => _userInfo?['assignedDepartment'];
  String? get userName => _userInfo?['name'];
  String? get userEmail => _userInfo?['email'];
  String? get userId => _userInfo?['id'];

  /// Check if user info has been loaded
  bool get isLoaded => _userInfo != null;

  /// Call this on logout to clear cached session
  void clearSession() {
    _userInfo = null;
    _cache.clearAll();
    _cache.clearPersistedProfile();
  }

  /// Preload user info (call in main.dart or splash screen)
  Future<void> preload() async {
    if (_userInfo == null) {
      await getUserInfo();
    }
  }
}
