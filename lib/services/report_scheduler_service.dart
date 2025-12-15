import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'report_service.dart';

/// Service for managing scheduled reports and their automation
class ReportSchedulerService {
  final _supabase = Supabase.instance.client;
  final _reportService = ReportService();

  // ============================================================================
  // SCHEDULED REPORT MANAGEMENT
  // ============================================================================

  /// Get all scheduled reports for a department
  Future<List<Map<String, dynamic>>> getScheduledReports({
    String? department,
  }) async {
    try {
      final query = _supabase
          .from('scheduled_reports')
          .select('*');

      final response = department != null
          ? await query.eq('department', department).order('created_at', ascending: false)
          : await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching scheduled reports: $e');
      return [];
    }
  }

  /// Create a new scheduled report
  Future<bool> createScheduledReport(ReportConfig config) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final nextRun = _calculateNextRun(config.frequency, config.scheduledTime);

      await _supabase.from('scheduled_reports').insert({
        'report_type': config.type.name,
        'department': config.department,
        'semester': config.semester,
        'section': config.section,
        'recipients': config.recipients,
        'frequency': config.frequency.name,
        'scheduled_hour': config.scheduledTime.hour,
        'scheduled_minute': config.scheduledTime.minute,
        'enabled': config.enabled,
        'created_by': user.id,
        'next_run': nextRun.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating scheduled report: $e');
      return false;
    }
  }

