import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDataService {
  final _supabase = Supabase.instance.client;

  /// Creates the students table if it doesn't exist
  Future<void> setupStudentsTable() async {
    try {
      print('Setting up students table...');

      // Create the table structure
      await _createStudentsTable();

      // Test basic database connectivity
      await _testDatabaseConnection();

      print('Students table setup completed.');
    } catch (e) {
      print('Error setting up students table: $e');
    }
  }

  /// Test database connection and permissions
  Future<void> _testDatabaseConnection() async {
    try {
      print('Testing database connection...');

      // Test if we can query the table at all
      final testQuery = await _supabase
          .from('students')
          .select('registration_no')
          .limit(1);

      print('Database connection test result: $testQuery');

      // Test if we can insert a simple record
      final testInsert =
          await _supabase.from('students').insert({
            'registration_no': 'TEST001',
            'user_id': null,
            'year_of_joining': 2021,
            'current_year_of_study': 3,
            'current_semester': 5,
            'section': 'A',
            'department': 'Computer Science and Engineering',
            'batch': '2021-2025',
            'status': 'active',
          }).select();

      print('Test insert result: $testInsert');

      // Clean up test data
      await _supabase
          .from('students')
          .delete()
          .eq('registration_no', 'TEST001');
    } catch (e) {
      print('Database connection test failed: $e');
    }
  }

  /// Creates the students table structure
  Future<void> _createStudentsTable() async {
    try {
      // This will attempt to create the table via SQL
      await _supabase.rpc('create_students_table');
    } catch (e) {
      print(
        'Table creation via RPC failed (this is expected if table exists): $e',
      );
    }
  }

  /// Get students by department, semester, and section
  Future<List<Map<String, dynamic>>> getStudentsBySection({
    required String department,
    required int semester,
    required String section,
  }) async {
    try {
      print(
        'Loading students for department: $department, semester: $semester, section: $section',
      );

      final response = await _supabase
          .from('students')
          .select(
            'registration_no,user_id,year_of_joining,current_year_of_study,current_semester,section,department,batch,status',
          )
          .ilike(
            'department',
            department,
          ) // Use ilike for case-insensitive match
          .eq('current_semester', semester)
          .eq('section', section);

      print(
        'Loaded ${response.length} students for $department semester $semester section $section',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  /// Alternative method: Get all students and filter locally
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _supabase
          .from('students')
          .select(
            'registration_no,user_id,year_of_joining,current_year_of_study,current_semester,section,department,batch,status',
          );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all students: $e');
      // Return empty list if database query fails
      return [];
    }
  }
}
