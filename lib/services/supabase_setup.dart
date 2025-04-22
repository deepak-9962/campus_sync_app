import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to set up required Supabase resources
class SupabaseSetup {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Initialize all required resources for the app
  Future<bool> initialize() async {
    try {
      // Try to execute basic setup
      final results = await Future.wait([
        _setupBuckets(),
        _setupTables(),
        _setupAdmin(),
      ], eagerError: false);
      
      // Check how many succeeded
      final successCount = results.where((result) => result).length;
      debugPrint('Supabase setup completed: $successCount/3 steps succeeded');
      
      // Return true if at least one step succeeded
      return successCount > 0;
    } catch (e) {
      debugPrint('Error during Supabase setup: $e');
      return false;
    }
  }
  
  /// Set up storage buckets
  Future<bool> _setupBuckets() async {
    try {
      // Try multiple methods to create the resources bucket
      
      // Method 1: Standard API
      try {
        final buckets = await _supabase.storage.listBuckets();
        final bucketNames = buckets.map((bucket) => bucket.name).toList();
        
        if (!bucketNames.contains('resources')) {
          await _supabase.storage.createBucket('resources');
          debugPrint('Created resources bucket using standard API');
        } else {
          debugPrint('Resources bucket already exists');
        }
        return true;
      } catch (e) {
        debugPrint('Standard bucket creation failed: $e');
      }
      
      // Method 2: RPC
      try {
        await _supabase.rpc('create_bucket', params: {
          'name': 'resources',
          'public': true
        });
        debugPrint('Created resources bucket using RPC');
        return true;
      } catch (e) {
        debugPrint('RPC bucket creation failed: $e');
      }
      
      // Method 3: SQL (requires admin privileges)
      try {
        await _supabase.rpc('execute_sql', params: {
          'query': "INSERT INTO storage.buckets(id, name, public) VALUES('resources', 'resources', true) ON CONFLICT DO NOTHING"
        });
        debugPrint('Created resources bucket using SQL');
        return true;
      } catch (e) {
        debugPrint('SQL bucket creation failed: $e');
      }
      
      // Failed all methods
      return false;
    } catch (e) {
      debugPrint('Error setting up buckets: $e');
      return false;
    }
  }
  
  /// Set up required database tables
  Future<bool> _setupTables() async {
    try {
      // Check if required tables exist
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Ensure users table has our user
      try {
        final userData = await _supabase.from('users').select().eq('id', user.id).maybeSingle();
        
        if (userData == null) {
          // User doesn't exist, create it
          await _supabase.from('users').insert({
            'id': user.id,
            'is_admin': true
          });
          debugPrint('Created user record');
        } else {
          debugPrint('User record already exists');
        }
      } catch (e) {
        debugPrint('Error setting up user table: $e');
        
        // Try simpler insert as fallback
        try {
          await _supabase.rpc('create_user_record', params: {
            'user_id': user.id
          });
        } catch (rpcError) {
          debugPrint('RPC user creation failed: $rpcError');
        }
      }
      
      // For resources table
      try {
        // Check if resources table exists by trying to select from it
        await _supabase.from('resources').select('id').limit(1);
        debugPrint('Resources table exists');
      } catch (e) {
        // Table might not exist
        if (e.toString().contains('relation "resources" does not exist')) {
          debugPrint('Resources table does not exist, trying to create it');
          
          try {
            await _supabase.rpc('execute_sql', params: {
              'query': '''
              CREATE TABLE IF NOT EXISTS public.resources (
                id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
                title text NOT NULL,
                description text,
                category text,
                department text,
                semester integer,
                file_path text,
                file_url text,
                file_type text,
                file_size integer,
                preview_text text,
                uploaded_by uuid REFERENCES auth.users(id),
                created_at timestamp with time zone DEFAULT now()
              );
              '''
            });
            debugPrint('Created resources table');
          } catch (sqlError) {
            debugPrint('Failed to create resources table: $sqlError');
          }
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error setting up tables: $e');
      return false;
    }
  }
  
  /// Set up admin user
  Future<bool> _setupAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Try to set admin status
      try {
        await _supabase.from('users').upsert({
          'id': user.id,
          'is_admin': true
        }, onConflict: 'id');
        debugPrint('Set admin status successfully');
        return true;
      } catch (e) {
        debugPrint('Error setting admin status: $e');
      }
      
      // Try RPC method
      try {
        await _supabase.rpc('set_admin_status', params: {
          'user_id': user.id,
          'is_admin': true
        });
        debugPrint('Set admin status via RPC');
        return true;
      } catch (e) {
        debugPrint('RPC admin setting failed: $e');
      }
      
      // Try SQL method (requires admin privileges)
      try {
        await _supabase.rpc('execute_sql', params: {
          'query': "UPDATE users SET is_admin = true WHERE id = '${user.id}'"
        });
        debugPrint('Set admin status via SQL');
        return true;
      } catch (e) {
        debugPrint('SQL admin setting failed: $e');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error setting up admin: $e');
      return false;
    }
  }
} 