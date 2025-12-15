import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import '../services/hod_service.dart';
import 'attendance_view_screen.dart';
import 'hod/pdf_export_screen.dart';
import 'hod/automated_reports_screen.dart';

class HODDashboardScreen extends StatefulWidget {
  final String department;
  final String hodName;
  final int? selectedSemester; // Optional semester filter

  const HODDashboardScreen({
    Key? key,
    required this.department,
    required this.hodName,
    this.selectedSemester, // Optional parameter
  }) : super(key: key);

  @override
  _HODDashboardScreenState createState() => _HODDashboardScreenState();
}

class _HODDashboardScreenState extends State<HODDashboardScreen> {
  final HODService _hodService = HODService();

  Map<String, dynamic> departmentSummary = {};
  List<Map<String, dynamic>> semesterWiseData = [];
  List<Map<String, dynamic>> lowAttendanceStudents = [];
  bool isLoading = true;
  String selectedView = 'summary'; // summary, semester-wise, low-attendance
  DateTime currentDate = DateTime.now();
  bool _isAdmin = false;
  String? _effectiveDepartment;
  List<String> _availableDepartments = [];
  int? _selectedSemester; // Admin-selected semester filter (nullable = All)

  @override
  void initState() {
    super.initState();
    // Clear any stale data and fetch fresh data
    _clearData();
    // Initialize semester filter from widget if provided
    _selectedSemester = widget.selectedSemester;
    _initRoleAndDepartment();
  }

  void _clearData() {
    setState(() {
      // Initialize with proper zero state for attendance counts
      departmentSummary = {
        'total_students': 0,
        'today_present': 0,
        'today_absent': 0,
        'today_percentage': 0.0,
        'low_attendance_today': 0,
        'attendance_taken': false,
      };
      semesterWiseData = [];
      lowAttendanceStudents = [];
      isLoading = true;
    });
  }

