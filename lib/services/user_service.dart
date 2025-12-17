import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Assuming user roles are stored in a 'user_roles' table
      // and linked to the 'users' table by user ID.
      // You might need to adjust this query based on your actual database schema.
      final response =
          await _supabase
              .from('user_roles')
              .select('role')
              .eq('user_id', user.id)
              .single();

      if (response.isNotEmpty) {
        final role = response['role'];
        return role ==
            'admin'; // Assuming 'admin' is the role name for administrators
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
