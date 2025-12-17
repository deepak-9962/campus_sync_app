import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getAttendanceByRegistrationNo(
    String registrationNo,
  ) async {
    try {
      // Clean up input - remove whitespace and # symbol if present
      final cleanedRegNo = registrationNo.trim().replaceAll('#', '');

      print('Searching for registration number: $cleanedRegNo');

      // Query the database for attendance record
      final response =
          await _supabase
              .from('student_attendance')
              .select()
              .eq('registration_no', cleanedRegNo)
              .maybeSingle();

      if (response != null) {
        print('Found record: $response');
        return response;
      }

      print('No record found with registration number: $cleanedRegNo');
      return null;
    } catch (error) {
      print('Error fetching attendance: $error');
      return null;
    }
  }

  // Get a list of all registration numbers for reference
  Future<List<Map<String, dynamic>>> getAllRegistrationNumbers() async {
    try {
      // Return registration numbers, names, department, semester, and section from database
      final response = await _supabase
          .from('student_attendance')
          .select('registration_no,student_name,department,semester,section');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching registration numbers: $error');
      return [];
    }
  }
}