  Future<void> _initRoleAndDepartment() async {
    try {
      final role = await _hodService.getUserRoleInfo();
      final isAdmin = role['isAdmin'] == true;
      List<String> depts = [];
      if (isAdmin) {
        depts = await _hodService.getAvailableDepartments();
      }
      String eff = widget.department;
      if (isAdmin) {
        final passed = eff.toLowerCase();
        if (passed.contains('all') || passed.isEmpty) {
          eff = depts.isNotEmpty ? depts.first : eff;
        } else if (depts.isNotEmpty && !depts.contains(eff)) {
          eff = depts.first;
        }
      }
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _availableDepartments = depts;
        _effectiveDepartment = eff;
      });
      await _loadDepartmentData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _availableDepartments = [];
        _effectiveDepartment = widget.department;
      });
      await _loadDepartmentData();
    }
  }

  Future<void> _loadDepartmentData() async {
    final dept = _effectiveDepartment ?? widget.department;
    print(
      'HOD Dashboard: Loading fresh data for '
      '${currentDate.toIso8601String().split('T')[0]} dept: $dept',
    );

    setState(() {
      isLoading = true;
    });

    try {
      // Use direct table access method (RPC function doesn't exist)
      print(
        'HOD Dashboard: Loading attendance data using direct table access...',
      );

      final summary = await _hodService.getDepartmentAttendanceSummary(
        dept,
        date: currentDate,
      );

      // ENHANCED DEBUGGING: Check for error states
      if (summary.containsKey('error')) {
        print('HOD Dashboard: Service returned error - ${summary['error']}');
        print('HOD Dashboard: Error message - ${summary['error_message']}');
        setState(() {
          isLoading = false;
        });

        // Show detailed error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Access Error: ${summary['error']}'),
                Text('Details: ${summary['error_message']}'),
                const Text('Please check with your administrator.'),
              ],
            ),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('HOD Dashboard: Service returned data - $summary');

      // Load TODAY'S semester-wise data using HOD service
      final semesterData = await _hodService.getTodaySemesterWiseData(
        dept,
        selectedSemester: _selectedSemester ?? widget.selectedSemester,
        date: currentDate,
      );

      // Load students with low attendance TODAY using HOD service
      final lowAttendance = await _hodService.getTodayLowAttendanceStudents(
        dept,
        selectedSemester: _selectedSemester ?? widget.selectedSemester,
        date: currentDate,
      );

      setState(() {
        departmentSummary = summary;
        semesterWiseData = semesterData;
        lowAttendanceStudents = lowAttendance;
        isLoading = false;
      });

      print(
        'HOD Dashboard: Data loaded successfully - ${summary['total_students']} students, ${summary['today_present']} present, attendance_taken: ${summary['attendance_taken']}',
      );

      // Debug: Print semester-wise data
      for (final semData in semesterData) {
        print(
          'HOD Dashboard: Semester ${semData['semester']} - attendance_taken: ${semData['attendance_taken']}, present: ${semData['today_present']}, absent: ${semData['today_absent']}',
        );
      }

      // ENHANCED: Log detailed state for debugging
      print(
        'HOD Dashboard: Final departmentSummary state - $departmentSummary',
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print('HOD Dashboard: CRITICAL ERROR during data loading - $e');
      print('HOD Dashboard: Error type - ${e.runtimeType}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Critical Error Loading Data'),
              Text('Error: $e'),
              const Text('Please contact your administrator.'),
            ],
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (_selectedSemester ?? widget.selectedSemester) != null
                  ? 'HOD Dashboard - ${_effectiveDepartment ?? widget.department} - Semester ${_selectedSemester ?? widget.selectedSemester}'
                  : 'HOD Dashboard - ${_effectiveDepartment ?? widget.department}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Date: ${currentDate.day}/${currentDate.month}/${currentDate.year}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export/Share',
            onSelected: (value) async {
              if (value == 'csv') {
                await _exportCurrentViewCSV();
              } else if (value == 'pdf') {
                await _exportCurrentViewPDF();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('Export CSV (current view)'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('Export PDF (current view)'),
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Automated Reports',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => AutomatedReportsScreen(
                        department: _effectiveDepartment ?? widget.department,
                        semester: _selectedSemester ?? widget.selectedSemester,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Student Data to PDF',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => PDFExportScreen(
                        department: _effectiveDepartment ?? widget.department,
                        semester: _selectedSemester ?? widget.selectedSemester,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: currentDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != currentDate) {
                setState(() {
                  currentDate = picked;
                });
                _loadDepartmentData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadDepartmentData,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadDepartmentData();
                },
                child: Column(
                  children: [
                    // Header with HOD info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.hodName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Department: ${_effectiveDepartment ?? widget.department}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Admin department selection (only for Admin)
                    if (_isAdmin)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.apartment,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Department:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _effectiveDepartment,
                                      isExpanded: true,
                                      items:
                                          _availableDepartments
                                              .map(
                                                (d) => DropdownMenuItem(
                                                  value: d,
                                                  child: Text(d),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) async {
                                        if (v == null) return;
                                        setState(() {
                                          _effectiveDepartment = v;
                                        });
                                        await _loadDepartmentData();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.school, color: Colors.indigo),
                                const SizedBox(width: 8),
                                const Text(
                                  'Semester:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _selectedSemester,
                                      isExpanded: true,
                                      items: <DropdownMenuItem<int?>>[
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('All'),
                                        ),
                                        ...List.generate(8, (i) => i + 1)
                                            .map(
                                              (s) => DropdownMenuItem<int?>(
                                                value: s,
                                                child: Text('Semester $s'),
                                              ),
                                            )
                                            .toList(),
                                      ],
                                      onChanged: (v) async {
                                        setState(() {
                                          _selectedSemester = v;
                                        });
                                        await _loadDepartmentData();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Quick date chips + View selector
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      currentDate = DateTime.now();
                                    });
                                    _loadDepartmentData();
                                  },
                                  icon: const Icon(Icons.today),
                                  label: const Text('Today'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      currentDate = DateTime.now().subtract(
                                        const Duration(days: 1),
                                      );
                                    });
                                    _loadDepartmentData();
                                  },
                                  child: const Text('Yesterday'),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Pick date',
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: currentDate,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null &&
                                        picked != currentDate) {
                                      setState(() {
                                        currentDate = picked;
                                      });
                                      _loadDepartmentData();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _buildViewTab('summary', 'Summary'),
                              _buildViewTab('semester-wise', 'Semester-wise'),
                              _buildViewTab('low-attendance', 'Low Attendance'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Highly visible Actions row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;
                              return Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 180,
                                    child: ElevatedButton.icon(
                                      onPressed: _exportCurrentViewCSV,
                                      icon: const Icon(Icons.table_chart),
                                      label: const Text('Export CSV'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 180,
                                    child: ElevatedButton.icon(
                                      onPressed: _exportCurrentViewPDF,
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Export PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 180,
                                    child: ElevatedButton.icon(
                                      onPressed: _loadDepartmentData,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Refresh Data'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Content based on selected view
                    Expanded(child: _buildSelectedView()),
                  ],
                ),
              ),
    );
  }

  // ======== EXPORT HELPERS ========
  List<List<dynamic>> _buildCsvRowsForCurrentView() {
    final dateStr = currentDate.toIso8601String().split('T')[0];
    final rows = <List<dynamic>>[];

    rows.add(['Campus Sync – HOD Export']);
    rows.add(['Department', _effectiveDepartment ?? widget.department]);
    rows.add(['Date', dateStr]);
    if ((_selectedSemester ?? widget.selectedSemester) != null) {
      rows.add([
        'Semester Filter',
        (_selectedSemester ?? widget.selectedSemester),
      ]);
    }
    rows.add(['View', selectedView]);
    rows.add([]);

    if (selectedView == 'summary') {
      rows.add(['Metric', 'Value']);
      rows.add(['Total Students', departmentSummary['total_students'] ?? 0]);
      rows.add(['Today Present', departmentSummary['today_present'] ?? 0]);
      rows.add(['Today Absent', departmentSummary['today_absent'] ?? 0]);
      rows.add([
        'Today %',
        (departmentSummary['today_percentage'] ?? 0.0).toStringAsFixed(1),
      ]);
    } else if (selectedView == 'semester-wise') {
      rows.add([
        'Semester',
        'Total Students',
        'Today Present',
        'Today Absent',
        'Today %',
      ]);
      for (final s in semesterWiseData) {
        rows.add([
          s['semester'],
          s['total_students'],
          s['today_present'] ?? 0,
          s['today_absent'] ?? 0,
          (s['today_percentage'] ?? 0.0).toStringAsFixed(1),
        ]);
      }
    } else if (selectedView == 'low-attendance') {
      rows.add(['Reg No', 'Name', 'Semester', 'Section', 'Percentage']);
      for (final st in lowAttendanceStudents) {
        rows.add([
          st['registration_no'] ?? '',
          st['student_name'] ?? '',
          st['semester'] ?? '',
          st['section'] ?? '',
          (st['percentage'] ?? 0.0).toStringAsFixed(1),
        ]);
      }
    }
    return rows;
  }

  Future<void> _exportCurrentViewCSV() async {
    try {
      final rows = _buildCsvRowsForCurrentView();
      final csv = const ListToCsvConverter().convert(rows);
      final deptSlug =
          (_effectiveDepartment ?? widget.department)
              .replaceAll(' ', '_')
              .toLowerCase();
      final semPart =
          (_selectedSemester ?? widget.selectedSemester) != null
              ? 'sem${_selectedSemester ?? widget.selectedSemester}_'
              : '';
      final filename =
          'hod_${deptSlug}_${semPart}${selectedView}_${currentDate.toIso8601String().split('T')[0]}.csv';

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For non-web, fallback to share dialog via Printing (wrap CSV in a simple PDF)
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build:
                (ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HOD Export (CSV contents below)',
                      style: pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(csv, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
          ),
        );
        await Printing.sharePdf(
          bytes: await doc.save(),
          filename: filename.replaceAll('.csv', '.pdf'),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportCurrentViewPDF() async {
    try {
      final dateStr = currentDate.toIso8601String().split('T')[0];
      final doc = pw.Document();

      pw.Widget buildHeader() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Campus Sync – HOD Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Department: ${_effectiveDepartment ?? widget.department}'),
          pw.Text('Date: $dateStr'),
          if ((_selectedSemester ?? widget.selectedSemester) != null)
            pw.Text(
              'Semester Filter: ${_selectedSemester ?? widget.selectedSemester}',
            ),
          pw.Text('View: $selectedView'),
          pw.SizedBox(height: 12),
        ],
      );

      if (selectedView == 'summary') {
        doc.addPage(
          pw.Page(
            build:
                (ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    buildHeader(),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.4),
                      columnWidths: {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Metric',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Value',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Total Students'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '${departmentSummary['total_students'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Today Present'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '${departmentSummary['today_present'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Today Absent'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '${departmentSummary['today_absent'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Today %'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '${(departmentSummary['today_percentage'] ?? 0.0).toStringAsFixed(1)}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      } else if (selectedView == 'semester-wise') {
        doc.addPage(
          pw.Page(
            build:
                (ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    buildHeader(),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.4),
                      columnWidths: {
                        0: pw.FlexColumnWidth(1),
                        1: pw.FlexColumnWidth(2),
                        2: pw.FlexColumnWidth(2),
                        3: pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Sem',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Total Students',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Today P/A',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Today %',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...semesterWiseData.map(
                          (s) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${s['semester']}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${s['total_students']}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  '${s['today_present'] ?? 0} / ${s['today_absent'] ?? 0}',
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  '${(s['today_percentage'] ?? 0.0).toStringAsFixed(1)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      } else if (selectedView == 'low-attendance') {
        doc.addPage(
          pw.Page(
            build:
                (ctx) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    buildHeader(),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.4),
                      columnWidths: {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(3),
                        2: pw.FlexColumnWidth(1),
                        3: pw.FlexColumnWidth(1),
                        4: pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Reg No',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Name',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Sem',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Sec',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                '%',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...lowAttendanceStudents.map(
                          (st) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  '${st['registration_no'] ?? ''}',
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${st['student_name'] ?? ''}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${st['semester'] ?? ''}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${st['section'] ?? ''}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  '${(st['percentage'] ?? 0.0).toStringAsFixed(1)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      }

      final bytes = await doc.save();
      final deptSlug =
          (_effectiveDepartment ?? widget.department)
              .replaceAll(' ', '_')
              .toLowerCase();
      final semPart =
          (_selectedSemester ?? widget.selectedSemester) != null
              ? 'sem${_selectedSemester ?? widget.selectedSemester}_'
              : '';
      final filename =
          'hod_${deptSlug}_${semPart}${selectedView}_${dateStr}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }

  Widget _buildViewTab(String value, String label) {
    final isSelected = selectedView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedView = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo[700] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (selectedView) {
      case 'summary':
        return _buildSummaryView();
      case 'semester-wise':
        return _buildSemesterWiseView();
      case 'low-attendance':
        return _buildLowAttendanceView();
      default:
        return _buildSummaryView();
    }
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Students',
                  '${departmentSummary['total_students'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Overall Avg Attendance',
                  '${(departmentSummary['avg_attendance'] ?? 0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Today Present',
                  departmentSummary['attendance_taken'] == false
                      ? 'Not Taken'
                      : '${departmentSummary['today_present'] ?? 0}',
                  Icons.check_circle,
                  departmentSummary['attendance_taken'] == false
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Today Absent',
                  departmentSummary['attendance_taken'] == false
                      ? 'Not Taken'
                      : '${departmentSummary['today_absent'] ?? 0}',
                  Icons.cancel,
                  departmentSummary['attendance_taken'] == false
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Low Attendance Students (<75%)',
            '${departmentSummary['low_attendance_students'] ?? 0}',
            Icons.warning,
            Colors.orange,
            isFullWidth: true,
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedView = 'semester-wise';
                            });
                          },
                          icon: const Icon(Icons.school),
                          label: const Text('View by Semester'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedView = 'low-attendance';
                            });
                          },
                          icon: const Icon(Icons.warning),
                          label: const Text('Low Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              isFullWidth
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isFullWidth
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isFullWidth ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterWiseView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: semesterWiseData.length,
      itemBuilder: (context, index) {
        final semester = semesterWiseData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo[700],
              child: Text(
                '${semester['semester']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Semester ${semester['semester']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _buildAttendanceTakenBadge(
                  (semester['attendance_taken'] ?? false) == true,
                ),
              ],
            ),
            subtitle: Text(
              'Students: ${semester['total_students']} | Today: ${semester['today_present'] ?? 0}P/${semester['today_absent'] ?? 0}A/${semester['today_na'] ?? 0}N/A | Avg: ${(semester['today_percentage'] ?? 0.0).toStringAsFixed(1)}%',
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            'Total Students',
                            '${semester['total_students']}',
                            Icons.people,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Today Present',
                            semester['attendance_taken'] == false
                                ? 'Not Taken'
                                : '${semester['today_present'] ?? 0}',
                            Icons.check_circle,
                            color:
                                semester['attendance_taken'] == false
                                    ? Colors.grey
                                    : Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Today Absent',
                            semester['attendance_taken'] == false
                                ? 'Not Taken'
                                : '${semester['today_absent'] ?? 0}',
                            Icons.cancel,
                            color:
                                semester['attendance_taken'] == false
                                    ? Colors.grey
                                    : Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Today\'s Avg',
                            '${(semester['today_percentage'] ?? 0.0).toStringAsFixed(1)}%',
                            Icons.analytics,
                            color:
                                (semester['today_percentage'] ?? 0.0) >= 75.0
                                    ? Colors.green
                                    : (semester['today_percentage'] ?? 0.0) >=
                                        50.0
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Today's attendance row for this semester
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            'Present',
                            '${semester['today_present'] ?? 0}',
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Absent',
                            '${semester['today_absent'] ?? 0}',
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'N/A',
                            '${semester['today_na'] ?? 0}',
                            Icons.remove_circle_outline,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Records',
                            '${(semester['today_present'] ?? 0) + (semester['today_absent'] ?? 0)}',
                            Icons.fact_check,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showDetailedSemesterView(semester);
                        },
                        child: const Text('View Detailed Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTakenBadge(bool taken) {
    final Color bg = taken ? Colors.green[50]! : Colors.grey[200]!;
    final Color fg = taken ? Colors.green[700]! : Colors.grey[700]!;
    final IconData icon = taken ? Icons.check_circle : Icons.schedule;
    final String label = taken ? 'Taken' : 'Not Taken';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowAttendanceView() {
    if (lowAttendanceStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            const Text(
              'Great! No students with low attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All students have attendance ≥ 75%',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowAttendanceStudents.length,
      itemBuilder: (context, index) {
        final student = lowAttendanceStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[400],
              child: Text(
                '${student['percentage']?.toStringAsFixed(0) ?? '0'}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(student['student_name'] ?? 'Unknown'),
            subtitle: Text(
              'Reg: ${student['registration_no']} | Sem: ${student['semester']} | Sec: ${student['section']}',
            ),
            trailing: Icon(Icons.warning, color: Colors.red[400]),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final displayColor = color ?? Colors.indigo[700]!;
    return Column(
      children: [
        Icon(icon, color: displayColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: displayColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showDetailedSemesterView(Map<String, dynamic> semester) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AttendanceViewScreen(
              department: _effectiveDepartment ?? widget.department,
              semester: semester['semester'] as int,
            ),
      ),
    );
  }
}
