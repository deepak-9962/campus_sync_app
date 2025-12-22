import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart' as report_service;
import '../../services/report_scheduler_service.dart';
import '../../services/hod_service.dart';

// Re-export types from report_service for convenience
typedef ReportType = report_service.ReportType;
typedef ReportFrequency = report_service.ReportFrequency;
typedef ReportConfig = report_service.ReportConfig;

class AutomatedReportsScreen extends StatefulWidget {
  final String department;
  final int? semester;

  const AutomatedReportsScreen({
    Key? key,
    required this.department,
    this.semester,
  }) : super(key: key);

  @override
  State<AutomatedReportsScreen> createState() => _AutomatedReportsScreenState();
}

class _AutomatedReportsScreenState extends State<AutomatedReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportSchedulerService _schedulerService = ReportSchedulerService();
  final HODService _hodService = HODService();

  List<Map<String, dynamic>> _scheduledReports = [];
  List<Map<String, dynamic>> _reportHistory = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduled = await _schedulerService.getScheduledReports(
        department: widget.department,
      );
      final history = await _schedulerService.getReportHistory(
        department: widget.department,
        limit: 50,
      );

      setState(() {
        _scheduledReports = scheduled;
        _reportHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Reports'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flash_on), text: 'Generate Now'),
            Tab(icon: Icon(Icons.schedule), text: 'Scheduled'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGenerateNowTab(),
                    _buildScheduledTab(),
                    _buildHistoryTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateScheduleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Report'),
            )
          : null,
    );
  }

  // ============================================================================
  // GENERATE NOW TAB
  // ============================================================================

  Widget _buildGenerateNowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildReportCard(
            title: 'Daily Attendance Report',
            description: 'Generate today\'s attendance summary with present/absent counts for all students.',
            icon: Icons.today,
            color: Colors.blue,
            onGenerate: _generateDailyReport,
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Weekly Low Attendance Report',
            description: 'List of students with attendance below 75% requiring immediate attention.',
            icon: Icons.warning_amber,
            color: Colors.orange,
            onGenerate: _generateWeeklyReport,
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Monthly Analytics Report',
            description: 'Comprehensive attendance analytics with trends and subject-wise breakdown.',
            icon: Icons.analytics,
            color: Colors.purple,
            onGenerate: _generateMonthlyReport,
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Semester Consolidation Report',
            description: 'Final attendance compilation for semester-end submission with eligibility status.',
            icon: Icons.school,
            color: Colors.teal,
            onGenerate: _generateSemesterReport,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.department,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (widget.semester != null)
                    Text(
                      'Semester ${widget.semester}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.8)),
                    ),
                  Text(
                    'Reports will be generated for this department',
                    style: TextStyle(fontSize: 12, color: colorScheme.onPrimaryContainer.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onGenerate,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isGenerating ? null : onGenerate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateDailyReport() async {
    await _generateAndShowReport(
      title: 'Daily Attendance Report',
      generator: () => _schedulerService.generateDailyReportNow(
        department: widget.department,
        semester: widget.semester,
      ),
    );
  }

  Future<void> _generateWeeklyReport() async {
    await _generateAndShowReport(
      title: 'Weekly Low Attendance Report',
      generator: () => _schedulerService.generateWeeklyReportNow(
        department: widget.department,
        semester: widget.semester,
      ),
    );
  }

  Future<void> _generateMonthlyReport() async {
    await _generateAndShowReport(
      title: 'Monthly Analytics Report',
      generator: () => _schedulerService.generateMonthlyReportNow(
        department: widget.department,
        semester: widget.semester,
      ),
    );
  }

  Future<void> _generateSemesterReport() async {
    // Show semester selection dialog if not specified
    int? semester = widget.semester;
    if (semester == null) {
      semester = await _showSemesterSelectionDialog();
      if (semester == null) return;
    }

    await _generateAndShowReport(
      title: 'Semester Consolidation Report',
      generator: () => _schedulerService.generateSemesterReportNow(
        department: widget.department,
        semester: semester!,
      ),
    );
  }

  Future<void> _generateAndShowReport({
    required String title,
    required Future<dynamic> Function() generator,
  }) async {
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await generator();

      if (pdfBytes == null) {
        _showSnackBar('Failed to generate report', isError: true);
        return;
      }

      // Show PDF preview/print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: '$title - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      );

      _showSnackBar('$title generated successfully!');
      
      // Refresh history
      _loadData();
    } catch (e) {
      _showSnackBar('Error generating report: $e', isError: true);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<int?> _showSemesterSelectionDialog() async {
    int? selectedSemester;
    
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Semester'),
        content: DropdownButtonFormField<int>(
          value: selectedSemester,
          decoration: const InputDecoration(
            labelText: 'Semester',
            border: OutlineInputBorder(),
          ),
          items: List.generate(8, (i) => i + 1)
              .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
              .toList(),
          onChanged: (value) => selectedSemester = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedSemester),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SCHEDULED TAB
  // ============================================================================

  Widget _buildScheduledTab() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_scheduledReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No Scheduled Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up automated reports to be generated\nand sent automatically',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateScheduleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scheduledReports.length,
      itemBuilder: (context, index) {
        final schedule = _scheduledReports[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final colorScheme = Theme.of(context).colorScheme;
    final reportType = _getReportTypeDisplay(schedule['report_type']);
    final frequency = _getFrequencyDisplay(schedule['frequency']);
    final isEnabled = schedule['enabled'] ?? true;
    final nextRun = schedule['next_run'] != null
        ? DateTime.parse(schedule['next_run'])
        : null;
    final lastRun = schedule['last_run'] != null
        ? DateTime.parse(schedule['last_run'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReportTypeIcon(schedule['report_type']),
                color: isEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            title: Text(
              reportType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(frequency),
                if (schedule['semester'] != null)
                  Text('Semester ${schedule['semester']}'),
              ],
            ),
            trailing: Switch(
              value: isEnabled,
              onChanged: (value) => _toggleSchedule(schedule['id'], value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Run',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      Text(
                        nextRun != null
                            ? DateFormat('MMM d, yyyy HH:mm').format(nextRun)
                            : 'Not scheduled',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Run',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      Text(
                        lastRun != null
                            ? DateFormat('MMM d, yyyy HH:mm').format(lastRun)
                            : 'Never',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Run Now',
                  onPressed: () => _runScheduleNow(schedule),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => _showEditScheduleDialog(schedule),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDeleteSchedule(schedule['id']),
                ),
              ],
            ),
          ),
          // Recipients section
          if (schedule['recipients'] != null &&
              (schedule['recipients'] as List).isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Icon(Icons.email, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                  ...List<String>.from(schedule['recipients']).map(
                    (email) => Chip(
                      label: Text(email, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateScheduleDialog() async {
    final result = await showDialog<ReportConfig>(
      context: context,
      builder: (context) => _ScheduleConfigDialog(
        department: widget.department,
        semester: widget.semester,
      ),
    );

    if (result != null) {
      final success = await _schedulerService.createScheduledReport(result);
      if (success) {
        _showSnackBar('Schedule created successfully!');
        _loadData();
      } else {
        _showSnackBar('Failed to create schedule', isError: true);
      }
    }
  }

  Future<void> _showEditScheduleDialog(Map<String, dynamic> schedule) async {
    final result = await showDialog<ReportConfig>(
      context: context,
      builder: (context) => _ScheduleConfigDialog(
        department: widget.department,
        semester: widget.semester,
        existingConfig: schedule,
      ),
    );

    if (result != null) {
      final success = await _schedulerService.updateScheduledReport(
        schedule['id'],
        result,
      );
      if (success) {
        _showSnackBar('Schedule updated successfully!');
        _loadData();
      } else {
        _showSnackBar('Failed to update schedule', isError: true);
      }
    }
  }

  Future<void> _toggleSchedule(String id, bool enabled) async {
    final success = await _schedulerService.toggleReportStatus(id, enabled);
    if (success) {
      _loadData();
    } else {
      _showSnackBar('Failed to update schedule', isError: true);
    }
  }

  Future<void> _runScheduleNow(Map<String, dynamic> schedule) async {
    setState(() => _isGenerating = true);

    try {
      final result = await _schedulerService.executeReport(schedule);
      
      if (result['success'] == true) {
        // Show the generated PDF
        await Printing.layoutPdf(
          onLayout: (format) async => result['pdfBytes'],
          name: result['reportTitle'],
        );
        _showSnackBar('Report generated successfully!');
        _loadData();
      } else {
        _showSnackBar('Failed to generate report: ${result['error']}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _confirmDeleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this scheduled report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _schedulerService.deleteScheduledReport(id);
      if (success) {
        _showSnackBar('Schedule deleted');
        _loadData();
      } else {
        _showSnackBar('Failed to delete schedule', isError: true);
      }
    }
  }

  // ============================================================================
  // HISTORY TAB
  // ============================================================================

  Widget _buildHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_reportHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No Report History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generated reports will appear here',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportHistory.length,
      itemBuilder: (context, index) {
        final log = _reportHistory[index];
        return _buildHistoryCard(log);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    final colorScheme = Theme.of(context).colorScheme;
    final reportType = _getReportTypeDisplay(log['report_type']);
    final generatedAt = DateTime.parse(log['generated_at']);
    final hasFile = log['file_url'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getReportTypeIcon(log['report_type']),
            color: colorScheme.primary,
          ),
        ),
        title: Text(reportType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, yyyy HH:mm').format(generatedAt)),
            if (log['generated_by'] != null)
              Text(
                'By: ${log['generated_by']}',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        trailing: hasFile
            ? IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadReport(log['file_url']),
              )
            : null,
      ),
    );
  }

  Future<void> _downloadReport(String url) async {
    // TODO: Implement download functionality
    _showSnackBar('Download started...');
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getReportTypeDisplay(String? type) {
    switch (type) {
      case 'dailyAttendance':
        return 'Daily Attendance Report';
      case 'weeklyLowAttendance':
        return 'Weekly Low Attendance Report';
      case 'monthlyAnalytics':
        return 'Monthly Analytics Report';
      case 'semesterConsolidation':
        return 'Semester Consolidation Report';
      default:
        return 'Unknown Report';
    }
  }

  IconData _getReportTypeIcon(String? type) {
    switch (type) {
      case 'dailyAttendance':
        return Icons.today;
      case 'weeklyLowAttendance':
        return Icons.warning_amber;
      case 'monthlyAnalytics':
        return Icons.analytics;
      case 'semesterConsolidation':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  String _getFrequencyDisplay(String? frequency) {
    switch (frequency) {
      case 'daily':
        return 'Every day at 5:00 PM';
      case 'weekly':
        return 'Every Monday';
      case 'monthly':
        return '1st of every month';
      case 'semesterEnd':
        return 'At semester end';
      default:
        return 'Unknown frequency';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ============================================================================
// SCHEDULE CONFIG DIALOG
// ============================================================================

class _ScheduleConfigDialog extends StatefulWidget {
  final String department;
  final int? semester;
  final Map<String, dynamic>? existingConfig;

  const _ScheduleConfigDialog({
    required this.department,
    this.semester,
    this.existingConfig,
  });

  @override
  State<_ScheduleConfigDialog> createState() => _ScheduleConfigDialogState();
}

class _ScheduleConfigDialogState extends State<_ScheduleConfigDialog> {
  late ReportType _selectedType;
  late ReportFrequency _selectedFrequency;
  late TimeOfDay _selectedTime;
  int? _selectedSemester;
  final List<String> _recipients = [];
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if (widget.existingConfig != null) {
      _selectedType = ReportType.values.firstWhere(
        (e) => e.name == widget.existingConfig!['report_type'],
        orElse: () => ReportType.dailyAttendance,
      );
      _selectedFrequency = ReportFrequency.values.firstWhere(
        (e) => e.name == widget.existingConfig!['frequency'],
        orElse: () => ReportFrequency.daily,
      );
      _selectedTime = TimeOfDay(
        hour: widget.existingConfig!['scheduled_hour'] ?? 17,
        minute: widget.existingConfig!['scheduled_minute'] ?? 0,
      );
      _selectedSemester = widget.existingConfig!['semester'];
      if (widget.existingConfig!['recipients'] != null) {
        _recipients.addAll(List<String>.from(widget.existingConfig!['recipients']));
      }
    } else {
      _selectedType = ReportType.dailyAttendance;
      _selectedFrequency = ReportFrequency.daily;
      _selectedTime = const TimeOfDay(hour: 17, minute: 0);
      _selectedSemester = widget.semester;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingConfig != null ? 'Edit Schedule' : 'Create Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Type
            DropdownButtonFormField<ReportType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Report Type',
                border: OutlineInputBorder(),
              ),
              items: ReportType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getReportTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    // Auto-select appropriate frequency
                    switch (value) {
                      case ReportType.dailyAttendance:
                        _selectedFrequency = ReportFrequency.daily;
                        break;
                      case ReportType.weeklyLowAttendance:
                        _selectedFrequency = ReportFrequency.weekly;
                        break;
                      case ReportType.monthlyAnalytics:
                        _selectedFrequency = ReportFrequency.monthly;
                        break;
                      case ReportType.semesterConsolidation:
                        _selectedFrequency = ReportFrequency.semesterEnd;
                        break;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Frequency
            DropdownButtonFormField<ReportFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ReportFrequency.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(_getFrequencyLabel(freq)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFrequency = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Semester (optional)
            DropdownButtonFormField<int?>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Semesters')),
                ...List.generate(8, (i) => i + 1).map(
                  (s) => DropdownMenuItem(value: s, child: Text('Semester $s')),
                ),
              ],
              onChanged: (value) => setState(() => _selectedSemester = value),
            ),
            const SizedBox(height: 16),

            // Time Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Scheduled Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),
            const Divider(),

            // Recipients
            const Text('Email Recipients', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRecipient,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _recipients.map((email) {
                return Chip(
                  label: Text(email, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _recipients.remove(email)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSchedule,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addRecipient() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && email.contains('@') && !_recipients.contains(email)) {
      setState(() {
        _recipients.add(email);
        _emailController.clear();
      });
    }
  }

  void _saveSchedule() {
    final config = ReportConfig(
      type: _selectedType,
      department: widget.department,
      semester: _selectedSemester,
      recipients: _recipients,
      frequency: _selectedFrequency,
      scheduledTime: report_service.TimeOfDay(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      ),
    );
    Navigator.pop(context, config);
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.dailyAttendance:
        return 'Daily Attendance';
      case ReportType.weeklyLowAttendance:
        return 'Weekly Low Attendance';
      case ReportType.monthlyAnalytics:
        return 'Monthly Analytics';
      case ReportType.semesterConsolidation:
        return 'Semester Consolidation';
    }
  }

  String _getFrequencyLabel(ReportFrequency freq) {
    switch (freq) {
      case ReportFrequency.daily:
        return 'Daily';
      case ReportFrequency.weekly:
        return 'Weekly (Monday)';
      case ReportFrequency.monthly:
        return 'Monthly (1st)';
      case ReportFrequency.semesterEnd:
        return 'Semester End';
    }
  }
}