  /// Update an existing scheduled report
  Future<bool> updateScheduledReport(String id, ReportConfig config) async {
    try {
      final nextRun = _calculateNextRun(config.frequency, config.scheduledTime);

      await _supabase.from('scheduled_reports').update({
        'report_type': config.type.name,
        'department': config.department,
        'semester': config.semester,
        'section': config.section,
        'recipients': config.recipients,
        'frequency': config.frequency.name,
        'scheduled_hour': config.scheduledTime.hour,
        'scheduled_minute': config.scheduledTime.minute,
        'enabled': config.enabled,
        'next_run': nextRun.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      return true;
    } catch (e) {
      debugPrint('Error updating scheduled report: $e');
      return false;
    }
  }

  /// Delete a scheduled report
  Future<bool> deleteScheduledReport(String id) async {
    try {
      await _supabase.from('scheduled_reports').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting scheduled report: $e');
      return false;
    }
  }

  /// Toggle report enabled status
  Future<bool> toggleReportStatus(String id, bool enabled) async {
    try {
      await _supabase.from('scheduled_reports').update({
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error toggling report status: $e');
      return false;
    }
  }

  // ============================================================================
  // REPORT EXECUTION
  // ============================================================================

  /// Execute a scheduled report manually
  Future<Map<String, dynamic>> executeReport(Map<String, dynamic> schedule) async {
    try {
      final type = ReportType.values.firstWhere(
        (e) => e.name == schedule['report_type'],
        orElse: () => ReportType.dailyAttendance,
      );

      final department = schedule['department'] as String;
      final semester = schedule['semester'] as int?;
      final section = schedule['section'] as String?;

      Uint8List pdfBytes;
      String reportTitle;

      switch (type) {
        case ReportType.dailyAttendance:
          pdfBytes = await _reportService.generateDailyAttendanceReport(
            department: department,
            semester: semester,
          );
          reportTitle = 'Daily Attendance Report';
          break;

        case ReportType.weeklyLowAttendance:
          pdfBytes = await _reportService.generateWeeklyLowAttendanceReport(
            department: department,
            semester: semester,
          );
          reportTitle = 'Weekly Low Attendance Report';
          break;

        case ReportType.monthlyAnalytics:
          pdfBytes = await _reportService.generateMonthlyAnalyticsReport(
            department: department,
            semester: semester,
          );
          reportTitle = 'Monthly Analytics Report';
          break;

        case ReportType.semesterConsolidation:
          pdfBytes = await _reportService.generateSemesterConsolidationReport(
            department: department,
            semester: semester ?? 1,
            section: section,
            academicYear: _getCurrentAcademicYear(),
          );
          reportTitle = 'Semester Consolidation Report';
          break;
      }

      // Store the report
      final fileUrl = await _reportService.storeReportInStorage(
        pdfBytes: pdfBytes,
        type: type,
        department: department,
        generatedAt: DateTime.now(),
      );

      // Update last run time
      await _updateLastRun(schedule['id'] as String);

      // Log the execution
      final user = _supabase.auth.currentUser;
      await _reportService.logReportGeneration(
        type: type,
        department: department,
        semester: semester,
        generatedBy: user?.email ?? 'system',
        fileUrl: fileUrl,
      );

      // Queue email sending (via Edge Function)
      if (schedule['recipients'] != null && (schedule['recipients'] as List).isNotEmpty) {
        await _queueEmailDelivery(
          reportTitle: reportTitle,
          recipients: List<String>.from(schedule['recipients']),
          fileUrl: fileUrl,
          department: department,
        );
      }

      return {
        'success': true,
        'pdfBytes': pdfBytes,
        'fileUrl': fileUrl,
        'reportTitle': reportTitle,
      };
    } catch (e) {
      debugPrint('Error executing report: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check and execute due reports (called from app or Edge Function)
  Future<List<Map<String, dynamic>>> executeDueReports() async {
    try {
      final now = DateTime.now();

      // Get all enabled reports that are due
      final dueReports = await _supabase
          .from('scheduled_reports')
          .select('*')
          .eq('enabled', true)
          .lte('next_run', now.toIso8601String());

      final results = <Map<String, dynamic>>[];

      for (final schedule in dueReports) {
        final result = await executeReport(schedule);
        results.add({
          'schedule_id': schedule['id'],
          'report_type': schedule['report_type'],
          ...result,
        });
      }

      return results;
    } catch (e) {
      debugPrint('Error executing due reports: $e');
      return [];
    }
  }

  // ============================================================================
  // REPORT HISTORY
  // ============================================================================

  /// Get report generation history
  Future<List<Map<String, dynamic>>> getReportHistory({
    String? department,
    ReportType? type,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('report_logs')
          .select('*');

      // Apply filters first
      if (department != null) {
        query = query.eq('department', department);
      }

      if (type != null) {
        query = query.eq('report_type', type.name);
      }

      // Then apply ordering and limit
      final response = await query
          .order('generated_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching report history: $e');
      return [];
    }
  }

  /// Get pending email deliveries
  Future<List<Map<String, dynamic>>> getPendingEmails() async {
    try {
      final response = await _supabase
          .from('email_queue')
          .select('*')
          .eq('status', 'pending')
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching pending emails: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  DateTime _calculateNextRun(ReportFrequency frequency, TimeOfDay time) {
    final now = DateTime.now();
    DateTime nextRun;

    switch (frequency) {
      case ReportFrequency.daily:
        // Next occurrence at scheduled time
        nextRun = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 1));
        }
        break;

      case ReportFrequency.weekly:
        // Next Monday at scheduled time
        int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
        if (daysUntilMonday == 0 && now.hour >= time.hour) {
          daysUntilMonday = 7;
        }
        nextRun = DateTime(now.year, now.month, now.day + daysUntilMonday, time.hour, time.minute);
        break;

      case ReportFrequency.monthly:
        // 1st of next month at scheduled time
        if (now.day == 1 && now.hour < time.hour) {
          nextRun = DateTime(now.year, now.month, 1, time.hour, time.minute);
        } else {
          final nextMonth = now.month == 12 
              ? DateTime(now.year + 1, 1, 1, time.hour, time.minute)
              : DateTime(now.year, now.month + 1, 1, time.hour, time.minute);
          nextRun = nextMonth;
        }
        break;

      case ReportFrequency.semesterEnd:
        // End of semester (approximate: June 30 or December 31)
        if (now.month <= 6) {
          nextRun = DateTime(now.year, 6, 30, time.hour, time.minute);
        } else {
          nextRun = DateTime(now.year, 12, 31, time.hour, time.minute);
        }
        if (nextRun.isBefore(now)) {
          nextRun = DateTime(now.year + 1, 6, 30, time.hour, time.minute);
        }
        break;
    }

    return nextRun;
  }

  Future<void> _updateLastRun(String scheduleId) async {
    try {
      final schedule = await _supabase
          .from('scheduled_reports')
          .select('frequency, scheduled_hour, scheduled_minute')
          .eq('id', scheduleId)
          .single();

      final frequency = ReportFrequency.values.firstWhere(
        (e) => e.name == schedule['frequency'],
      );
      final time = TimeOfDay(
        hour: schedule['scheduled_hour'],
        minute: schedule['scheduled_minute'],
      );

      final nextRun = _calculateNextRun(frequency, time);

      await _supabase.from('scheduled_reports').update({
        'last_run': DateTime.now().toIso8601String(),
        'next_run': nextRun.toIso8601String(),
        'run_count': _supabase.rpc('increment_run_count', params: {'row_id': scheduleId}),
      }).eq('id', scheduleId);
    } catch (e) {
      debugPrint('Error updating last run: $e');
      // Fallback update without increment
      await _supabase.from('scheduled_reports').update({
        'last_run': DateTime.now().toIso8601String(),
      }).eq('id', scheduleId);
    }
  }

  Future<void> _queueEmailDelivery({
    required String reportTitle,
    required List<String> recipients,
    String? fileUrl,
    required String department,
  }) async {
    try {
      for (final recipient in recipients) {
        await _supabase.from('email_queue').insert({
          'recipient': recipient,
          'subject': '$reportTitle - $department',
          'body': _buildEmailBody(reportTitle, department, fileUrl),
          'attachment_url': fileUrl,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error queuing email: $e');
    }
  }

  String _buildEmailBody(String reportTitle, String department, String? fileUrl) {
    final now = DateFormat('MMMM d, yyyy').format(DateTime.now());
    return '''
Dear Sir/Madam,

Please find attached the $reportTitle for $department, generated on $now.

${fileUrl != null ? 'You can also download the report from: $fileUrl' : ''}

This is an automated report from Campus Sync.

Best regards,
Campus Sync System
''';
  }

  String _getCurrentAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${(startYear + 1) % 100}';
  }

  // ============================================================================
  // QUICK GENERATION METHODS (for manual triggering)
  // ============================================================================

  /// Generate and download daily attendance report immediately
  Future<Uint8List?> generateDailyReportNow({
    required String department,
    int? semester,
  }) async {
    try {
      return await _reportService.generateDailyAttendanceReport(
        department: department,
        semester: semester,
      );
    } catch (e) {
      debugPrint('Error generating daily report: $e');
      return null;
    }
  }

  /// Generate and download weekly low attendance report immediately
  Future<Uint8List?> generateWeeklyReportNow({
    required String department,
    int? semester,
    double threshold = 75.0,
  }) async {
    try {
      return await _reportService.generateWeeklyLowAttendanceReport(
        department: department,
        semester: semester,
        threshold: threshold,
      );
    } catch (e) {
      debugPrint('Error generating weekly report: $e');
      return null;
    }
  }

  /// Generate and download monthly analytics report immediately
  Future<Uint8List?> generateMonthlyReportNow({
    required String department,
    int? semester,
  }) async {
    try {
      return await _reportService.generateMonthlyAnalyticsReport(
        department: department,
        semester: semester,
      );
    } catch (e) {
      debugPrint('Error generating monthly report: $e');
      return null;
    }
  }

  /// Generate and download semester consolidation report immediately
  Future<Uint8List?> generateSemesterReportNow({
    required String department,
    required int semester,
    String? section,
  }) async {
    try {
      return await _reportService.generateSemesterConsolidationReport(
        department: department,
        semester: semester,
        section: section,
        academicYear: _getCurrentAcademicYear(),
      );
    } catch (e) {
      debugPrint('Error generating semester report: $e');
      return null;
    }
  }
}
