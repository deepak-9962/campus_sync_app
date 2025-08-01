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

      // Query attendance table directly
      final attendanceResponse = await _supabase
          .from('attendance')
          .select(
            'registration_no, percentage, total_classes, attended_classes, status, date',
          )
          .eq('registration_no', cleanedRegNo)
          .order('date', ascending: false) // Get latest record first
          .limit(1);

      if (attendanceResponse.isNotEmpty) {
        final attendanceData = attendanceResponse.first;
        print('Found attendance record: $attendanceData');

        // Try to get student info from students table
        final studentResponse = await _supabase
            .from('students')
            .select('registration_no, department, current_semester, section')
            .eq('registration_no', cleanedRegNo)
            .limit(1);

        String department = '';
        int currentSemester = 0;
        String section = '';

        if (studentResponse.isNotEmpty) {
          final studentData = studentResponse.first;
          department = studentData['department'] ?? '';
          currentSemester = studentData['current_semester'] ?? 0;
          section = studentData['section'] ?? '';
        }

        // Format the response to match expected structure
        return {
          'registration_no': attendanceData['registration_no'],
          'department': department,
          'current_semester': currentSemester,
          'section': section,
          'total_classes': attendanceData['total_classes'] ?? 0,
          'present_classes': attendanceData['attended_classes'] ?? 0,
          'attendance_percentage': attendanceData['percentage'] ?? 0.0,
          'status': _getStatusText(attendanceData['percentage'] ?? 0.0),
        };
      }

      print(
        'No attendance record found for registration number: $cleanedRegNo',
      );

      // Also check if the registration number exists in students table
      final studentCheck = await _supabase
          .from('students')
          .select('registration_no')
          .eq('registration_no', cleanedRegNo)
          .limit(1);

      if (studentCheck.isEmpty) {
        print(
          'Registration number $cleanedRegNo does not exist in students table',
        );
      } else {
        print(
          'Registration number exists in students table but no attendance data found',
        );
      }

      return null;
    } catch (error) {
      print('Error fetching attendance: $error');
      return null;
    }
  }

  // Helper method to get status text based on percentage
  String _getStatusText(double percentage) {
    if (percentage >= 90)
      return 'Excellent (${percentage.toStringAsFixed(1)}%)';
    if (percentage >= 75) return 'Good (${percentage.toStringAsFixed(1)}%)';
    if (percentage >= 60) return 'Average (${percentage.toStringAsFixed(1)}%)';
    return 'Below Average (${percentage.toStringAsFixed(1)}%)';
  }

  // Get student's attendance using current user's linked account
  Future<Map<String, dynamic>?> getMyAttendance() async {
    try {
      // First try to get attendance using email-based registration number
      final emailBasedAttendance = await getAttendanceFromEmail();
      if (emailBasedAttendance != null) {
        return emailBasedAttendance;
      }

      // Fallback to linked account method
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

  // Extract registration number from email and get attendance
  Future<Map<String, dynamic>?> getAttendanceFromEmail() async {
    try {
      // Get current user's email
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        print('No user logged in or no email found');
        return null;
      }

      final email = user.email!;
      print('Current user email: $email');

      // Extract registration number from email
      // For emails like "210823104027@kingsedu.ac.in"
      final registrationNo = extractRegistrationFromEmail(email);

      if (registrationNo == null) {
        print('Could not extract registration number from email: $email');
        return null;
      }

      print(
        'Extracted registration number: $registrationNo from email: $email',
      );

      // Get attendance using the extracted registration number
      return await getAttendanceByRegistrationNo(registrationNo);
    } catch (error) {
      print('Error getting attendance from email: $error');
      return null;
    }
  }

  // Extract registration number from email address
  String? extractRegistrationFromEmail(String email) {
    try {
      // Split email by @ symbol
      final parts = email.split('@');
      if (parts.length != 2) {
        return null;
      }

      final localPart = parts[0]; // Part before @
      final domain = parts[1]; // Part after @

      // Check if domain is kingsedu.ac.in or similar educational domain
      if (!domain.toLowerCase().contains('kingsedu') &&
          !domain.toLowerCase().contains('edu')) {
        print('Email domain $domain does not appear to be educational');
        // Still try to extract registration number in case it's a valid format
      }

      // Check if local part looks like a registration number
      // Registration numbers typically:
      // - Start with year (20xx or 21xx)
      // - Have numeric digits
      // - Are 10-12 characters long
      final regNoPattern = RegExp(r'^(20|21)\d{8,10}$');

      if (regNoPattern.hasMatch(localPart)) {
        return localPart;
      }

      // Alternative pattern for different registration formats
      final altPattern = RegExp(r'^\d{10,12}$');
      if (altPattern.hasMatch(localPart)) {
        return localPart;
      }

      print('Local part $localPart does not match registration number pattern');
      return null;
    } catch (error) {
      print('Error extracting registration number from email: $error');
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

      // Get all attendance records with explicit ordering to handle duplicates
      final attendanceResponse = await _supabase
          .from('attendance')
          .select(
            'id, registration_no, date, percentage, total_classes, attended_classes, status, created_at',
          )
          .order('registration_no')
          .order('created_at', ascending: false); // Get newest first

      print(
        'Raw attendance query returned ${attendanceResponse.length} records',
      );

      if (attendanceResponse.isEmpty) {
        print('No attendance records found in database');
        return [];
      }

      // Remove duplicates by keeping only the latest record for each registration_no + date
      final Map<String, Map<String, dynamic>> uniqueAttendance = {};

      for (final record in attendanceResponse) {
        final key = '${record['registration_no']}_${record['date']}';
        if (!uniqueAttendance.containsKey(key)) {
          uniqueAttendance[key] = record;
        }
      }

      final deduplicatedList = uniqueAttendance.values.toList();
      print('After deduplication: ${deduplicatedList.length} unique records');

      // If we need to filter by department or semester, try to join with students table
      if (department != null || semester != null) {
        try {
          print('Attempting to filter by department/semester...');

          // Try to get students that match the criteria
          var studentsQuery = _supabase
              .from('students')
              .select('registration_no, department, current_semester');

          final studentsResponse = await studentsQuery;
          print('Found ${studentsResponse.length} students in students table');

          if (studentsResponse.isNotEmpty) {
            // Filter attendance based on students table data
            final filteredAttendance =
                deduplicatedList.where((attendance) {
                  final regNo = attendance['registration_no'];

                  // Find matching student record
                  final studentRecord = studentsResponse.firstWhere(
                    (student) => student['registration_no'] == regNo,
                    orElse: () => <String, dynamic>{},
                  );

                  if (studentRecord.isEmpty) {
                    print('No student record found for $regNo');
                    return false;
                  }

                  // Apply filters
                  if (department != null && department.isNotEmpty) {
                    if (studentRecord['department'] != department) {
                      print(
                        'Department mismatch for $regNo: ${studentRecord['department']} != $department',
                      );
                      return false;
                    }
                  }

                  if (semester != null) {
                    if (studentRecord['current_semester'] != semester) {
                      print(
                        'Semester mismatch for $regNo: ${studentRecord['current_semester']} != $semester',
                      );
                      return false;
                    }
                  }

                  return true;
                }).toList();

            print(
              'After filtering: ${filteredAttendance.length} records match criteria',
            );

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
      return deduplicatedList.map<Map<String, dynamic>>((item) {
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
