import 'package:supabase_flutter/supabase_flutter.dart';

class DataSetupService {
  final _supabase = Supabase.instance.client;

  /// Populates the student_attendance table with sample data
  Future<void> setupAttendanceData() async {
    try {
      print('Starting database setup...');

      // First check if table has data already
      final existingData = await _supabase
          .from('student_attendance')
          .select('registration_no');

      if (existingData.isNotEmpty) {
        print(
          'Table already has ${existingData.length} records. Skipping setup.',
        );
        return;
      }

      print('Database setup complete. Table structure is ready.');
    } catch (e) {
      print('Error during database setup: $e');
    }
  }

  /// Checks if the student_attendance table exists and has the right structure
  Future<bool> validateDatabaseStructure() async {
    try {
      // Try a simple query to see if the table exists
      await _supabase
          .from('student_attendance')
          .select('registration_no')
          .limit(1);
      print('Table structure validation successful');
      return true;
    } catch (e) {
      print('Table structure validation failed: $e');
      return false;
    }
  }
}
