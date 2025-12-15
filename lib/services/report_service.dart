import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'hod_service.dart';
import 'attendance_service.dart';

/// Report types supported by the system
enum ReportType {
  dailyAttendance,
  weeklyLowAttendance,
  monthlyAnalytics,
  semesterConsolidation,
}

/// Report frequency for scheduling
enum ReportFrequency {
  daily,
  weekly,
  monthly,
  semesterEnd,
}

/// Configuration for a scheduled report
class ReportConfig {
  final ReportType type;
  final String department;
  final int? semester;
  final String? section;
  final List<String> recipients;
  final ReportFrequency frequency;
  final TimeOfDay scheduledTime;
  final bool enabled;

  ReportConfig({
    required this.type,
    required this.department,
    this.semester,
    this.section,
    required this.recipients,
    required this.frequency,
    required this.scheduledTime,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'department': department,
    'semester': semester,
    'section': section,
    'recipients': recipients,
    'frequency': frequency.name,
    'scheduled_hour': scheduledTime.hour,
    'scheduled_minute': scheduledTime.minute,
    'enabled': enabled,
  };

  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
    type: ReportType.values.firstWhere((e) => e.name == json['type']),
    department: json['department'],
    semester: json['semester'],
    section: json['section'],
    recipients: List<String>.from(json['recipients'] ?? []),
    frequency: ReportFrequency.values.firstWhere((e) => e.name == json['frequency']),
    scheduledTime: TimeOfDay(
      hour: json['scheduled_hour'] ?? 17,
      minute: json['scheduled_minute'] ?? 0,
    ),
    enabled: json['enabled'] ?? true,
  );
}

/// TimeOfDay class for scheduling (Flutter's TimeOfDay equivalent for service layer)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String format24Hour() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Service for generating automated reports
class ReportService {
  final _supabase = Supabase.instance.client;
  final _hodService = HODService();
  final _attendanceService = AttendanceService();

  // ============================================================================
  // REPORT GENERATION METHODS
  // ============================================================================

