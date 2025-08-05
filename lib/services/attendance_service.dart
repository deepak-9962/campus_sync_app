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

  // Get all students attendance for faculty/admin view (optimized)
  Future<List<Map<String, dynamic>>> getAllStudentsAttendance({
    String? department,
    int? semester,
  }) async {
    try {
      print(
        'Fetching attendance data for department: $department, semester: $semester',
      );

      // Use the optimized overall_attendance_summary table for better performance
      var query = _supabase
          .from('overall_attendance_summary')
          .select(
            'registration_no, department, semester, section, total_periods, attended_periods, overall_percentage, last_updated',
          );

      // Apply filters if provided
      if (department != null && department.isNotEmpty) {
        query = query.eq('department', department);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }

      final attendanceResponse = await query.order('registration_no');

      print('Optimized query returned ${attendanceResponse.length} records');

      if (attendanceResponse.isEmpty) {
        print('No attendance records found in summary table');
        return [];
      }

      // Get student names from students table
      final registrationNumbers =
          attendanceResponse
              .map((record) => record['registration_no'] as String)
              .toList();

      final studentsResponse = await _supabase
          .from('students')
          .select('registration_no, student_name')
          .inFilter('registration_no', registrationNumbers);

      // Create a map for quick name lookup
      final studentNamesMap = <String, String>{};
      for (final student in studentsResponse) {
        studentNamesMap[student['registration_no']] =
            student['student_name'] ?? '';
      }

      // Format the response
      return attendanceResponse.map<Map<String, dynamic>>((item) {
        return {
          'registration_no': item['registration_no'],
          'percentage': item['overall_percentage'] ?? 0.0,
          'total_classes': item['total_periods'] ?? 0,
          'attended_classes': item['attended_periods'] ?? 0,
          'status': _getAttendanceStatus(item['overall_percentage'] ?? 0.0),
          'student_name': studentNamesMap[item['registration_no']] ?? '',
          'department': item['department'] ?? department ?? '',
          'semester': item['semester'] ?? semester ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error in getAllStudentsAttendance: $e');
      return [];
    }
  }

  // Get today's attendance for faculty/admin view
  Future<List<Map<String, dynamic>>> getTodayAttendance({
    String? department,
    int? semester,
  }) async {
    try {
      final today =
          DateTime.now().toIso8601String().split(
            'T',
          )[0]; // Get today's date in YYYY-MM-DD format

      print(
        'Fetching today\'s attendance data for department: $department, semester: $semester, date: $today',
      );

      // Get today's attendance records with explicit ordering
      final attendanceResponse = await _supabase
          .from('attendance')
          .select(
            'id, registration_no, date, percentage, total_classes, attended_classes, status, created_at',
          )
          .eq('date', today)
          .order('registration_no')
          .order('created_at', ascending: false); // Get newest first

      print(
        'Raw today\'s attendance query returned ${attendanceResponse.length} records',
      );

      if (attendanceResponse.isEmpty) {
        print('No attendance records found for today');
        return [];
      }

      // Remove duplicates by keeping only the latest record for each registration_no for today
      final Map<String, Map<String, dynamic>> uniqueAttendance = {};

      for (final record in attendanceResponse) {
        final regNo = record['registration_no'];
        // Only keep the latest record per registration number for today
        if (!uniqueAttendance.containsKey(regNo)) {
          uniqueAttendance[regNo] = record;
        }
      }

      final deduplicatedList = uniqueAttendance.values.toList();
      print(
        'After deduplication: ${deduplicatedList.length} unique today\'s records',
      );

      // If we need to filter by department or semester, try to join with students table
      if (department != null || semester != null) {
        try {
          print('Attempting to filter today\'s data by department/semester...');

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
              'After filtering: ${filteredAttendance.length} today\'s records match criteria',
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
            'No matching students found in students table, returning all today\'s attendance data',
          );
        } catch (e) {
          print(
            'Error filtering today\'s data by students table: $e, returning all today\'s attendance data',
          );
        }
      }

      // Return all today's attendance data if no filtering or filtering failed
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
      print('Error fetching today\'s attendance: $error');
      // Return empty list on error
      return [];
    }
  }

  // Helper method to get attendance status based on percentage
  String _getAttendanceStatus(double percentage) {
    if (percentage >= 75) {
      return 'Regular';
    } else if (percentage >= 50) {
      return 'Irregular';
    } else {
      return 'Poor';
    }
  }

  // Mark period-wise attendance (for new schema)
  Future<bool> markPeriodAttendance({
    required String registrationNo,
    required String subjectCode,
    required int periodNumber,
    required bool isPresent,
    DateTime? date,
  }) async {
    try {
      final today = date ?? DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];

      print(
        'Marking period attendance: $registrationNo, Subject: $subjectCode, Period: $periodNumber, Present: $isPresent',
      );

      // Insert or update attendance record
      final response =
          await _supabase.from('attendance').upsert({
            'registration_no': registrationNo,
            'date': dateStr,
            'subject_code': subjectCode,
            'period_number': periodNumber,
            'is_present': isPresent,
            'marked_at': DateTime.now().toIso8601String(),
          }).select();

      if (response.isNotEmpty) {
        print('Period attendance marked successfully');
        return true;
      } else {
        print('Failed to mark period attendance');
        return false;
      }
    } catch (e) {
      print('Error marking period attendance: $e');
      return false;
    }
  }

  // Get today's period attendance for a subject
  Future<List<Map<String, dynamic>>> getTodayPeriodAttendance({
    required String subjectCode,
    required int periodNumber,
    String? department,
    int? semester,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      print(
        'Fetching today\'s period attendance for Subject: $subjectCode, Period: $periodNumber',
      );

      var query = _supabase
          .from('attendance')
          .select('registration_no, is_present')
          .eq('date', today)
          .eq('subject_code', subjectCode)
          .eq('period_number', periodNumber);

      final attendanceResponse = await query;

      if (attendanceResponse.isEmpty) {
        print('No period attendance records found');
        return [];
      }

      // Get student details
      final registrationNumbers =
          attendanceResponse
              .map((record) => record['registration_no'] as String)
              .toList();

      var studentQuery = _supabase
          .from('students')
          .select('registration_no, student_name, department, semester')
          .inFilter('registration_no', registrationNumbers);

      if (department != null && department.isNotEmpty) {
        studentQuery = studentQuery.eq('department', department);
      }
      if (semester != null) {
        studentQuery = studentQuery.eq('semester', semester);
      }

      final studentsResponse = await studentQuery;

      // Create a map for quick lookup
      final studentMap = <String, Map<String, dynamic>>{};
      for (final student in studentsResponse) {
        studentMap[student['registration_no']] = student;
      }

      // Combine attendance and student data
      return attendanceResponse
          .where(
            (attendance) =>
                studentMap.containsKey(attendance['registration_no']),
          )
          .map<Map<String, dynamic>>((attendance) {
            final regNo = attendance['registration_no'];
            final student = studentMap[regNo]!;

            return {
              'registration_no': regNo,
              'student_name': student['student_name'] ?? '',
              'department': student['department'] ?? '',
              'semester': student['semester'] ?? 0,
              'is_present': attendance['is_present'] ?? false,
              'subject_code': subjectCode,
              'period_number': periodNumber,
            };
          })
          .toList();
    } catch (e) {
      print('Error fetching today\'s period attendance: $e');
      return [];
    }
  }

  // Get subjects for a department and semester
  Future<List<Map<String, dynamic>>> getSubjects({
    String? department,
    int? semester,
  }) async {
    try {
      var query = _supabase
          .from('subjects')
          .select('subject_code, subject_name, department, semester');

      if (department != null && department.isNotEmpty) {
        query = query.eq('department', department);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }

      final response = await query.order('subject_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  // Get class schedule for a specific day
  Future<List<Map<String, dynamic>>> getClassSchedule({
    String? department,
    int? semester,
    String? dayOfWeek,
  }) async {
    try {
      var query = _supabase.from('class_schedule').select('''
        period_number, 
        subject_code, 
        subjects(subject_name),
        day_of_week,
        start_time,
        end_time,
        department,
        semester
      ''');

      if (department != null && department.isNotEmpty) {
        query = query.eq('department', department);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }
      if (dayOfWeek != null) {
        query = query.eq('day_of_week', dayOfWeek);
      }

      final response = await query.order('period_number');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching class schedule: $e');
      return [];
    }
  }
}
