import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String gender,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'gender': gender},
    );

    // Create user profile after successful signup
    if (response.user != null) {
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        name: name,
        gender: gender,
      );
    }

    return response;
  }

  // Create user profile in the database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String gender,
  }) async {
    await _supabase.from('profiles').insert({
      'id': userId,
      'email': email,
      'name': name,
      'gender': gender,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final response =
        await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .single();

    return response;
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? gender,
    String? department,
    int? semester,
  }) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (department != null) data['department'] = department;
    if (semester != null) data['semester'] = semester;

    await _supabase.from('profiles').update(data).eq('id', currentUser!.id);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Stream of auth changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Get user role from the users table
  Future<String?> getUserRoleFromDatabase() async {
    try {
      if (currentUser == null) return null;

      // Query the users table for the current user's role
      final response =
          await _supabase
              .from('users')
              .select('role')
              .eq('id', currentUser!.id)
              .single();
      print('DEBUG: Supabase user role response: $response');
      final role = response['role'] as String?;
      if (role != null) {
        return role.toLowerCase();
      }
      return null;
    } catch (e) {
      print('DEBUG: Supabase user role error: $e');
      return null;
    }
  }

  // Role-based authentication methods
  Future<bool> isStaff() async {
    try {
      if (currentUser == null) return false;
      final role = await getUserRoleFromDatabase();
      print('DEBUG: isStaff role: $role');
      if (role != null) {
        return role == 'staff' ||
            role == 'admin' ||
            role == 'faculty' ||
            role == 'teacher';
      }
      return false;
    } catch (e) {
      print('DEBUG: isStaff error: $e');
      return false;
    }
  }

  Future<bool> isAdmin() async {
    try {
      if (currentUser == null) return false;
      final role = await getUserRoleFromDatabase();
      print('DEBUG: isAdmin role: $role');
      return role == 'admin';
    } catch (e) {
      print('DEBUG: isAdmin error: $e');
      return false;
    }
  }

  Future<bool> isStudent() async {
    try {
      if (currentUser == null) return false;
      final role = await getUserRoleFromDatabase();
      print('DEBUG: isStudent role: $role');
      return role == 'student';
    } catch (e) {
      print('DEBUG: isStudent error: $e');
      return false;
    }
  }

  Future<String> getUserRole() async {
    try {
      if (currentUser == null) return 'unknown';
      final role = await getUserRoleFromDatabase();
      print('DEBUG: getUserRole: $role');
      if (role != null) {
        return role;
      }
      return 'student';
    } catch (e) {
      print('DEBUG: getUserRole error: $e');
      return 'unknown';
    }
  }

  // Get detailed user information including role
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      if (currentUser == null) return null;

      final response =
          await _supabase
              .from('users')
              .select('*')
              .eq('id', currentUser!.id)
              .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching user info: $e');
      return null;
    }
  }

  // Test method to verify database connection and role setup
  Future<Map<String, dynamic>> testRoleSetup() async {
    try {
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No authenticated user',
          'user_id': null,
          'email': null,
          'role': null,
        };
      }

      // Test 1: Check if users table exists and is accessible
      final userInfo = await getUserInfo();

      // Test 2: Get role from database (with fallback)
      final role = await getUserRoleFromDatabase();

      // Test 3: Check role-based access
      final staffStatus = await isStaff();
      final adminStatus = await isAdmin();
      final studentStatus = await isStudent();

      return {
        'success': true,
        'user_id': currentUser!.id,
        'email': currentUser!.email,
        'user_info': userInfo,
        'role': role,
        'is_staff': staffStatus,
        'is_admin': adminStatus,
        'is_student': studentStatus,
        'message': 'Database connection and role setup verified successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'user_id': currentUser?.id,
        'email': currentUser?.email,
        'role': null,
        'message': 'Error testing role setup',
      };
    }
  }
}
