import 'package:supabase_flutter/supabase_flutter.dart';

class DataSetupService {
  final _supabase = Supabase.instance.client;

  // Sample student data to insert
  final List<Map<String, dynamic>> _attendanceRecords = [
    {
      'registration_no': '210823104027',
      'student_name': 'DEEPAK S',
      'total_working_days': 37,
      'days_absent': 9,
      'days_present': 28,
      'attendance_percentage': 75.7,
      'department': 'Computer Science Engineering',
      'semester': 4,
    },
    {
      'registration_no': '210823104022',
      'student_name': 'BOAZ K',
      'total_working_days': 37,
      'days_absent': 19,
      'days_present': 18,
      'attendance_percentage': 48.6,
      'department': 'Computer Science Engineering',
      'semester': 4,
    },
    {
      'registration_no': '210823104039',
      'student_name': 'GAYATHRI Kumar',
      'total_working_days': 37,
      'days_absent': 5,
      'days_present': 32,
      'attendance_percentage': 86.5,
      'department': 'Computer Science Engineering',
      'semester': 4,
    },
    {
      'registration_no': '210823104063',
      'student_name': 'KARTHIKEYAN D',
      'total_working_days': 37,
      'days_absent': 13,
      'days_present': 24,
      'attendance_percentage': 64.9,
      'department': 'Computer Science Engineering',
      'semester': 4,
    },
    {
      'registration_no': '210823104005',
      'student_name': 'ABISHEK PAULSON S',
      'total_working_days': 37,
      'days_absent': 6,
      'days_present': 31,
      'attendance_percentage': 83.8,
      'department': 'Computer Science Engineering',
      'semester': 4,
    },
  ];

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

      print(
        'Table is empty. Adding ${_attendanceRecords.length} sample records...',
      );

      // Insert records one by one to handle any errors
      int successCount = 0;

      for (final record in _attendanceRecords) {
        try {
          await _supabase.from('student_attendance').insert(record);
          successCount++;
          print('Inserted record for ${record['student_name']}');
        } catch (e) {
          print('Failed to insert record for ${record['student_name']}: $e');
        }
      }

      print(
        'Database setup complete. Successfully inserted $successCount records.',
      );
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
