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
      data: {
        'name': name,
        'gender': gender,
      },
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
    
    final response = await _supabase
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
    
    await _supabase
        .from('profiles')
        .update(data)
        .eq('id', currentUser!.id);
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Stream of auth changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}