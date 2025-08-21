import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;
  // Toggle for verbose attendance logs
  static const bool _verboseAttendanceLogs = false;

  Future<Map<String, dynamic>?> getAttendanceByRegistrationNo(
    String registrationNo,
  ) async {
    try {
      // Clean up input - remove whitespace and # symbol if present
      final cleanedRegNo = registrationNo.trim().replaceAll('#', '');

      print('Searching for registration number: $cleanedRegNo');

      // Query overall summary table that matches current schema
      final summaryResponse = await _supabase
          .from('overall_attendance_summary')
          .select(
            'registration_no, department, semester, section, total_periods, attended_periods, overall_percentage, last_updated',
          )
          .eq('registration_no', cleanedRegNo)
          .limit(1);

      if (summaryResponse.isNotEmpty) {
        final s = summaryResponse.first;
        // Enrich with student name
        String studentName = '';
        try {
          final studentResp = await _supabase
              .from('students')
              .select('student_name')
              .eq('registration_no', cleanedRegNo)
              .limit(1);
          if (studentResp.isNotEmpty) {
            studentName = studentResp.first['student_name'] ?? '';
          }
        } catch (_) {}

        return {
          'registration_no': s['registration_no'],
          'student_name': studentName,
          'department': s['department'],
          // Map schema's semester to expected current_semester field
          'current_semester': s['semester'],
          'section': s['section'],
          'total_classes': s['total_periods'] ?? 0,
          'present_classes': s['attended_periods'] ?? 0,
          'attendance_percentage': s['overall_percentage'] ?? 0.0,
          'status': _getStatusText(s['overall_percentage'] ?? 0.0),
        };
      }

      print(
        'No attendance summary found for registration number: $cleanedRegNo',
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
          'Registration number exists in students table but no summary data found',
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

      // Apply filters if provided (case-insensitive for department)
      if (department != null && department.isNotEmpty) {
        query = query.ilike(
          'department',
          department,
        ); // ILIKE matches ignoring case
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }

      final attendanceResponse = await query.order('registration_no');

      print('Optimized query returned ${attendanceResponse.length} records');

      if (attendanceResponse.isEmpty) {
        print('No attendance records found in summary table');
        try {
          final depts = await _supabase
              .from('overall_attendance_summary')
              .select('department')
              .order('department');
          final distinct = {
            for (final d in depts) (d['department'] ?? '').toString(),
          }..removeWhere((e) => e.isEmpty);
          print('Existing departments in summary table: $distinct');
        } catch (e2) {
          print('Could not fetch existing departments: $e2');
        }
        return [];
      }

      // Build registration list and resolve names (prefer users.name via students.user_id)
      final registrationNumbers =
          attendanceResponse
              .map((record) => record['registration_no'] as String)
              .toList();

      final studentsResponse = await _supabase
          .from('students')
          .select('registration_no, student_name, user_id')
          .inFilter('registration_no', registrationNumbers);

      // Fetch user names for linked user_ids
      final userIds =
          studentsResponse
              .map((s) => s['user_id'])
              .where((id) => id != null)
              .toSet()
              .toList();
      Map<String, String> userNameById = {};
      if (userIds.isNotEmpty) {
        final usersResp = await _supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds);
        for (final u in usersResp) {
          if (u['id'] != null) userNameById[u['id']] = u['name'] ?? '';
        }
      }

      // Create a map for quick name lookup (prefer users.name)
      final studentNamesMap = <String, String>{};
      for (final student in studentsResponse) {
        final reg = student['registration_no'];
        final uid = student['user_id'];
        final usersName = uid != null ? (userNameById[uid] ?? '') : '';
        final fallback = student['student_name'] ?? '';
        studentNamesMap[reg] =
            usersName.toString().trim().isNotEmpty ? usersName : fallback;
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

  // New: fetch overall analytics from attendance_analytics view (includes names already)
  Future<List<Map<String, dynamic>>> getOverallAttendanceAnalytics({
    String? department,
    int? semester,
  }) async {
    try {
      print('Fetching analytics view for dept=$department sem=$semester');
      var query = _supabase.from('attendance_analytics').select();
      if (department != null && department.isNotEmpty) {
        query = query.ilike('department', department);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }
      final resp = await query.order('registration_no');
      print('Analytics view returned ${resp.length} rows');
      return List<Map<String, dynamic>>.from(
        resp.map(
          (r) => {
            'registration_no': r['registration_no'],
            'student_name': r['student_name'],
            // unify field names expected by UI
            'percentage': r['overall_percentage'] ?? r['percentage'] ?? 0.0,
            'total_classes': r['total_periods'] ?? 0,
            'attended_classes': r['attended_periods'] ?? 0,
            'status': r['attendance_status'],
            'department': r['department'],
            'semester': r['semester'],
          },
        ),
      );
    } catch (e) {
      print('Error loading attendance_analytics view: $e');
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

      // Build a list of registration numbers to enrich with student names and metadata
      final registrationNumbers =
          deduplicatedList
              .map((record) => record['registration_no'] as String)
              .toList();

      Map<String, Map<String, dynamic>> studentMap = {};
      // Enrich with names: prefer users.name via students.user_id, fallback to students.student_name
      try {
        final studentsResponse = await _supabase
            .from('students')
            .select(
              'registration_no, student_name, user_id, department, current_semester',
            )
            .inFilter('registration_no', registrationNumbers);

        // Map students and collect user_ids
        final Set<String> userIds = {};
        for (final s in studentsResponse) {
          studentMap[s['registration_no']] = s;
          final uid = s['user_id'];
          if (uid != null && uid.toString().trim().isNotEmpty) {
            userIds.add(uid as String);
          }
        }

        // Fetch user names
        final Map<String, String> userNameById = {};
        if (userIds.isNotEmpty) {
          final usersResp = await _supabase
              .from('users')
              .select('id, name')
              .inFilter('id', userIds.toList());
          for (final u in usersResp) {
            final id = u['id'] as String?;
            if (id != null) userNameById[id] = (u['name'] ?? '').toString();
          }
        }

        // Attach resolved names onto studentMap entries for easy access later
        for (final entry in studentMap.entries) {
          final uid = entry.value['user_id'] as String?;
          final usersName = uid != null ? (userNameById[uid] ?? '') : '';
          final fallback = (entry.value['student_name'] ?? '').toString();
          entry.value['resolved_name'] =
              usersName.trim().isNotEmpty ? usersName : fallback;
        }
      } catch (e) {
        if (kDebugMode && _verboseAttendanceLogs) {
          debugPrint('Name enrichment failed for today list: $e');
        }
      }

      // If we need to filter by department or semester, filter based on students table
      List<Map<String, dynamic>> workingList = deduplicatedList;
      if (department != null || semester != null) {
        workingList =
            deduplicatedList.where((attendance) {
              final regNo = attendance['registration_no'] as String;
              final student = studentMap[regNo];
              if (student == null) return false; // cannot determine cohort
              if (department != null && department.isNotEmpty) {
                if (student['department'] != department) return false;
              }
              if (semester != null) {
                if (student['current_semester'] != semester) return false;
              }
              return true;
            }).toList();
      }

      // Return enriched list (with names)
      return workingList.map<Map<String, dynamic>>((item) {
        final regNo = item['registration_no'] as String;
        final student = studentMap[regNo];
        return {
          'registration_no': regNo,
          'percentage': item['percentage'] ?? 0.0,
          'total_classes': item['total_classes'] ?? 0,
          'attended_classes': item['attended_classes'] ?? 0,
          'status': item['status'],
          'student_name':
              student != null
                  ? ((student['resolved_name'] ?? student['student_name'] ?? '')
                      .toString())
                  : '',
          'department':
              department ??
              (student != null ? (student['department'] ?? '') : ''),
          'semester':
              semester ??
              (student != null ? (student['current_semester'] ?? 0) : 0),
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
    String? department,
    int? semester,
    String? section,
  }) async {
    try {
      final today = date ?? DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];

      if (kDebugMode && _verboseAttendanceLogs) {
        print(
          'Marking period attendance: $registrationNo, Subject: $subjectCode, Period: $periodNumber, Present: $isPresent',
        );
      }

      final currentUserId = _supabase.auth.currentUser?.id;

      // Insert or update attendance record
      final Map<String, dynamic> payload = {
        'registration_no': registrationNo,
        'date': dateStr,
        'subject_code': subjectCode,
        'period_number': periodNumber,
        'is_present': isPresent,
        'marked_at': DateTime.now().toIso8601String(),
        'marked_by': currentUserId,
      };

      // Include class metadata when available to avoid NULLs downstream
      if (department != null) payload['department'] = department;
      if (semester != null) payload['semester'] = semester;
      if (section != null) payload['section'] = section;

      try {
        // First, check if student exists in the proper department and semester
        await _supabase
            .from('students')
            .select('registration_no')
            .eq('registration_no', registrationNo)
            .single();

        // Now insert/update the attendance record
        await _supabase
            .from('attendance')
            .upsert({
              'registration_no': registrationNo,
              'date': dateStr,
              'subject_code': subjectCode,
              'period_number': periodNumber,
              'is_present': isPresent,
              'marked_at': DateTime.now().toIso8601String(),
              'marked_by': currentUserId,
              'department': department,
              'semester': semester,
              'section': section,
            })
            .select()
            .single();

        if (kDebugMode && _verboseAttendanceLogs) {
          print('Period attendance marked successfully');
        }
        return true;
      } on PostgrestException catch (e) {
        if (kDebugMode) {
          if (e.code == 'PGRST116') {
            print('Student not found: $registrationNo');
          } else {
            print('Failed to mark period attendance: ${e.message}');
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking period attendance: $e');
      }
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

      if (kDebugMode && _verboseAttendanceLogs) {
        debugPrint(
          'Fetching today\'s period attendance for Subject: $subjectCode, Period: $periodNumber',
        );
      }

      var query = _supabase
          .from('attendance')
          .select('registration_no, is_present')
          .eq('date', today)
          .eq('subject_code', subjectCode)
          .eq('period_number', periodNumber);

      final attendanceResponse = await query;

      if (attendanceResponse.isEmpty) {
        if (kDebugMode && _verboseAttendanceLogs) {
          debugPrint('No period attendance records found');
        }
        return [];
      }

      // Get student details
      final registrationNumbers =
          attendanceResponse
              .map((record) => record['registration_no'] as String)
              .toList();

      var studentQuery = _supabase
          .from('students')
          .select(
            'registration_no, student_name, department, semester, current_semester, section',
          )
          .inFilter('registration_no', registrationNumbers);

      final studentsResponse = await studentQuery;

      // Create a map for quick lookup
      final studentMap = <String, Map<String, dynamic>>{};
      for (final student in studentsResponse) {
        studentMap[student['registration_no']] = student;
      }

      // Combine attendance and student data without dropping records
      final List<Map<String, dynamic>> combined = [];
      for (final a in attendanceResponse) {
        final regNo = a['registration_no'] as String;
        final student = studentMap[regNo];

        // Apply optional filters when we have student metadata
        if (semester != null && student != null) {
          final sem = student['semester'] ?? student['current_semester'];
          if (sem != semester) continue;
        }
        // If semester filter provided but no student metadata, keep the record (do not drop silently)

        combined.add({
          'registration_no': regNo,
          'student_name':
              student != null ? (student['student_name'] ?? '') : '',
          'department':
              student != null
                  ? (student['department'] ?? '')
                  : (department ?? ''),
          'semester':
              student != null
                  ? (student['semester'] ?? student['current_semester'] ?? 0)
                  : (semester ?? 0),
          'is_present': a['is_present'] ?? false,
          'subject_code': subjectCode,
          'period_number': periodNumber,
        });
      }
      return combined;
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

  // New: Resolve the class (subject + staff) scheduled for a specific date & period
  Future<Map<String, dynamic>?> getPeriodClassInfo({
    required String department,
    required int semester,
    required String section,
    required DateTime date,
    required int periodNumber,
  }) async {
    try {
      final weekday = _weekdayString(date).toLowerCase();
      // Query class_schedule join subjects for name + faculty
      final resp =
          await _supabase
              .from('class_schedule')
              .select(
                'subject_code, faculty_name, subjects(subject_name, faculty_name)',
              )
              .eq('department', department)
              .eq('semester', semester)
              .eq('section', section)
              .eq('day_of_week', weekday)
              .eq('period_number', periodNumber)
              .maybeSingle();
      if (resp == null) return null;
      String? subjectName;
      String? staffName;
      if (resp['subjects'] != null) {
        subjectName = resp['subjects']['subject_name'];
        staffName = resp['subjects']['faculty_name'];
      }
      // Prefer explicit faculty_name stored on class_schedule row
      if ((resp['faculty_name'] ?? '').toString().trim().isNotEmpty) {
        staffName = resp['faculty_name'];
      }
      return {
        'subject_code': resp['subject_code'],
        'subject_name': subjectName ?? resp['subject_code'],
        'staff_name': staffName,
      };
    } catch (e) {
      print('Error resolving period class info: $e');
      return null;
    }
  }

  String _weekdayString(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      default:
        return 'sunday';
    }
  }

  // Mark day-wise attendance (for full day present/absent)
  Future<bool> markDayAttendance({
    required String registrationNo,
    required bool isPresent,
    DateTime? date,
  }) async {
    try {
      final today = date ?? DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];

      print(
        'Marking day attendance: $registrationNo, Present: $isPresent, Date: $dateStr',
      );

      final currentUserId = _supabase.auth.currentUser?.id;

      // Insert or update day attendance record
      final response =
          await _supabase.from('daily_attendance').upsert({
            'registration_no': registrationNo,
            'date': dateStr,
            'is_present': isPresent,
            'marked_at': DateTime.now().toIso8601String(),
            'marked_by': currentUserId,
          }).select();

      if (response.isNotEmpty) {
        print('Day attendance marked successfully');
        return true;
      } else {
        print('Failed to mark day attendance');
        return false;
      }
    } catch (e) {
      print('Error marking day attendance: $e');
      return false;
    }
  }

  // Get attendance records for a specific date (period-wise)
  Future<List<Map<String, dynamic>>> getAttendanceForDate(
    String department,
    int semester,
    String section,
    DateTime date,
  ) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('attendance')
          .select('''
            registration_no,
            is_present,
            subject_name,
            period,
            marked_at,
            marked_by
          ''')
          .eq('date', dateStr)
          .order('registration_no');

      // Add student names
      List<Map<String, dynamic>> attendanceWithNames = [];
      for (var record in response) {
        final studentResponse = await _supabase
            .from('students')
            .select('student_name')
            .eq('registration_no', record['registration_no'])
            .limit(1);

        final studentName =
            studentResponse.isNotEmpty
                ? studentResponse.first['student_name']
                : 'Unknown';

        attendanceWithNames.add({...record, 'student_name': studentName});
      }

      return attendanceWithNames;
    } catch (e) {
      print('Error getting attendance for date: $e');
      return [];
    }
  }

  // Get daily attendance records for a specific date
  Future<List<Map<String, dynamic>>> getDailyAttendanceForDate(
    String department,
    int semester,
    String section,
    DateTime date,
  ) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_attendance')
          .select('''
            registration_no,
            is_present,
            marked_at,
            marked_by
          ''')
          .eq('date', dateStr)
          .order('registration_no');

      if (response.isEmpty) return [];

      // Build list of registration numbers and a normalized (trimmed, upper) index
      final regs = <String>[];
      for (final r in response) {
        final reg = (r['registration_no'] as String?)?.trim() ?? '';
        if (reg.isNotEmpty) regs.add(reg);
      }

      Map<String, String> nameMap = {};
      if (regs.isNotEmpty) {
        try {
          final students = await _supabase
              .from('students')
              .select('registration_no, student_name, user_id')
              .inFilter('registration_no', regs);

          // Collect user_ids
          final Set<String> userIds = {};
          for (final s in students) {
            final uid = s['user_id'];
            if (uid != null && uid.toString().trim().isNotEmpty) {
              userIds.add(uid as String);
            }
          }

          // Fetch users
          final Map<String, String> userNameById = {};
          if (userIds.isNotEmpty) {
            final usersResp = await _supabase
                .from('users')
                .select('id, name')
                .inFilter('id', userIds.toList());
            for (final u in usersResp) {
              final id = u['id'] as String?;
              if (id != null) userNameById[id] = (u['name'] ?? '').toString();
            }
          }

          for (final s in students) {
            final key = (s['registration_no'] as String?)?.trim() ?? '';
            if (key.isNotEmpty) {
              final uid = s['user_id'] as String?;
              final usersName = uid != null ? (userNameById[uid] ?? '') : '';
              final fallback = (s['student_name'] ?? '').toString();
              final resolved =
                  usersName.trim().isNotEmpty ? usersName : fallback;
              nameMap[key.toUpperCase()] = resolved;
            }
          }
        } catch (e) {
          if (kDebugMode && _verboseAttendanceLogs) {
            debugPrint('Daily name enrichment failed: $e');
          }
        }
      }

      // Merge names into attendance list
      final enriched =
          response.map<Map<String, dynamic>>((rec) {
            final reg = ((rec['registration_no'] as String?) ?? '').trim();
            final name = nameMap[reg.toUpperCase()] ?? '';
            return {...rec, 'registration_no': reg, 'student_name': name};
          }).toList();

      return enriched;
    } catch (e) {
      print('Error getting daily attendance for date: $e');
      return [];
    }
  }

  // Fallback: derive daily attendance from period records for a date
  Future<List<Map<String, dynamic>>> getDerivedDailyFromPeriods({
    required String department,
    required int semester,
    required String section,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Fetch period records for the date
      final periodRows = await _supabase
          .from('attendance')
          .select('registration_no, is_present')
          .eq('date', dateStr);

      if (periodRows.isEmpty) return [];

      // Group by student and compute totals
      final Map<String, Map<String, int>> agg = {};
      for (final row in periodRows) {
        final reg = row['registration_no'] as String;
        final present = (row['is_present'] as bool?) ?? false;
        final entry = agg.putIfAbsent(reg, () => {'total': 0, 'present': 0});
        entry['total'] = (entry['total'] ?? 0) + 1;
        if (present) entry['present'] = (entry['present'] ?? 0) + 1;
      }

      final regs = agg.keys.toList();
      if (regs.isEmpty) return [];

      // Join with students to filter by sem/section and get names
      final students = await _supabase
          .from('students')
          .select(
            'registration_no, student_name, user_id, department, semester, current_semester, section',
          )
          .inFilter('registration_no', regs);

      // Fetch user names for linked accounts
      final Set<String> userIds = {
        for (final s in students)
          if (s['user_id'] != null && s['user_id'].toString().trim().isNotEmpty)
            s['user_id'] as String,
      };
      final Map<String, String> userNameById = {};
      if (userIds.isNotEmpty) {
        final usersResp = await _supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds.toList());
        for (final u in usersResp) {
          final id = u['id'] as String?;
          if (id != null) userNameById[id] = (u['name'] ?? '').toString();
        }
      }

      final Map<String, Map<String, dynamic>> studentMap = {
        for (final s in students)
          s['registration_no'] as String: {
            ...s,
            'resolved_name': () {
              final uid = s['user_id'] as String?;
              final usersName = uid != null ? (userNameById[uid] ?? '') : '';
              final fallback = (s['student_name'] ?? '').toString();
              return usersName.trim().isNotEmpty ? usersName : fallback;
            }(),
          },
      };

      final List<Map<String, dynamic>> results = [];
      for (final reg in regs) {
        final s = studentMap[reg];
        if (s == null) continue; // require metadata to place in a section
        // Filter by semester and section
        final sem = s['semester'] ?? s['current_semester'];
        if (sem != semester) continue;
        final sec = (s['section'] as String?)?.toUpperCase();
        if (sec != section.toUpperCase()) continue;

        final counts = agg[reg]!;
        final total = counts['total'] ?? 0;
        final present = counts['present'] ?? 0;

        results.add({
          'registration_no': reg,
          'student_name':
              (s['resolved_name'] ?? s['student_name'] ?? '').toString(),
          'is_present': present >= (total / 2), // simple majority heuristic
          'marked_at': null,
          'marked_by': null,
        });
      }

      return results;
    } catch (e) {
      print('Error deriving daily from periods: $e');
      return [];
    }
  }

  // Get period attendance for a specific date
  Future<List<Map<String, dynamic>>> getPeriodAttendanceForDate({
    required String subjectCode,
    required int periodNumber,
    required DateTime date,
    String? department,
    int? semester,
    String? section,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      if (kDebugMode && _verboseAttendanceLogs) {
        debugPrint(
          'Fetching period attendance for Subject: $subjectCode, Period: $periodNumber, Date: $dateStr',
        );
      }

      // First check if attendance exists for this subject and period
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('''
            registration_no,
            is_present,
            date,
            subject_code,
            period_number
          ''')
          .eq('date', dateStr)
          .eq('subject_code', subjectCode)
          .eq('period_number', periodNumber);

      if (attendanceResponse.isEmpty) {
        if (kDebugMode && _verboseAttendanceLogs) {
          debugPrint('No period attendance records found for $dateStr');
        }
        return [];
      }

      final registrationNumbers =
          attendanceResponse
              .map((record) => record['registration_no'] as String)
              .toList();

      var studentQuery = _supabase
          .from('students')
          .select(
            'registration_no, student_name, user_id, department, semester, current_semester, section',
          )
          .inFilter('registration_no', registrationNumbers);
      // Avoid filtering by semester at SQL level due to schema variations; filter in Dart below

      final studentsResponse = await studentQuery;

      // Fetch user names for linked user_ids
      final Set<String> userIds = {
        for (final s in studentsResponse)
          if (s['user_id'] != null && s['user_id'].toString().trim().isNotEmpty)
            s['user_id'] as String,
      };
      final Map<String, String> userNameById = {};
      if (userIds.isNotEmpty) {
        final usersResp = await _supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds.toList());
        for (final u in usersResp) {
          final id = u['id'] as String?;
          if (id != null) userNameById[id] = (u['name'] ?? '').toString();
        }
      }

      final studentMap = <String, Map<String, dynamic>>{};
      for (final student in studentsResponse) {
        final uid = student['user_id'] as String?;
        final usersName = uid != null ? (userNameById[uid] ?? '') : '';
        final fallback = (student['student_name'] ?? '').toString();
        studentMap[student['registration_no']] = {
          ...student,
          'resolved_name': usersName.trim().isNotEmpty ? usersName : fallback,
        };
      }

      final List<Map<String, dynamic>> results = [];
      for (final attendance in attendanceResponse) {
        final regNo = attendance['registration_no'] as String;
        final student = studentMap[regNo];

        // Apply filters when metadata exists; if missing, don't drop the record
        if (student != null) {
          if (semester != null) {
            final sem = student['semester'];
            final currSem = student['current_semester'];
            final matchesSemester = (sem == semester) || (currSem == semester);
            if (!matchesSemester) continue;
          }
          if (section != null && section.isNotEmpty) {
            final sec = (student['section'] as String?)?.toUpperCase();
            if (sec != section.toUpperCase()) continue;
          }
        }

        results.add({
          'registration_no': regNo,
          'student_name':
              student != null
                  ? ((student['resolved_name'] ?? student['student_name'] ?? '')
                      .toString())
                  : '',
          'department':
              student != null
                  ? (student['department'] ?? '')
                  : (department ?? ''),
          'semester':
              student != null
                  ? (student['semester'] ?? student['current_semester'] ?? 0)
                  : (semester ?? 0),
          'section':
              student != null ? (student['section'] ?? '') : (section ?? ''),
          'is_present': attendance['is_present'] ?? false,
          'subject_code': subjectCode,
          'period_number': periodNumber,
          'date': dateStr,
        });
      }
      return results;
    } catch (e) {
      print('Error fetching period attendance for date: $e');
      return [];
    }
  }
}
