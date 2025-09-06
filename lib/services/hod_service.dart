import 'package:supabase_flutter/supabase_flutter.dart';

class HODService {
  final _supabase = Supabase.instance.client;

  /// Check if the current user is an HOD
  Future<bool> isUserHOD() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department')
              .eq('id', user.id)
              .maybeSingle();

      return response != null && response['role'] == 'hod';
    } catch (e) {
      print('Error checking HOD status: $e');
      return false;
    }
  }

  /// Get HOD information for the current user
  Future<Map<String, dynamic>?> getHODInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('users')
              .select('name, email, role, assigned_department')
              .eq('id', user.id)
              .eq('role', 'hod')
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting HOD info: $e');
      return null;
    }
  }

  /// Create a new HOD user
  Future<bool> createHODUser({
    required String email,
    required String name,
    required String department,
    required String password,
  }) async {
    try {
      // Create auth user first
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('Failed to create auth user');
        return false;
      }

      // Create user profile with HOD role
      await _supabase.from('users').insert({
        'id': authResponse.user!.id,
        'name': name,
        'email': email,
        'role': 'hod',
        'assigned_department': department,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error creating HOD user: $e');
      return false;
    }
  }

  /// Update HOD's assigned department
  Future<bool> updateHODDepartment({
    required String userId,
    required String newDepartment,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({'assigned_department': newDepartment})
          .eq('id', userId)
          .eq('role', 'hod');

      return true;
    } catch (e) {
      print('Error updating HOD department: $e');
      return false;
    }
  }

  /// Get all HOD users (admin only)
  Future<List<Map<String, dynamic>>> getAllHODs() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, assigned_department, created_at')
          .eq('role', 'hod')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all HODs: $e');
      return [];
    }
  }

  /// Check if user has permission to view department data
  Future<bool> canViewDepartmentData(String department) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) return false;

      // Admin can view all departments
      if (response['is_admin'] == true || response['role'] == 'admin') {
        return true;
      }

      // HOD can view only their assigned department
      if (response['role'] == 'hod') {
        return response['assigned_department'] == department;
      }

      return false;
    } catch (e) {
      print('Error checking department view permission: $e');
      return false;
    }
  }

  /// Get departments available to current user
  Future<List<String>> getAvailableDepartments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) return [];

      // Admin can see all departments
      if (response['is_admin'] == true || response['role'] == 'admin') {
        // Get all unique departments from students table
        final deptResponse = await _supabase
            .from('students')
            .select('department')
            .order('department');

        final departments =
            deptResponse.map((d) => d['department'] as String).toSet().toList();

        return departments;
      }

      // HOD can see only their assigned department
      if (response['role'] == 'hod' &&
          response['assigned_department'] != null) {
        return [response['assigned_department']];
      }

      return [];
    } catch (e) {
      print('Error getting available departments: $e');
      return [];
    }
  }

  /// Get user role and permissions
  Future<Map<String, dynamic>> getUserRoleInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'role': 'guest',
          'isAdmin': false,
          'isHOD': false,
          'assignedDepartment': null,
        };
      }

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin, name')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) {
        return {
          'role': 'student',
          'isAdmin': false,
          'isHOD': false,
          'assignedDepartment': null,
        };
      }

      return {
        'role': response['role'] ?? 'student',
        'isAdmin': response['is_admin'] == true || response['role'] == 'admin',
        'isHOD': response['role'] == 'hod',
        'assignedDepartment': response['assigned_department'],
        'name': response['name'],
      };
    } catch (e) {
      print('Error getting user role info: $e');
      return {
        'role': 'guest',
        'isAdmin': false,
        'isHOD': false,
        'assignedDepartment': null,
      };
    }
  }
}
