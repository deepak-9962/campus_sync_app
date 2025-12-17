import 'package:supabase_flutter/supabase_flutter.dart';
import 'attendance_service.dart';

class HODService {
  final _supabase = Supabase.instance.client;
  final _attendanceService = AttendanceService();

  /// Check if the current user is an HOD
  Future<bool> isUserHOD() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department')
              .eq('id', user.id)
              .maybeSingle();

      return response != null && response['role'] == 'hod';
    } catch (e) {
      print('Error checking HOD status: $e');
      return false;
    }
  }

  /// Get HOD information for the current user
  Future<Map<String, dynamic>?> getHODInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('users')
              .select('name, email, role, assigned_department')
              .eq('id', user.id)
              .eq('role', 'hod')
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting HOD info: $e');
      return null;
    }
  }

  /// Create a new HOD user
  Future<bool> createHODUser({
    required String email,
    required String name,
    required String department,
    required String password,
  }) async {
    try {
      // Create auth user first
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('Failed to create auth user');
        return false;
      }

      // Create user profile with HOD role
      await _supabase.from('users').insert({
        'id': authResponse.user!.id,
        'name': name,
        'email': email,
        'role': 'hod',
        'assigned_department': department,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error creating HOD user: $e');
      return false;
    }
  }

  /// Update HOD's assigned department
  Future<bool> updateHODDepartment({
    required String userId,
    required String newDepartment,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({'assigned_department': newDepartment})
          .eq('id', userId)
          .eq('role', 'hod');

      return true;
    } catch (e) {
      print('Error updating HOD department: $e');
      return false;
    }
  }

  /// Get all HOD users (admin only)
  Future<List<Map<String, dynamic>>> getAllHODs() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, assigned_department, created_at')
          .eq('role', 'hod')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all HODs: $e');
      return [];
    }
  }

  /// Check if user has permission to view department data
  Future<bool> canViewDepartmentData(String department) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) return false;

      // Admin can view all departments
      if (response['is_admin'] == true || response['role'] == 'admin') {
        return true;
      }

      // HOD can view only their assigned department
      if (response['role'] == 'hod') {
        return response['assigned_department'] == department;
      }

      return false;
    } catch (e) {
      print('Error checking department view permission: $e');
      return false;
    }
  }

  /// Get departments available to current user
  Future<List<String>> getAvailableDepartments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) return [];

      // Admin can see all departments
      if (response['is_admin'] == true || response['role'] == 'admin') {
        // Get all unique departments from students table
        final deptResponse = await _supabase
            .from('students')
            .select('department')
            .order('department');

        final departments =
            deptResponse.map((d) => d['department'] as String).toSet().toList();

        return departments;
      }

      // HOD can see only their assigned department
      if (response['role'] == 'hod' &&
          response['assigned_department'] != null) {
        return [response['assigned_department']];
      }

      return [];
    } catch (e) {
      print('Error getting available departments: $e');
      return [];
    }
  }

  /// Get user role and permissions
  Future<Map<String, dynamic>> getUserRoleInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'role': 'guest',
          'isAdmin': false,
          'isHOD': false,
          'assignedDepartment': null,
        };
      }

      final response =
          await _supabase
              .from('users')
              .select('role, assigned_department, is_admin, name')
              .eq('id', user.id)
              .maybeSingle();

      if (response == null) {
        return {
          'role': 'student',
          'isAdmin': false,
          'isHOD': false,
          'assignedDepartment': null,
        };
      }

      return {
        'role': response['role'] ?? 'student',
        'isAdmin': response['is_admin'] == true || response['role'] == 'admin',
        'isHOD': response['role'] == 'hod',
        'assignedDepartment': response['assigned_department'],
        'name': response['name'],
      };
    } catch (e) {
      print('Error getting user role info: $e');
      return {
        'role': 'guest',
        'isAdmin': false,
        'isHOD': false,
        'assignedDepartment': null,
      };
    }
  }

  /// RPC function method disabled - function doesn't exist in database
  /*
  /// Get today's department attendance summary using RPC function with enhanced error handling
  Future<Map<String, dynamic>> getDepartmentAttendanceSummaryRPC(
    String department, {
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr = targetDate.toIso8601String().split('T')[0];

      print(
        'HOD Service: Calling RPC get_department_attendance_summary for $department on $dateStr',
      );

      // ENHANCED ERROR HANDLING: Wrap RPC call in try-catch
      try {
        final response = await _supabase.rpc(
          'get_department_attendance_summary',
          params: {'dept_name': department, 'target_date': dateStr},
        );

        print('HOD Service: RPC response - $response');

        if (response == null || response.isEmpty) {
          print('HOD Service: RPC returned null or empty response');
          return {
            'total_students': 0,
            'today_present': 0,
            'today_absent': 0,
            'today_percentage': 0.0,
            'low_attendance_today': 0,
            'date': dateStr,
            'attendance_taken': false,
            'error': 'RPC_NO_DATA',
            'error_message': 'RPC function returned no data',
          };
        }

        return response;
      } catch (rpcError) {
        print('HOD Service: CRITICAL RPC ERROR - $rpcError');
        print('HOD Service: Error type - ${rpcError.runtimeType}');

        // Check if it's a permissions error
        final errorMessage = rpcError.toString().toLowerCase();
        if (errorMessage.contains('permission') ||
            errorMessage.contains('rls') ||
            errorMessage.contains('policy') ||
            errorMessage.contains('access')) {
          print('HOD Service: This appears to be an RLS/permissions issue');
          return {
            'total_students': 0,
            'today_present': 0,
            'today_absent': 0,
            'today_percentage': 0.0,
            'low_attendance_today': 0,
            'date': dateStr,
            'attendance_taken': false,
            'error': 'RPC_PERMISSION_DENIED',
            'error_message': 'RPC function access denied: $rpcError',
          };
        }

        // For other RPC errors
        return {
          'total_students': 0,
          'today_present': 0,
          'today_absent': 0,
          'today_percentage': 0.0,
          'low_attendance_today': 0,
          'date': dateStr,
          'attendance_taken': false,
          'error': 'RPC_ERROR',
          'error_message': 'RPC function error: $rpcError',
        };
      }
    } catch (e) {
      print(
        'HOD Service: GENERAL ERROR in getDepartmentAttendanceSummaryRPC: $e',
      );
      return {
        'total_students': 0,
        'today_present': 0,
        'today_absent': 0,
        'today_percentage': 0.0,
        'low_attendance_today': 0,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'attendance_taken': false,
        'error': 'GENERAL_ERROR',
        'error_message': e.toString(),
      };
    }
  }
  */

  /// Get today's department attendance summary with live data (Enhanced with better error handling)
  Future<Map<String, dynamic>> getDepartmentAttendanceSummary(
    String department, {
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr = targetDate.toIso8601String().split('T')[0];

      print(
        'HOD Service: Fetching attendance summary for $department on $dateStr',
      );

      // ENHANCED DEBUGGING: Check current user and permissions
      try {
        final user = _supabase.auth.currentUser;
        print(
          'HOD Service: Current user - ${user?.email ?? "Not authenticated"}',
        );

        if (user?.email != null) {
          // Check user role
          final userRoleQuery =
              await _supabase
                  .from('users')
                  .select('role, assigned_department, name')
                  .eq('id', user!.id)
                  .maybeSingle();

          if (userRoleQuery != null) {
            print(
              'HOD Service: User role - ${userRoleQuery['role']}, Department - ${userRoleQuery['assigned_department']}',
            );
          } else {
            print(
              'HOD Service: WARNING - No user role found for ${user.email}',
            );
          }
        }
      } catch (roleError) {
        print('HOD Service: Error checking user role - $roleError');
      }

      // ENHANCED: Test direct daily_attendance access
      print('HOD Service: Testing direct access to daily_attendance table...');
      try {
        final testQuery = await _supabase
            .from('daily_attendance')
            .select('id, date, registration_no, is_present')
            .eq('date', dateStr)
            .limit(5);

        print(
          'HOD Service: Direct daily_attendance test - Found ${testQuery.length} records',
        );
        if (testQuery.isNotEmpty) {
          print('HOD Service: Sample records - ${testQuery.first}');
        }
      } catch (testError) {
        print(
          'HOD Service: CRITICAL - Cannot access daily_attendance table: $testError',
        );
        print(
          'HOD Service: This indicates an RLS (Row Level Security) policy issue',
        );

        // Return error state with detailed message
        return {
          'total_students': 0,
          'today_present': 0,
          'today_absent': 0,
          'today_percentage': 0.0,
          'low_attendance_today': 0,
          'date': dateStr,
          'attendance_taken': false,
          'error': 'RLS_ACCESS_DENIED',
          'error_message':
              'HOD role cannot access daily_attendance table. Check RLS policies.',
        };
      }

      // Get all students in the department with enhanced error handling
      print('HOD Service: Testing students table access...');
      var studentsQuery = _supabase
          .from('students')
          .select('registration_no, current_semester, section, student_name');

      // Apply department filter with pattern matching
      if (department.toLowerCase().contains('computer science')) {
        studentsQuery = studentsQuery.ilike(
          'department',
          '%computer science%engineering%',
        );
      } else {
        studentsQuery = studentsQuery.ilike('department', department);
      }

      List<Map<String, dynamic>> allStudents;
      try {
        allStudents = await studentsQuery;
        print(
          'HOD Service: Successfully accessed students table - found ${allStudents.length} students',
        );

        // ENHANCED DEBUGGING: Show sample students and department info
        if (allStudents.isNotEmpty) {
          print('HOD Service: Sample students found:');
          for (int i = 0; i < allStudents.length && i < 3; i++) {
            final student = allStudents[i];
            print(
              '  - ${student['student_name']} (${student['registration_no']})',
            );
          }
        } else {
          print(
            'HOD Service: WARNING - No students found for department pattern matching',
          );
          print('HOD Service: Department filter used: $department');
          final pattern =
              department.toLowerCase().contains('computer science')
                  ? '%computer science%engineering%'
                  : department;
          print('HOD Service: ILIKE pattern used: $pattern');

          // Additional debug: Try to understand why no students found
          try {
            final allDepts = await _supabase
                .from('students')
                .select('department')
                .limit(5);
            print('HOD Service: Sample department names in students table:');
            for (final dept in allDepts) {
              print('  - "${dept['department']}"');
            }
          } catch (e) {
            print('HOD Service: Could not fetch sample departments: $e');
          }
        }
      } catch (studentsError) {
        print(
          'HOD Service: CRITICAL - Cannot access students table: $studentsError',
        );
        print(
          'HOD Service: This indicates missing RLS policy for students table',
        );

        return {
          'total_students': 0,
          'today_present': 0,
          'today_absent': 0,
          'today_percentage': 0.0,
          'low_attendance_today': 0,
          'date': dateStr,
          'attendance_taken': false,
          'error': 'STUDENTS_ACCESS_DENIED',
          'error_message':
              'HOD role cannot access students table. Check RLS policies: $studentsError',
        };
      }
      final totalStudents = allStudents.length;

      if (totalStudents == 0) {
        return {
          'total_students': 0,
          'today_present': 0,
          'today_absent': 0,
          'today_percentage': 0.0,
          'low_attendance_today': 0,
          'date': dateStr,
        };
      }

      final registrationNumbers =
          allStudents.map((s) => s['registration_no'] as String).toList();

      // First, check if ANY attendance records exist for this department on this date
      final attendanceCheckQuery = await _supabase
          .from('daily_attendance')
          .select('registration_no')
          .eq('date', dateStr)
          .inFilter('registration_no', registrationNumbers)
          .limit(1);

      // If no attendance records exist at all for this date, return zeros
      if (attendanceCheckQuery.isEmpty) {
        print(
          'HOD Service: No attendance records found for $department on $dateStr - returning zeros',
        );
        return {
          'total_students': totalStudents,
          'today_present': 0,
          'today_absent': 0,
          'today_percentage': 0.0,
          'low_attendance_today': 0,
          'date': dateStr,
          'attendance_taken': false, // Flag to indicate no attendance was taken
        };
      }

      // Get today's attendance from daily_attendance table with enhanced debugging
      print(
        'HOD Service: Querying attendance for ${registrationNumbers.length} students on $dateStr',
      );

      final todayAttendance = await _supabase
          .from('daily_attendance')
          .select('registration_no, is_present')
          .eq('date', dateStr)
          .inFilter('registration_no', registrationNumbers);

      print(
        'HOD Service: Found ${todayAttendance.length} attendance records for department students on $dateStr',
      );

      // Show sample attendance records
      if (todayAttendance.isNotEmpty) {
        print('HOD Service: Sample attendance records:');
        for (int i = 0; i < todayAttendance.length && i < 3; i++) {
          final record = todayAttendance[i];
          print(
            '  - ${record['registration_no']}: ${record['is_present'] ? 'Present' : 'Absent'}',
          );
        }
      } else {
        print(
          'HOD Service: No attendance records found - checking if any exist for today at all...',
        );
        try {
          final anyTodayAttendance = await _supabase
              .from('daily_attendance')
              .select('registration_no, is_present')
              .eq('date', dateStr)
              .limit(5);
          print(
            'HOD Service: Total attendance records for $dateStr: ${anyTodayAttendance.length}',
          );
          if (anyTodayAttendance.isNotEmpty) {
            print(
              'HOD Service: Sample attendance records from any department:',
            );
            for (final record in anyTodayAttendance) {
              print(
                '  - ${record['registration_no']}: ${record['is_present'] ? 'Present' : 'Absent'}',
              );
            }
          }
        } catch (e) {
          print('HOD Service: Error checking total attendance: $e');
        }
      }

      // Calculate today's metrics
      int todayPresent = 0;
      int todayAbsent = 0;

      // Create a map for quick lookup
      final attendanceMap = <String, bool>{};
      for (final record in todayAttendance) {
        final regNo = record['registration_no'] as String;
        final isPresent = record['is_present'] as bool? ?? false;
        attendanceMap[regNo] = isPresent;

        if (isPresent) {
          todayPresent++;
        } else {
          todayAbsent++;
        }
      }

      // FIXED LOGIC: Only count students with actual absence records as absent
      // Students without records are not counted as absent when attendance exists for others
      // This prevents the "all students absent" issue when attendance is partially taken
      final studentsWithoutRecord = totalStudents - todayAttendance.length;

      // Only add students without records to absent count if attendance was partially taken
      // The logic is: if some students have attendance records, then students without records
      // are considered absent (they weren't marked but others were)
      if (todayAttendance.isNotEmpty) {
        todayAbsent += studentsWithoutRecord;
      }

      // Calculate percentage
      final todayPercentage =
          totalStudents > 0 ? (todayPresent / totalStudents) * 100 : 0.0;

      print(
        'HOD Service: Department $department - Total: $totalStudents, Present: $todayPresent, Absent: $todayAbsent, Records: ${todayAttendance.length}',
      );

      return {
        'total_students': totalStudents,
        'today_present': todayPresent,
        'today_absent': todayAbsent,
        'today_percentage': todayPercentage,
        'low_attendance_today': todayAbsent,
        'date': dateStr,
        'attendance_taken': true, // Flag to indicate attendance was taken
      };
    } catch (e) {
      print('Error getting department attendance summary: $e');
      return {
        'total_students': 0,
        'today_present': 0,
        'today_absent': 0,
        'today_percentage': 0.0,
        'low_attendance_today': 0,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'attendance_taken': false, // Flag to indicate error state
      };
    }
  }

  /// Get semester-wise attendance data for today
  Future<List<Map<String, dynamic>>> getTodaySemesterWiseData(
    String department, {
    int? selectedSemester,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();

      List<Map<String, dynamic>> data = [];

      // If a specific semester is selected, only load that semester
      final semestersToLoad =
          selectedSemester != null
              ? [selectedSemester]
              : [1, 2, 3, 4, 5, 6, 7, 8]; // Load all semesters if none selected

      // Load TODAY'S data for specified semesters
      for (int semester in semestersToLoad) {
        try {
          print(
            'HOD Service: Loading TODAY\'S data for semester $semester for department: $department',
          );

          // Get today's attendance data for this semester using AttendanceService
          final semesterTodayData = await _attendanceService
              .getTodaySemesterAttendance(
                department: department,
                semester: semester,
              );

          print(
            'HOD Service: Semester $semester TODAY - ${semesterTodayData['total_students']} total students, ${semesterTodayData['today_present']} present, ${semesterTodayData['today_absent']} absent, attendance_taken: ${semesterTodayData['attendance_taken']}',
          );

          if (semesterTodayData['total_students'] > 0 ||
              (semesterTodayData['attendance_taken'] ?? false)) {
            data.add({
              'semester': semester,
              'total_students': semesterTodayData['total_students'],
              'today_present': semesterTodayData['today_present'],
              'today_absent': semesterTodayData['today_absent'],
              'today_percentage': semesterTodayData['today_percentage'],
              'students': semesterTodayData['students'],
              'attendance_taken':
                  semesterTodayData['attendance_taken'] ?? false,
              'date': targetDate.toIso8601String().split('T')[0],
            });
            print(
              'HOD Service: Added semester $semester data with attendance_taken: ${semesterTodayData['attendance_taken']}',
            );
          } else {
            print(
              'HOD Service: No students found for semester $semester and no attendance taken',
            );
          }
        } catch (e) {
          print('HOD Service: Error loading semester $semester: $e');
        }
      }

      return data;
    } catch (e) {
      print('Error getting today\'s semester-wise data: $e');
      return [];
    }
  }

  /// Get students with low attendance for today
  Future<List<Map<String, dynamic>>> getTodayLowAttendanceStudents(
    String department, {
    int? selectedSemester,
    DateTime? date,
    double threshold = 75.0,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();

      // Use AttendanceService to get low attendance students
      final lowAttendanceStudents = await _attendanceService
          .getTodayLowAttendanceStudents(
            department: department,
            semester: selectedSemester,
            threshold: threshold,
          );

      // Add date information
      return lowAttendanceStudents
          .map(
            (student) => {
              ...student,
              'date': targetDate.toIso8601String().split('T')[0],
            },
          )
          .toList();
    } catch (e) {
      print('Error getting today\'s low attendance students: $e');
      return [];
    }
  }

  /// Fetch all available columns from the students table (for dynamic PDF export)
  Future<List<String>> fetchStudentTableColumns() async {
    try {
      // Fetch a single row to get all keys (columns)
      final resp = await _supabase.from('students').select().limit(1);
      if (resp.isEmpty) {
        // Fallback to a default set if table is empty
        return [
          'registration_no',
          'student_name',
          'department',
          'semester',
          'current_semester',
          'section',
          'batch',
          'user_id',
          'created_at',
          'updated_at',
        ];
      }
      return resp.first.keys.toList();
    } catch (e) {
      // Return fallback columns if there's an error
      return [
        'registration_no',
        'student_name',
        'department',
        'semester',
        'current_semester',
        'section',
        'batch',
        'user_id',
        'created_at',
        'updated_at',
      ];
    }
  }

  /// Fetch student data for only the selected columns, with optional filters
  Future<List<Map<String, dynamic>>> fetchCustomStudentData(
    List<String> selectedColumns, {
    String? department,
    int? semester,
    String? section,
  }) async {
    var query = _supabase.from('students').select(selectedColumns.join(','));
    if (department != null) {
      query = query.eq('department', department);
    }
    if (semester != null) {
      // Try both semester and current_semester for compatibility
      query = query.or('semester.eq.$semester,current_semester.eq.$semester');
    }
    if (section != null) {
      query = query.eq('section', section);
    }
    final resp = await query.order('registration_no', ascending: true);
    return List<Map<String, dynamic>>.from(resp);
  }

  /// Fetch attendance report data for students with daily attendance
  Future<Map<String, dynamic>> fetchAttendanceReportData({
    String? department,
    int? semester,
    String? section,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Set default date range if not provided (current week)
      final now = DateTime.now();
      final weekStart =
          startDate ?? now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = endDate ?? weekStart.add(const Duration(days: 6));

      // Get students
      var studentsQuery = _supabase
          .from('students')
          .select(
            'registration_no, student_name, department, semester, current_semester, section',
          );

      if (department != null) {
        studentsQuery = studentsQuery.eq('department', department);
      }
      if (semester != null) {
        studentsQuery = studentsQuery.or(
          'semester.eq.$semester,current_semester.eq.$semester',
        );
      }
      if (section != null) {
        studentsQuery = studentsQuery.eq('section', section);
      }

      final students = await studentsQuery.order('registration_no', ascending: true);

      // Generate date range for the week
      List<DateTime> dateRange = [];
      for (int i = 0; i <= weekEnd.difference(weekStart).inDays; i++) {
        dateRange.add(weekStart.add(Duration(days: i)));
      }

      // Get attendance data for the date range
      final attendanceData = await _supabase
          .from('daily_attendance')
          .select('registration_no, date, is_present')
          .gte('date', weekStart.toIso8601String().split('T')[0])
          .lte('date', weekEnd.toIso8601String().split('T')[0]);

      // Also get period-based attendance as fallback
      final periodAttendanceData = await _supabase
          .from('attendance')
          .select('registration_no, date, is_present')
          .gte('date', weekStart.toIso8601String().split('T')[0])
          .lte('date', weekEnd.toIso8601String().split('T')[0]);

      // Create attendance map
      Map<String, Map<String, bool>> attendanceMap = {};

      // Process daily attendance first
      for (var record in attendanceData) {
        final regNo = record['registration_no'] as String;
        final date = record['date'] as String;
        final isPresent = record['is_present'] as bool;

        if (!attendanceMap.containsKey(regNo)) {
          attendanceMap[regNo] = {};
        }
        attendanceMap[regNo]![date] = isPresent;
      }

      // Process period attendance (aggregate by date)
      Map<String, Map<String, List<bool>>> periodMap = {};
      for (var record in periodAttendanceData) {
        final regNo = record['registration_no'] as String;
        final date = record['date'] as String;
        final isPresent = record['is_present'] as bool;

        if (!periodMap.containsKey(regNo)) {
          periodMap[regNo] = {};
        }
        if (!periodMap[regNo]!.containsKey(date)) {
          periodMap[regNo]![date] = [];
        }
        periodMap[regNo]![date]!.add(isPresent);
      }

      // Convert period attendance to daily (present if attended any period)
      for (var regNo in periodMap.keys) {
        if (!attendanceMap.containsKey(regNo)) {
          attendanceMap[regNo] = {};
        }
        for (var date in periodMap[regNo]!.keys) {
          if (!attendanceMap[regNo]!.containsKey(date)) {
            final periodsList = periodMap[regNo]![date]!;
            attendanceMap[regNo]![date] = periodsList.any((p) => p);
          }
        }
      }

      return {
        'students': students,
        'dateRange': dateRange,
        'attendanceMap': attendanceMap,
        'startDate': weekStart,
        'endDate': weekEnd,
      };
    } catch (e) {
      print('Error fetching attendance report data: $e');
      return {
        'students': <Map<String, dynamic>>[],
        'dateRange': <DateTime>[],
        'attendanceMap': <String, Map<String, bool>>{},
        'startDate': DateTime.now(),
        'endDate': DateTime.now(),
      };
    }
  }
}