  /// Generate Daily Attendance PDF Report
  /// Shows today's attendance summary for a department
  Future<Uint8List> generateDailyAttendanceReport({
    required String department,
    int? semester,
    DateTime? date,
  }) async {
    final reportDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(reportDate);
    final displayDate = DateFormat('EEEE, MMMM d, yyyy').format(reportDate);

    debugPrint('Generating Daily Attendance Report for $department on $dateStr');

    // Fetch department summary
    final summary = await _hodService.getDepartmentAttendanceSummary(
      department,
      date: reportDate,
    );

    // Fetch semester-wise breakdown
    final semesterData = await _hodService.getTodaySemesterWiseData(
      department,
      selectedSemester: semester,
      date: reportDate,
    );

    // Fetch detailed attendance records
    final attendanceRecords = await _fetchDailyAttendanceDetails(
      department: department,
      semester: semester,
      date: reportDate,
    );

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader(
          title: 'Daily Attendance Report',
          subtitle: department,
          date: displayDate,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Summary Card
          _buildSummarySection(summary),
          pw.SizedBox(height: 20),

          // Semester-wise breakdown
          if (semesterData.isNotEmpty) ...[
            pw.Text(
              'Semester-wise Breakdown',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildSemesterTable(semesterData),
            pw.SizedBox(height: 20),
          ],

          // Detailed attendance list
          pw.Text(
            'Attendance Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildAttendanceTable(attendanceRecords),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Weekly Low Attendance Report
  /// Lists students with attendance below 75%
  Future<Uint8List> generateWeeklyLowAttendanceReport({
    required String department,
    int? semester,
    double threshold = 75.0,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final displayRange = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';

    debugPrint('Generating Weekly Low Attendance Report for $department');

    // Fetch students with low attendance
    final lowAttendanceStudents = await _fetchLowAttendanceStudents(
      department: department,
      semester: semester,
      threshold: threshold,
    );

    // Group by semester
    final Map<int, List<Map<String, dynamic>>> bySemester = {};
    for (final student in lowAttendanceStudents) {
      final sem = student['semester'] as int? ?? 0;
      bySemester.putIfAbsent(sem, () => []).add(student);
    }

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader(
          title: 'Weekly Low Attendance Report',
          subtitle: department,
          date: displayRange,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Alert summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '⚠️ ',
                  style: pw.TextStyle(fontSize: 24),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${lowAttendanceStudents.length} Students Below ${threshold.toInt()}% Attendance',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Immediate attention required for these students',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Students grouped by semester
          ...bySemester.entries.map((entry) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: PdfColors.grey200,
                child: pw.Text(
                  'Semester ${entry.key} (${entry.value.length} students)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              _buildLowAttendanceTable(entry.value),
              pw.SizedBox(height: 16),
            ],
          )).toList(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Monthly Analytics Report
  /// Department-wise comprehensive attendance analytics
  Future<Uint8List> generateMonthlyAnalyticsReport({
    required String department,
    int? semester,
    DateTime? month,
  }) async {
    final reportMonth = month ?? DateTime.now();
    final monthStart = DateTime(reportMonth.year, reportMonth.month, 1);
    final monthEnd = DateTime(reportMonth.year, reportMonth.month + 1, 0);
    final displayMonth = DateFormat('MMMM yyyy').format(reportMonth);

    debugPrint('Generating Monthly Analytics Report for $department - $displayMonth');

    // Fetch monthly statistics
    final monthlyStats = await _fetchMonthlyStatistics(
      department: department,
      semester: semester,
      startDate: monthStart,
      endDate: monthEnd,
    );

    // Fetch subject-wise breakdown
    final subjectWise = await _fetchSubjectWiseAttendance(
      department: department,
      semester: semester,
      startDate: monthStart,
      endDate: monthEnd,
    );

    // Fetch attendance trends (daily averages)
    final dailyTrends = await _fetchDailyTrends(
      department: department,
      semester: semester,
      startDate: monthStart,
      endDate: monthEnd,
    );

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader(
          title: 'Monthly Attendance Analytics',
          subtitle: department,
          date: displayMonth,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Monthly Overview
          _buildMonthlyOverview(monthlyStats),
          pw.SizedBox(height: 24),

          // Attendance Distribution
          pw.Text(
            'Attendance Distribution',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildDistributionChart(monthlyStats),
          pw.SizedBox(height: 24),

          // Subject-wise Performance
          if (subjectWise.isNotEmpty) ...[
            pw.Text(
              'Subject-wise Attendance',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildSubjectTable(subjectWise),
            pw.SizedBox(height: 24),
          ],

          // Daily Trends
          if (dailyTrends.isNotEmpty) ...[
            pw.Text(
              'Daily Attendance Trends',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildTrendsTable(dailyTrends),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate Semester Consolidation Report
  /// Final attendance compilation for semester end
  Future<Uint8List> generateSemesterConsolidationReport({
    required String department,
    required int semester,
    String? section,
    required String academicYear,
  }) async {
    debugPrint('Generating Semester Consolidation Report for $department Sem $semester');

    // Fetch all students with final attendance
    final consolidatedData = await _fetchSemesterConsolidation(
      department: department,
      semester: semester,
      section: section,
    );

    // Calculate statistics
    final totalStudents = consolidatedData.length;
    final aboveThreshold = consolidatedData.where((s) => (s['percentage'] ?? 0) >= 75).length;
    final belowThreshold = totalStudents - aboveThreshold;
    final avgAttendance = consolidatedData.isEmpty ? 0.0 :
        consolidatedData.map((s) => (s['percentage'] ?? 0) as num).reduce((a, b) => a + b) / totalStudents;

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildReportHeader(
          title: 'Semester Attendance Consolidation',
          subtitle: '$department - Semester $semester${section != null ? ' (Section $section)' : ''}',
          date: 'Academic Year: $academicYear',
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Summary statistics
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Total Students', totalStudents.toString(), PdfColors.blue),
              _buildStatCard('Above 75%', aboveThreshold.toString(), PdfColors.green),
              _buildStatCard('Below 75%', belowThreshold.toString(), PdfColors.red),
              _buildStatCard('Avg Attendance', '${avgAttendance.toStringAsFixed(1)}%', PdfColors.orange),
            ],
          ),
          pw.SizedBox(height: 24),

          // Detailed student list
          pw.Text(
            'Student-wise Attendance Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildConsolidationTable(consolidatedData),

          // Signature section
          pw.SizedBox(height: 40),
          _buildSignatureSection(),
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================================
  // PDF BUILDING HELPERS
  // ============================================================================

  pw.Widget _buildReportHeader({
    required String title,
    required String subtitle,
    required String date,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Campus Sync',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                  ),
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(date, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.blue800),
        ],
      ),
    );
  }

  pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(Map<String, dynamic> summary) {
    final present = summary['today_present'] ?? 0;
    final absent = summary['today_absent'] ?? 0;
    final total = summary['total_students'] ?? 0;
    final percentage = summary['today_percentage'] ?? 0.0;
    final attendanceTaken = summary['attendance_taken'] ?? false;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Students', total.toString(), PdfColors.blue),
          _buildStatCard('Present', present.toString(), PdfColors.green),
          _buildStatCard('Absent', absent.toString(), PdfColors.red),
          _buildStatCard('Attendance %', '${percentage.toStringAsFixed(1)}%', 
            percentage >= 75 ? PdfColors.green : PdfColors.red),
          _buildStatCard('Status', attendanceTaken ? 'Recorded' : 'Pending', 
            attendanceTaken ? PdfColors.green : PdfColors.orange),
        ],
      ),
    );
  }

  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _buildSemesterTable(List<Map<String, dynamic>> data) {
    return pw.Table.fromTextArray(
      headers: ['Semester', 'Section', 'Total', 'Present', 'Absent', 'Percentage'],
      data: data.map((row) => [
        'Sem ${row['semester']}',
        row['section'] ?? 'All',
        (row['total_students'] ?? 0).toString(),
        (row['today_present'] ?? 0).toString(),
        (row['today_absent'] ?? 0).toString(),
        '${(row['today_percentage'] ?? 0.0).toStringAsFixed(1)}%',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
    );
  }

  pw.Widget _buildAttendanceTable(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text('No attendance records found for this date.', 
          style: const pw.TextStyle(color: PdfColors.grey600)),
      );
    }

    return pw.Table.fromTextArray(
      headers: ['Reg. No.', 'Name', 'Section', 'Status', 'Periods'],
      data: records.map((row) => [
        row['registration_no'] ?? '',
        row['student_name'] ?? 'Unknown',
        row['section'] ?? '-',
        (row['is_present'] ?? false) ? 'Present' : 'Absent',
        (row['periods_attended'] ?? 0).toString(),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _buildLowAttendanceTable(List<Map<String, dynamic>> students) {
    return pw.Table.fromTextArray(
      headers: ['Reg. No.', 'Name', 'Section', 'Total Classes', 'Attended', 'Percentage', 'Status'],
      data: students.map((row) => [
        row['registration_no'] ?? '',
        row['student_name'] ?? 'Unknown',
        row['section'] ?? '-',
        (row['total_periods'] ?? 0).toString(),
        (row['attended_periods'] ?? 0).toString(),
        '${(row['percentage'] ?? 0.0).toStringAsFixed(1)}%',
        _getAttendanceStatus(row['percentage'] ?? 0.0),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
    );
  }

  pw.Widget _buildMonthlyOverview(Map<String, dynamic> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Working Days', (stats['working_days'] ?? 0).toString(), PdfColors.blue),
          _buildStatCard('Avg Attendance', '${(stats['avg_percentage'] ?? 0.0).toStringAsFixed(1)}%', PdfColors.green),
          _buildStatCard('Highest', '${(stats['max_percentage'] ?? 0.0).toStringAsFixed(1)}%', PdfColors.teal),
          _buildStatCard('Lowest', '${(stats['min_percentage'] ?? 0.0).toStringAsFixed(1)}%', PdfColors.orange),
        ],
      ),
    );
  }

  pw.Widget _buildDistributionChart(Map<String, dynamic> stats) {
    final above90 = stats['above_90'] ?? 0;
    final between75And90 = stats['between_75_90'] ?? 0;
    final between60And75 = stats['between_60_75'] ?? 0;
    final below60 = stats['below_60'] ?? 0;

    return pw.Table.fromTextArray(
      headers: ['Category', 'Count', 'Percentage'],
      data: [
        ['Excellent (≥90%)', above90.toString(), '${_calcPercentage(above90, stats['total_students'] ?? 1).toStringAsFixed(1)}%'],
        ['Good (75-90%)', between75And90.toString(), '${_calcPercentage(between75And90, stats['total_students'] ?? 1).toStringAsFixed(1)}%'],
        ['Average (60-75%)', between60And75.toString(), '${_calcPercentage(between60And75, stats['total_students'] ?? 1).toStringAsFixed(1)}%'],
        ['Poor (<60%)', below60.toString(), '${_calcPercentage(below60, stats['total_students'] ?? 1).toStringAsFixed(1)}%'],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _buildSubjectTable(List<Map<String, dynamic>> subjects) {
    return pw.Table.fromTextArray(
      headers: ['Subject Code', 'Subject Name', 'Total Classes', 'Avg Attendance'],
      data: subjects.map((row) => [
        row['subject_code'] ?? '',
        row['subject_name'] ?? 'Unknown',
        (row['total_classes'] ?? 0).toString(),
        '${(row['avg_attendance'] ?? 0.0).toStringAsFixed(1)}%',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _buildTrendsTable(List<Map<String, dynamic>> trends) {
    return pw.Table.fromTextArray(
      headers: ['Date', 'Day', 'Present', 'Absent', 'Percentage'],
      data: trends.map((row) => [
        DateFormat('dd/MM').format(DateTime.parse(row['date'])),
        DateFormat('EEE').format(DateTime.parse(row['date'])),
        (row['present'] ?? 0).toString(),
        (row['absent'] ?? 0).toString(),
        '${(row['percentage'] ?? 0.0).toStringAsFixed(1)}%',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _buildConsolidationTable(List<Map<String, dynamic>> data) {
    return pw.Table.fromTextArray(
      headers: ['S.No', 'Reg. No.', 'Name', 'Section', 'Total', 'Attended', 'Percentage', 'Status', 'Eligible'],
      data: data.asMap().entries.map((entry) {
        final row = entry.value;
        final percentage = row['percentage'] ?? 0.0;
        return [
          (entry.key + 1).toString(),
          row['registration_no'] ?? '',
          row['student_name'] ?? 'Unknown',
          row['section'] ?? '-',
          (row['total_periods'] ?? 0).toString(),
          (row['attended_periods'] ?? 0).toString(),
          '${percentage.toStringAsFixed(1)}%',
          _getAttendanceStatus(percentage),
          percentage >= 75 ? 'Yes' : 'No',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureBox('Class Advisor'),
        _buildSignatureBox('HOD'),
        _buildSignatureBox('Principal'),
      ],
    );
  }

  pw.Widget _buildSignatureBox(String role) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        children: [
          pw.Container(
            width: 120,
            height: 40,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(role, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================================
  // DATA FETCHING HELPERS
  // ============================================================================

  Future<List<Map<String, dynamic>>> _fetchDailyAttendanceDetails({
    required String department,
    int? semester,
    required DateTime date,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      var query = _supabase
          .from('attendance')
          .select('''
            registration_no,
            is_present,
            period_number,
            students!inner(student_name, section, semester, department)
          ''')
          .eq('date', dateStr)
          .eq('students.department', department);

      if (semester != null) {
        query = query.eq('students.semester', semester);
      }

      final response = await query;

      // Group by student and calculate periods attended
      final Map<String, Map<String, dynamic>> studentMap = {};
      
      for (final record in response) {
        final regNo = record['registration_no'] as String;
        final student = record['students'];
        
        if (!studentMap.containsKey(regNo)) {
          studentMap[regNo] = {
            'registration_no': regNo,
            'student_name': student['student_name'],
            'section': student['section'],
            'is_present': false,
            'periods_attended': 0,
            'total_periods': 0,
          };
        }
        
        studentMap[regNo]!['total_periods'] = (studentMap[regNo]!['total_periods'] as int) + 1;
        if (record['is_present'] == true) {
          studentMap[regNo]!['periods_attended'] = (studentMap[regNo]!['periods_attended'] as int) + 1;
          studentMap[regNo]!['is_present'] = true;
        }
      }

      return studentMap.values.toList()
        ..sort((a, b) => (a['registration_no'] as String).compareTo(b['registration_no'] as String));
    } catch (e) {
      debugPrint('Error fetching daily attendance details: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLowAttendanceStudents({
    required String department,
    int? semester,
    required double threshold,
  }) async {
    try {
      var query = _supabase
          .from('overall_attendance_summary')
          .select('''
            registration_no,
            semester,
            section,
            total_periods,
            attended_periods,
            overall_percentage
          ''')
          .ilike('department', '%$department%')
          .lt('overall_percentage', threshold);

      if (semester != null) {
        query = query.eq('semester', semester);
      }

      final response = await query.order('overall_percentage');

      // Enrich with student names
      final List<Map<String, dynamic>> enriched = [];
      for (final record in response) {
        final studentName = await _getStudentName(record['registration_no']);
        enriched.add({
          ...record,
          'student_name': studentName,
          'percentage': record['overall_percentage'],
        });
      }

      return enriched;
    } catch (e) {
      debugPrint('Error fetching low attendance students: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchMonthlyStatistics({
    required String department,
    int? semester,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Get working days count
      final workingDaysResponse = await _supabase
          .from('attendance')
          .select('date')
          .gte('date', startStr)
          .lte('date', endStr);

      final workingDays = workingDaysResponse.map((r) => r['date']).toSet().length;

      // Get attendance statistics
      var query = _supabase
          .from('overall_attendance_summary')
          .select('overall_percentage')
          .ilike('department', '%$department%');

      if (semester != null) {
        query = query.eq('semester', semester);
      }

      final statsResponse = await query;

      if (statsResponse.isEmpty) {
        return {
          'working_days': workingDays,
          'total_students': 0,
          'avg_percentage': 0.0,
          'max_percentage': 0.0,
          'min_percentage': 0.0,
          'above_90': 0,
          'between_75_90': 0,
          'between_60_75': 0,
          'below_60': 0,
        };
      }

      final percentages = statsResponse.map((r) => (r['overall_percentage'] as num).toDouble()).toList();
      
      return {
        'working_days': workingDays,
        'total_students': percentages.length,
        'avg_percentage': percentages.reduce((a, b) => a + b) / percentages.length,
        'max_percentage': percentages.reduce((a, b) => a > b ? a : b),
        'min_percentage': percentages.reduce((a, b) => a < b ? a : b),
        'above_90': percentages.where((p) => p >= 90).length,
        'between_75_90': percentages.where((p) => p >= 75 && p < 90).length,
        'between_60_75': percentages.where((p) => p >= 60 && p < 75).length,
        'below_60': percentages.where((p) => p < 60).length,
      };
    } catch (e) {
      debugPrint('Error fetching monthly statistics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjectWiseAttendance({
    required String department,
    int? semester,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      var query = _supabase
          .from('attendance_summary')
          .select('''
            subject_code,
            subjects!inner(subject_name),
            total_periods,
            attended_periods
          ''')
          .eq('subjects.department', department)
          .gte('date', startStr)
          .lte('date', endStr);

      if (semester != null) {
        query = query.eq('subjects.semester', semester);
      }

      final response = await query;

      // Group by subject
      final Map<String, Map<String, dynamic>> subjectMap = {};
      
      for (final record in response) {
        final subjectCode = record['subject_code'] as String;
        
        if (!subjectMap.containsKey(subjectCode)) {
          subjectMap[subjectCode] = {
            'subject_code': subjectCode,
            'subject_name': record['subjects']['subject_name'],
            'total_classes': 0,
            'total_attended': 0,
          };
        }
        
        subjectMap[subjectCode]!['total_classes'] = 
            (subjectMap[subjectCode]!['total_classes'] as int) + (record['total_periods'] as int? ?? 0);
        subjectMap[subjectCode]!['total_attended'] = 
            (subjectMap[subjectCode]!['total_attended'] as int) + (record['attended_periods'] as int? ?? 0);
      }

      return subjectMap.values.map((subject) {
        final total = subject['total_classes'] as int;
        final attended = subject['total_attended'] as int;
        return {
          ...subject,
          'avg_attendance': total > 0 ? (attended / total) * 100 : 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching subject-wise attendance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDailyTrends({
    required String department,
    int? semester,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      // This is a simplified query - adjust based on your actual schema
      final response = await _supabase.rpc('get_daily_attendance_trends', params: {
        'p_department': department,
        'p_semester': semester,
        'p_start_date': startStr,
        'p_end_date': endStr,
      }).catchError((e) {
        debugPrint('RPC not available, using fallback query');
        return <dynamic>[];
      });

      if (response is List && response.isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }

      // Fallback: return empty trends if RPC doesn't exist
      return [];
    } catch (e) {
      debugPrint('Error fetching daily trends: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSemesterConsolidation({
    required String department,
    required int semester,
    String? section,
  }) async {
    try {
      var query = _supabase
          .from('overall_attendance_summary')
          .select('''
            registration_no,
            section,
            total_periods,
            attended_periods,
            overall_percentage
          ''')
          .ilike('department', '%$department%')
          .eq('semester', semester);

      if (section != null) {
        query = query.eq('section', section);
      }

      final response = await query.order('registration_no');

      // Enrich with student names
      final List<Map<String, dynamic>> enriched = [];
      for (final record in response) {
        final studentName = await _getStudentName(record['registration_no']);
        enriched.add({
          ...record,
          'student_name': studentName,
          'percentage': record['overall_percentage'],
        });
      }

      return enriched;
    } catch (e) {
      debugPrint('Error fetching semester consolidation: $e');
      return [];
    }
  }

  Future<String> _getStudentName(String registrationNo) async {
    try {
      final response = await _supabase
          .from('students')
          .select('student_name')
          .eq('registration_no', registrationNo)
          .maybeSingle();
      
      return response?['student_name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  String _getAttendanceStatus(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Average';
    return 'Poor';
  }

  double _calcPercentage(int count, int total) {
    if (total == 0) return 0.0;
    return (count / total) * 100;
  }

  /// Store generated report in Supabase Storage
  Future<String?> storeReportInStorage({
    required Uint8List pdfBytes,
    required ReportType type,
    required String department,
    required DateTime generatedAt,
  }) async {
    try {
      final fileName = '${type.name}_${department.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.pdf';
      final path = 'reports/${generatedAt.year}/${generatedAt.month}/$fileName';

      await _supabase.storage.from('reports').uploadBinary(path, pdfBytes);

      final publicUrl = _supabase.storage.from('reports').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error storing report: $e');
      return null;
    }
  }

  /// Log report generation for audit trail
  Future<void> logReportGeneration({
    required ReportType type,
    required String department,
    int? semester,
    required String generatedBy,
    String? fileUrl,
  }) async {
    try {
      await _supabase.from('report_logs').insert({
        'report_type': type.name,
        'department': department,
        'semester': semester,
        'generated_by': generatedBy,
        'file_url': fileUrl,
        'generated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging report generation: $e');
    }
  }
}
