// Manually generated Supabase types for Campus Sync App
// This provides AI assistance with complete database schema awareness

// ============================================================================
// DATABASE TABLE TYPES
// ============================================================================

/// Students table structure
class Student {
  final String registrationNo;
  final String? studentName;
  final String? department;
  final int? semester;
  final int? currentSemester;
  final String? section;
  final String? batch;
  final String? userId; // Reference to auth.users
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Student({
    required this.registrationNo,
    this.studentName,
    this.department,
    this.semester,
    this.currentSemester,
    this.section,
    this.batch,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    registrationNo: json['registration_no'] as String,
    studentName: json['student_name'] as String?,
    department: json['department'] as String?,
    semester: json['semester'] as int?,
    currentSemester: json['current_semester'] as int?,
    section: json['section'] as String?,
    batch: json['batch'] as String?,
    userId: json['user_id'] as String?,
    createdAt:
        json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
    updatedAt:
        json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'registration_no': registrationNo,
    'student_name': studentName,
    'department': department,
    'semester': semester,
    'current_semester': currentSemester,
    'section': section,
    'batch': batch,
    'user_id': userId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Subjects table structure
class Subject {
  final String subjectCode;
  final String? subjectName;
  final String? department;
  final int? semester;
  final String? facultyName;
  final int? credits;
  final DateTime? createdAt;

  const Subject({
    required this.subjectCode,
    this.subjectName,
    this.department,
    this.semester,
    this.facultyName,
    this.credits,
    this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    subjectCode: json['subject_code'] as String,
    subjectName: json['subject_name'] as String?,
    department: json['department'] as String?,
    semester: json['semester'] as int?,
    facultyName: json['faculty_name'] as String?,
    credits: json['credits'] as int?,
    createdAt:
        json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'subject_code': subjectCode,
    'subject_name': subjectName,
    'department': department,
    'semester': semester,
    'faculty_name': facultyName,
    'credits': credits,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// Period-wise attendance table structure
class Attendance {
  final String? id;
  final String registrationNo;
  final String subjectCode;
  final DateTime date;
  final int periodNumber;
  final bool isPresent;
  final String? academicYear;
  final DateTime? markedAt;
  final String? markedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Attendance({
    this.id,
    required this.registrationNo,
    required this.subjectCode,
    required this.date,
    required this.periodNumber,
    required this.isPresent,
    this.academicYear,
    this.markedAt,
    this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'] as String?,
    registrationNo: json['registration_no'] as String,
    subjectCode: json['subject_code'] as String,
    date: DateTime.parse(json['date'] as String),
    periodNumber: json['period_number'] as int,
    isPresent: json['is_present'] as bool,
    academicYear: json['academic_year'] as String?,
    markedAt:
        json['marked_at'] != null
            ? DateTime.parse(json['marked_at'] as String)
            : null,
    markedBy: json['marked_by'] as String?,
    createdAt:
        json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
    updatedAt:
        json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_no': registrationNo,
    'subject_code': subjectCode,
    'date': date.toIso8601String().split('T')[0],
    'period_number': periodNumber,
    'is_present': isPresent,
    'academic_year': academicYear,
    'marked_at': markedAt?.toIso8601String(),
    'marked_by': markedBy,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Daily attendance summary table structure
class DailyAttendance {
  final int? id;
  final String registrationNo;
  final DateTime date;
  final bool isPresent;
  final DateTime? markedAt;
  final String? markedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyAttendance({
    this.id,
    required this.registrationNo,
    required this.date,
    required this.isPresent,
    this.markedAt,
    this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) =>
      DailyAttendance(
        id: json['id'] as int?,
        registrationNo: json['registration_no'] as String,
        date: DateTime.parse(json['date'] as String),
        isPresent: json['is_present'] as bool,
        markedAt:
            json['marked_at'] != null
                ? DateTime.parse(json['marked_at'] as String)
                : null,
        markedBy: json['marked_by'] as String?,
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : null,
        updatedAt:
            json['updated_at'] != null
                ? DateTime.parse(json['updated_at'] as String)
                : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_no': registrationNo,
    'date': date.toIso8601String().split('T')[0],
    'is_present': isPresent,
    'marked_at': markedAt?.toIso8601String(),
    'marked_by': markedBy,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Subject-wise attendance summary table structure
class AttendanceSummary {
  final String? id;
  final String registrationNo;
  final String subjectCode;
  final String department;
  final int semester;
  final String section;
  final DateTime date;
  final int totalPeriods;
  final int attendedPeriods;
  final double attendancePercentage;
  final DateTime? lastUpdated;

  const AttendanceSummary({
    this.id,
    required this.registrationNo,
    required this.subjectCode,
    required this.department,
    required this.semester,
    required this.section,
    required this.date,
    required this.totalPeriods,
    required this.attendedPeriods,
    required this.attendancePercentage,
    this.lastUpdated,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        id: json['id'] as String?,
        registrationNo: json['registration_no'] as String,
        subjectCode: json['subject_code'] as String,
        department: json['department'] as String,
        semester: json['semester'] as int,
        section: json['section'] as String,
        date: DateTime.parse(json['date'] as String),
        totalPeriods: json['total_periods'] as int,
        attendedPeriods: json['attended_periods'] as int,
        attendancePercentage: (json['attendance_percentage'] as num).toDouble(),
        lastUpdated:
            json['last_updated'] != null
                ? DateTime.parse(json['last_updated'] as String)
                : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_no': registrationNo,
    'subject_code': subjectCode,
    'department': department,
    'semester': semester,
    'section': section,
    'date': date.toIso8601String().split('T')[0],
    'total_periods': totalPeriods,
    'attended_periods': attendedPeriods,
    'attendance_percentage': attendancePercentage,
    'last_updated': lastUpdated?.toIso8601String(),
  };
}

/// Overall attendance summary table structure
class OverallAttendanceSummary {
  final int? id;
  final String registrationNo;
  final String department;
  final int semester;
  final String section;
  final int totalPeriods;
  final int attendedPeriods;
  final double overallPercentage;
  final DateTime? lastUpdated;

  const OverallAttendanceSummary({
    this.id,
    required this.registrationNo,
    required this.department,
    required this.semester,
    required this.section,
    required this.totalPeriods,
    required this.attendedPeriods,
    required this.overallPercentage,
    this.lastUpdated,
  });

  factory OverallAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      OverallAttendanceSummary(
        id: json['id'] as int?,
        registrationNo: json['registration_no'] as String,
        department: json['department'] as String,
        semester: json['semester'] as int,
        section: json['section'] as String,
        totalPeriods: json['total_periods'] as int,
        attendedPeriods: json['attended_periods'] as int,
        overallPercentage: (json['overall_percentage'] as num).toDouble(),
        lastUpdated:
            json['last_updated'] != null
                ? DateTime.parse(json['last_updated'] as String)
                : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'registration_no': registrationNo,
    'department': department,
    'semester': semester,
    'section': section,
    'total_periods': totalPeriods,
    'attended_periods': attendedPeriods,
    'overall_percentage': overallPercentage,
    'last_updated': lastUpdated?.toIso8601String(),
  };
}

/// Class schedule table structure
class ClassSchedule {
  final String? id;
  final DateTime date;
  final String department;
  final int semester;
  final String section;
  final int periodNumber;
  final String subjectCode;
  final String? staffId;
  final bool isConducted;
  final DateTime? createdAt;

  const ClassSchedule({
    this.id,
    required this.date,
    required this.department,
    required this.semester,
    required this.section,
    required this.periodNumber,
    required this.subjectCode,
    this.staffId,
    required this.isConducted,
    this.createdAt,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) => ClassSchedule(
    id: json['id'] as String?,
    date: DateTime.parse(json['date'] as String),
    department: json['department'] as String,
    semester: json['semester'] as int,
    section: json['section'] as String,
    periodNumber: json['period_number'] as int,
    subjectCode: json['subject_code'] as String,
    staffId: json['staff_id'] as String?,
    isConducted: json['is_conducted'] as bool,
    createdAt:
        json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String().split('T')[0],
    'department': department,
    'semester': semester,
    'section': section,
    'period_number': periodNumber,
    'subject_code': subjectCode,
    'staff_id': staffId,
    'is_conducted': isConducted,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// User profile table structure (auth.users related)
class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String?,
    email: json['email'] as String?,
    role: json['role'] as String?,
    createdAt:
        json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
    updatedAt:
        json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

// ============================================================================
// VIEW TYPES
// ============================================================================

/// Attendance analytics view structure
class AttendanceAnalytics {
  final String registrationNo;
  final String studentName;
  final String department;
  final int semester;
  final String section;
  final int totalPeriods;
  final int attendedPeriods;
  final double overallPercentage;
  final String attendanceStatus;
  final DateTime? lastUpdated;

  const AttendanceAnalytics({
    required this.registrationNo,
    required this.studentName,
    required this.department,
    required this.semester,
    required this.section,
    required this.totalPeriods,
    required this.attendedPeriods,
    required this.overallPercentage,
    required this.attendanceStatus,
    this.lastUpdated,
  });

  factory AttendanceAnalytics.fromJson(Map<String, dynamic> json) =>
      AttendanceAnalytics(
        registrationNo: json['registration_no'] as String,
        studentName: json['student_name'] as String,
        department: json['department'] as String,
        semester: json['semester'] as int,
        section: json['section'] as String,
        totalPeriods: json['total_periods'] as int,
        attendedPeriods: json['attended_periods'] as int,
        overallPercentage: (json['overall_percentage'] as num).toDouble(),
        attendanceStatus: json['attendance_status'] as String,
        lastUpdated:
            json['last_updated'] != null
                ? DateTime.parse(json['last_updated'] as String)
                : null,
      );
}

/// Subject attendance report view structure
class SubjectAttendanceReport {
  final String registrationNo;
  final String studentName;
  final String department;
  final int currentSemester;
  final String section;
  final String subjectCode;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final double subjectPercentage;

  const SubjectAttendanceReport({
    required this.registrationNo,
    required this.studentName,
    required this.department,
    required this.currentSemester,
    required this.section,
    required this.subjectCode,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.subjectPercentage,
  });

  factory SubjectAttendanceReport.fromJson(Map<String, dynamic> json) =>
      SubjectAttendanceReport(
        registrationNo: json['registration_no'] as String,
        studentName: json['student_name'] as String,
        department: json['department'] as String,
        currentSemester: json['current_semester'] as int,
        section: json['section'] as String,
        subjectCode: json['subject_code'] as String,
        subjectName: json['subject_name'] as String,
        totalClasses: json['total_classes'] as int,
        attendedClasses: json['attended_classes'] as int,
        subjectPercentage: (json['subject_percentage'] as num).toDouble(),
      );
}

// ============================================================================
// COMMON RESPONSE TYPES
// ============================================================================

/// Common attendance response structure used throughout the app
class AttendanceResponse {
  final String registrationNo;
  final String studentName;
  final String department;
  final int semester;
  final String section;
  final double percentage;
  final int totalClasses;
  final int attendedClasses;
  final String status;
  final bool? isPresent;
  final double? todayPercentage;

  const AttendanceResponse({
    required this.registrationNo,
    required this.studentName,
    required this.department,
    required this.semester,
    required this.section,
    required this.percentage,
    required this.totalClasses,
    required this.attendedClasses,
    required this.status,
    this.isPresent,
    this.todayPercentage,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      AttendanceResponse(
        registrationNo: json['registration_no'] as String,
        studentName: json['student_name'] as String,
        department: json['department'] as String,
        semester: json['semester'] as int,
        section: json['section'] as String,
        percentage: (json['percentage'] as num).toDouble(),
        totalClasses: json['total_classes'] as int,
        attendedClasses: json['attended_classes'] as int,
        status: json['status'] as String,
        isPresent: json['is_present'] as bool?,
        todayPercentage:
            json['today_percentage'] != null
                ? (json['today_percentage'] as num).toDouble()
                : null,
      );

  Map<String, dynamic> toJson() => {
    'registration_no': registrationNo,
    'student_name': studentName,
    'department': department,
    'semester': semester,
    'section': section,
    'percentage': percentage,
    'total_classes': totalClasses,
    'attended_classes': attendedClasses,
    'status': status,
    'is_present': isPresent,
    'today_percentage': todayPercentage,
  };
}

/// Department summary response structure
class DepartmentSummaryResponse {
  final String department;
  final int semester;
  final int totalStudents;
  final int todayPresent;
  final int todayAbsent;
  final double todayPercentage;
  final List<AttendanceResponse> students;

  const DepartmentSummaryResponse({
    required this.department,
    required this.semester,
    required this.totalStudents,
    required this.todayPresent,
    required this.todayAbsent,
    required this.todayPercentage,
    required this.students,
  });

  factory DepartmentSummaryResponse.fromJson(Map<String, dynamic> json) =>
      DepartmentSummaryResponse(
        department: json['department'] as String,
        semester: json['semester'] as int,
        totalStudents: json['total_students'] as int,
        todayPresent: json['today_present'] as int,
        todayAbsent: json['today_absent'] as int,
        todayPercentage: (json['today_percentage'] as num).toDouble(),
        students:
            (json['students'] as List<dynamic>)
                .map(
                  (e) => AttendanceResponse.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );

  Map<String, dynamic> toJson() => {
    'department': department,
    'semester': semester,
    'total_students': totalStudents,
    'today_present': todayPresent,
    'today_absent': todayAbsent,
    'today_percentage': todayPercentage,
    'students': students.map((s) => s.toJson()).toList(),
  };
}

// ============================================================================
// ENUM TYPES
// ============================================================================

/// Attendance status enumeration
enum AttendanceStatus { excellent, good, average, belowAverage, poor }

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.excellent:
        return 'Excellent';
      case AttendanceStatus.good:
        return 'Good';
      case AttendanceStatus.average:
        return 'Average';
      case AttendanceStatus.belowAverage:
        return 'Below Average';
      case AttendanceStatus.poor:
        return 'Poor';
    }
  }

  static AttendanceStatus fromPercentage(double percentage) {
    if (percentage >= 90) return AttendanceStatus.excellent;
    if (percentage >= 75) return AttendanceStatus.good;
    if (percentage >= 60) return AttendanceStatus.average;
    if (percentage >= 50) return AttendanceStatus.belowAverage;
    return AttendanceStatus.poor;
  }
}

/// User role enumeration
enum UserRole { student, staff, hod, admin }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.staff:
        return 'staff';
      case UserRole.hod:
        return 'hod';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'staff':
        return UserRole.staff;
      case 'hod':
        return UserRole.hod;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }
}

// ============================================================================
// UTILITY TYPES
// ============================================================================

/// Type-safe filter options for attendance queries
class AttendanceFilter {
  final String? department;
  final int? semester;
  final String? section;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minPercentage;
  final double? maxPercentage;
  final List<String>? registrationNumbers;

  const AttendanceFilter({
    this.department,
    this.semester,
    this.section,
    this.startDate,
    this.endDate,
    this.minPercentage,
    this.maxPercentage,
    this.registrationNumbers,
  });

  Map<String, dynamic> toJson() => {
    'department': department,
    'semester': semester,
    'section': section,
    'start_date': startDate?.toIso8601String().split('T')[0],
    'end_date': endDate?.toIso8601String().split('T')[0],
    'min_percentage': minPercentage,
    'max_percentage': maxPercentage,
    'registration_numbers': registrationNumbers,
  };
}

/// Type-safe pagination options
class PaginationOptions {
  final int page;
  final int limit;
  final String? orderBy;
  final bool ascending;

  const PaginationOptions({
    this.page = 1,
    this.limit = 50,
    this.orderBy,
    this.ascending = true,
  });

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'order_by': orderBy,
    'ascending': ascending,
  };
}

// ============================================================================
// CONSTANTS
// ============================================================================

/// Database table names
class DatabaseTables {
  static const String students = 'students';
  static const String subjects = 'subjects';
  static const String attendance = 'attendance';
  static const String dailyAttendance = 'daily_attendance';
  static const String attendanceSummary = 'attendance_summary';
  static const String overallAttendanceSummary = 'overall_attendance_summary';
  static const String classSchedule = 'class_schedule';
  static const String users = 'users';
}

/// Database view names
class DatabaseViews {
  static const String attendanceAnalytics = 'attendance_analytics';
  static const String attendanceAnalyticsV2 = 'attendance_analytics_v2';
  static const String subjectAttendanceReport = 'subject_attendance_report';
  static const String dailyAttendanceReport = 'daily_attendance_report';
}

/// Common query patterns
class QueryPatterns {
  static const String today = 'CURRENT_DATE';
  static const String thisWeek = "date_trunc('week', CURRENT_DATE)";
  static const String thisMonth = "date_trunc('month', CURRENT_DATE)";
  static const String thisAcademicYear = "'2024-25'";
}
