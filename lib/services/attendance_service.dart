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

      // Use the new RPC function to get comprehensive attendance data
      final response = await _supabase.rpc(
        'get_student_attendance_summary',
        params: {'student_reg_no': cleanedRegNo},
      );

      if (response != null && response is List && response.isNotEmpty) {
        final attendanceData = response.first;
        print('Found attendance record: $attendanceData');

        // Format the response to match expected structure
        return {
          'registration_no': attendanceData['registration_no'],
          'department': attendanceData['department'],
          'current_semester': attendanceData['current_semester'],
          'section': attendanceData['section'],
          'total_classes': attendanceData['total_classes'] ?? 0,
          'present_classes': attendanceData['attended_classes'] ?? 0,
          'attendance_percentage': attendanceData['percentage'] ?? 0.0,
          'status': attendanceData['status_text'] ?? 'Unknown',
        };
      }

      print(
        'No attendance record found for registration number: $cleanedRegNo',
      );
      return null;
    } catch (error) {
      print('Error fetching attendance: $error');
      return null;
    }
  }

  // Get student's attendance using current user's linked account
  Future<Map<String, dynamic>?> getMyAttendance() async {
    try {
      // Get current user's student info first
      final studentInfo = await _supabase.rpc('get_my_student_info');

      if (studentInfo != null &&
          studentInfo is List &&
          studentInfo.isNotEmpty) {
        final regNo = studentInfo.first['registration_no'];
        return await getAttendanceByRegistrationNo(regNo);
      }

      return null;
    } catch (error) {
      print('Error fetching my attendance: $error');
      return null;
    }
  }

  // Get a list of all registration numbers for reference
  Future<List<Map<String, dynamic>>> getAllRegistrationNumbers() async {
    try {
      // Return registration numbers from students table
      final response = await _supabase
          .from('students')
          .select(
            'registration_no, department, current_semester, section, batch',
          );

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching registration numbers: $error');
      return [];
    }
  }

  // Get attendance summary report (for admin/faculty)
  Future<List<Map<String, dynamic>>> getAttendanceSummaryReport() async {
    try {
      final response =
          await _supabase.from('attendance_summary_report').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching attendance summary: $error');
      return [];
    }
  }

  // Update attendance percentage (for demo purposes)
  Future<bool> updateAttendancePercentage(
    String registrationNo,
    double percentage,
    int totalClasses,
    int attendedClasses,
  ) async {
    try {
      await _supabase.from('attendance').upsert({
        'registration_no': registrationNo,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'status': attendedClasses > (totalClasses * 0.5) ? 'present' : 'absent',
        'percentage': percentage,
        'total_classes': totalClasses,
        'attended_classes': attendedClasses,
      });

      return true;
    } catch (error) {
      print('Error updating attendance: $error');
      return false;
    }
  }

  // Get all students attendance for faculty/admin view
  Future<List<Map<String, dynamic>>> getAllStudentsAttendance({
    String? department,
    int? semester,
  }) async {
    try {
      print(
        'Fetching attendance data for department: $department, semester: $semester',
      );

      // Get all attendance records first since we have real data there
      final attendanceResponse = await _supabase
          .from('attendance')
          .select(
            'registration_no, percentage, total_classes, attended_classes, status',
          )
          .order('registration_no');

      if (attendanceResponse.isEmpty) {
        print('No attendance records found');
        return [];
      }

      print('Found ${attendanceResponse.length} attendance records');

      // If we need to filter by department or semester, try to join with students table
      // But if that fails, we'll still return the attendance data
      if (department != null || semester != null) {
        try {
          // Try to get students that match the criteria
          var studentsQuery = _supabase
              .from('students')
              .select('registration_no, department, current_semester');

          final studentsResponse = await studentsQuery;

          if (studentsResponse.isNotEmpty) {
            // Filter attendance based on students table data
            final filteredAttendance =
                attendanceResponse.where((attendance) {
                  final regNo = attendance['registration_no'];

                  // Find matching student record
                  final studentRecord = studentsResponse.firstWhere(
                    (student) => student['registration_no'] == regNo,
                    orElse: () => <String, dynamic>{},
                  );

                  if (studentRecord.isEmpty) return false;

                  // Apply filters
                  if (department != null && department.isNotEmpty) {
                    if (studentRecord['department'] != department) return false;
                  }

                  if (semester != null) {
                    if (studentRecord['current_semester'] != semester)
                      return false;
                  }

                  return true;
                }).toList();

            if (filteredAttendance.isNotEmpty) {
              return filteredAttendance.map<Map<String, dynamic>>((item) {
                return {
                  'registration_no': item['registration_no'],
                  'percentage': item['percentage'] ?? 0.0,
                  'total_classes': item['total_classes'] ?? 0,
                  'attended_classes': item['attended_classes'] ?? 0,
                  'status': item['status'],
                  'student_name': '', // No name column available
                  'department': department ?? '',
                  'semester': semester ?? 0,
                };
              }).toList();
            }
          }

          print(
            'No matching students found in students table, returning all attendance data',
          );
        } catch (e) {
          print(
            'Error filtering by students table: $e, returning all attendance data',
          );
        }
      }

      // Return all attendance data if no filtering or filtering failed
      return attendanceResponse.map<Map<String, dynamic>>((item) {
        return {
          'registration_no': item['registration_no'],
          'percentage': item['percentage'] ?? 0.0,
          'total_classes': item['total_classes'] ?? 0,
          'attended_classes': item['attended_classes'] ?? 0,
          'status': item['status'],
          'student_name': '', // No name column available
          'department': department ?? '',
          'semester': semester ?? 0,
        };
      }).toList();
    } catch (error) {
      print('Error fetching all students attendance: $error');
      // Return empty list on error
      return [];
    }
  }
}
