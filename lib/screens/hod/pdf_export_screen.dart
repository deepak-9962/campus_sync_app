import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import '../../services/hod_service.dart';

class PDFExportScreen extends StatefulWidget {
  final String department;
  final int? semester;
  final String? section;

  const PDFExportScreen({
    Key? key,
    required this.department,
    this.semester,
    this.section,
  }) : super(key: key);

  @override
  State<PDFExportScreen> createState() => _PDFExportScreenState();
}

class _PDFExportScreenState extends State<PDFExportScreen> {
  final HODService _hodService = HODService();
  List<String> _allColumns = [];
  Map<String, bool> _selectedColumns = {};
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String _reportType = 'student_data'; // 'student_data' or 'attendance_report'
  int? _selectedSemester; // For filtering by semester
  String? _selectedSection; // For filtering by section
  String _dateSelectionMode = 'week'; // 'week' or 'custom'
  DateTime _startDate = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  DateTime _endDate = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 7),
  );
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();
  
  // Working days selection - stores dates that ARE working days (not excluded)
  Set<DateTime> _selectedWorkingDays = {};
  bool _workingDaysInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected semester and section with widget values
    _selectedSemester = widget.semester;
    _selectedSection = widget.section;
    // Set end date to end of current week
    _endDate = _startDate.add(const Duration(days: 6));
    _fetchStudentColumns();
    _initializeWorkingDays();
  }

  /// Initialize working days when custom date range changes
  void _initializeWorkingDays() {
    final start = _dateSelectionMode == 'custom' ? _customStartDate : _startDate;
    final end = _dateSelectionMode == 'custom' ? _customEndDate : _endDate;
    
    _selectedWorkingDays.clear();
    
    // Add all dates except Sundays by default
    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      // Normalize to date only (no time component)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      // Exclude Sundays by default (weekday 7 = Sunday)
      if (normalizedDate.weekday != DateTime.sunday) {
        _selectedWorkingDays.add(normalizedDate);
      }
    }
    _workingDaysInitialized = true;
  }

  /// Get all dates in the current range
  List<DateTime> _getAllDatesInRange() {
    final start = _dateSelectionMode == 'custom' ? _customStartDate : _startDate;
    final end = _dateSelectionMode == 'custom' ? _customEndDate : _endDate;
    
    List<DateTime> dates = [];
    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      dates.add(DateTime(date.year, date.month, date.day));
    }
    return dates;
  }

  /// Toggle a date's working day status
  void _toggleWorkingDay(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    setState(() {
      if (_selectedWorkingDays.contains(normalizedDate)) {
        _selectedWorkingDays.remove(normalizedDate);
      } else {
        _selectedWorkingDays.add(normalizedDate);
      }
    });
  }

  /// Select all dates as working days
  void _selectAllWorkingDays() {
    setState(() {
      _selectedWorkingDays.clear();
      for (final date in _getAllDatesInRange()) {
        _selectedWorkingDays.add(date);
      }
    });
  }

  /// Deselect all dates
  void _deselectAllWorkingDays() {
    setState(() {
      _selectedWorkingDays.clear();
    });
  }

  /// Exclude all Sundays
  void _excludeAllSundays() {
    setState(() {
      _selectedWorkingDays.removeWhere((date) => date.weekday == DateTime.sunday);
    });
  }

  /// Exclude all Saturdays
  void _excludeAllSaturdays() {
    setState(() {
      _selectedWorkingDays.removeWhere((date) => date.weekday == DateTime.saturday);
    });
  }

  /// Get only the selected working days as the date range for reports
  List<DateTime> _getWorkingDaysDateRange() {
    final allDates = _getAllDatesInRange();
    return allDates.where((date) => _selectedWorkingDays.contains(date)).toList()
      ..sort();
  }

  /// Build the visual date grid for selecting working days
  Widget _buildWorkingDaysGrid() {
    final allDates = _getAllDatesInRange();
    if (allDates.isEmpty) {
      return const Center(child: Text('No dates in range'));
    }
    
    // Find the first Monday before or on the start date to align the grid
    DateTime firstDate = allDates.first;
    while (firstDate.weekday != DateTime.monday) {
      firstDate = firstDate.subtract(const Duration(days: 1));
    }
    
    // Find the last Sunday after or on the end date to complete the grid
    DateTime lastDate = allDates.last;
    while (lastDate.weekday != DateTime.sunday) {
      lastDate = lastDate.add(const Duration(days: 1));
    }
    
    // Build grid data
    List<List<DateTime?>> weeks = [];
    DateTime current = firstDate;
    while (!current.isAfter(lastDate)) {
      List<DateTime?> week = [];
      for (int i = 0; i < 7; i++) {
        // Only include dates that are in the actual range
        if (allDates.any((d) => d.year == current.year && d.month == current.month && d.day == current.day)) {
          week.add(current);
        } else {
          week.add(null); // Placeholder for dates outside range
        }
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }
    
    return Column(
      children: weeks.map((week) {
        return Row(
          children: week.map((date) {
            if (date == null) {
              return const Expanded(child: SizedBox(height: 36));
            }
            
            final isSelected = _selectedWorkingDays.any(
              (d) => d.year == date.year && d.month == date.month && d.day == date.day
            );
            final isSunday = date.weekday == DateTime.sunday;
            final isSaturday = date.weekday == DateTime.saturday;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _toggleWorkingDay(date),
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isSunday ? Colors.red[100] : (isSaturday ? Colors.orange[100] : Colors.green[100]))
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected 
                          ? (isSunday ? Colors.red : (isSaturday ? Colors.orange : Colors.green))
                          : Colors.grey[400]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? (isSunday ? Colors.red[800] : (isSaturday ? Colors.orange[800] : Colors.green[800]))
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<void> _fetchStudentColumns() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch a single student row to get all available columns
      final columns = await _hodService.fetchStudentTableColumns();
      setState(() {
        _allColumns = columns;
        _selectedColumns = {for (var col in columns) col: true};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load columns: $e';
        _loading = false;
      });
    }
  }

  Future<void> _generatePDF() async {
    if (_reportType == 'student_data') {
      await _generateStudentDataPDF();
    } else if (_reportType == 'attendance_report') {
      await _generateAttendanceReportPDF();
    }
  }

  Future<void> _generateStudentDataPDF() async {
    final selected =
        _selectedColumns.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one column.')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final data = await _hodService.fetchCustomStudentData(
        selected,
        department: widget.department,
        semester: _selectedSemester,
        section: _selectedSection,
      );
      final pdf = await _buildStudentDataPDF(selected, data);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('PDF generation error: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to generate PDF. Please check your selections and try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _generateAttendanceReportPDF() async {
    // Check if any working days are selected
    if (_dateSelectionMode == 'custom' && _selectedWorkingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one working day.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _generating = true);
    try {
      // Use custom dates if custom mode is selected
      final effectiveStartDate = _dateSelectionMode == 'custom' ? _customStartDate : _startDate;
      final effectiveEndDate = _dateSelectionMode == 'custom' ? _customEndDate : _endDate;
      
      final reportData = await _hodService.fetchAttendanceReportData(
        department: widget.department,
        semester: _selectedSemester,
        section: _selectedSection,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );
      
      // Filter to only include selected working days
      if (_dateSelectionMode == 'custom') {
        final workingDays = _getWorkingDaysDateRange();
        reportData['dateRange'] = workingDays;
      }
      
      final pdf = await _buildAttendanceReportPDF(reportData);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance report generated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Attendance report PDF generation error: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to generate attendance report. Please check your date selection and try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<pw.Document> _buildStudentDataPDF(
    List<String> columns,
    List<Map<String, dynamic>> data,
  ) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Split columns into chunks if there are too many to fit on one page
    const maxColumnsPerPage = 6; // Adjust based on page width
    final columnChunks = <List<String>>[];

    for (int i = 0; i < columns.length; i += maxColumnsPerPage) {
      columnChunks.add(
        columns.sublist(
          i,
          i + maxColumnsPerPage > columns.length
              ? columns.length
              : i + maxColumnsPerPage,
        ),
      );
    }

    // Create a page for each chunk of columns
    for (int chunkIndex = 0; chunkIndex < columnChunks.length; chunkIndex++) {
      final currentColumns = columnChunks[chunkIndex];
      final isFirstChunk = chunkIndex == 0;

      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                // Add header only on first page
                if (isFirstChunk) ...[
                  pw.Text(
                    'Student Data Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Department: ${widget.department}'),
                  if (widget.semester != null)
                    pw.Text('Semester: ${widget.semester}'),
                  if (_selectedSection != null)
                    pw.Text('Section: $_selectedSection'),
                  pw.Text('Date: $now'),
                  pw.SizedBox(height: 16),
                ] else ...[
                  pw.Text(
                    'Student Data Report (Continued - Page ${chunkIndex + 1})',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Create table with current columns chunk
                _buildTableForColumns(currentColumns, data),
              ],
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildTableForColumns(
    List<String> columns,
    List<Map<String, dynamic>> data,
  ) {
    // Limit rows per page to avoid overflow
    const maxRowsPerTable = 30;

    if (data.length <= maxRowsPerTable) {
      // Single table if data is small enough
      return pw.Table.fromTextArray(
        headers: columns.map((col) => _formatColumnName(col)).toList(),
        data:
            data
                .map(
                  (row) => columns.map((c) => _formatCellData(row[c])).toList(),
                )
                .toList(),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        border: pw.TableBorder.all(color: PdfColors.grey400),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(3),
      );
    } else {
      // Multiple tables for large datasets
      return pw.Column(
        children: [
          for (int i = 0; i < data.length; i += maxRowsPerTable)
            pw.Column(
              children: [
                if (i > 0) pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers:
                      columns.map((col) => _formatColumnName(col)).toList(),
                  data:
                      data
                          .sublist(
                            i,
                            i + maxRowsPerTable > data.length
                                ? data.length
                                : i + maxRowsPerTable,
                          )
                          .map(
                            (row) =>
                                columns
                                    .map((c) => _formatCellData(row[c]))
                                    .toList(),
                          )
                          .toList(),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(3),
                ),
              ],
            ),
        ],
      );
    }
  }

  String _formatColumnName(String columnName) {
    // Convert snake_case to Title Case
    return columnName
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _formatCellData(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value);
    }
    String str = value.toString();
    // Limit cell content length to prevent overflow
    return str.length > 30 ? '${str.substring(0, 27)}...' : str;
  }

  Future<pw.Document> _buildAttendanceReportPDF(
    Map<String, dynamic> reportData,
  ) async {
    final pdf = pw.Document();
    final students = reportData['students'] as List<Map<String, dynamic>>;
    final dateRange = reportData['dateRange'] as List<DateTime>;
    final attendanceMap =
        reportData['attendanceMap'] as Map<String, Map<String, bool>>;
    
    final totalDays = dateRange.length;

    // Create header with dates
    final dateHeaders =
        dateRange.map((date) {
          return '${DateFormat('dd.MM.yy').format(date)}\n${DateFormat('EEEE').format(date).toUpperCase()}';
        }).toList();

    final headers = [
      'S.No.',
      'Reg No',
      'Name of the Student',
      ...dateHeaders,
      'Total\nDays\nPresent',
      'Attendance\n%',
    ];

    // Prepare data rows
    final dataRows = <List<String>>[];

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final regNo = student['registration_no'] as String;
      final studentName = student['student_name'] as String? ?? regNo;

      // Get attendance for each date
      final attendanceRow = <String>[];
      int presentDays = 0;

      for (final date in dateRange) {
        final dateStr = date.toIso8601String().split('T')[0];
        final isPresent = attendanceMap[regNo]?[dateStr] ?? false;
        attendanceRow.add(isPresent ? 'P' : 'A');
        if (isPresent) presentDays++;
      }

      // Calculate percentage
      final percentage = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

      dataRows.add([
        '${i + 1}',
        regNo,
        studentName,
        ...attendanceRow,
        presentDays.toString(),
        '${percentage.toStringAsFixed(1)}%',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape for better fit
        margin: const pw.EdgeInsets.all(20),
        build:
            (context) => [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'DEPARTMENT OF ${widget.department.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _selectedSemester != null
                          ? 'SEMESTER: $_selectedSemester'
                          : 'ALL SEMESTERS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (_selectedSection != null)
                      pw.Text(
                        'CLASS: $_selectedSection',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),

              // Attendance Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25), // S.No.
                  1: const pw.FixedColumnWidth(60), // Reg No
                  2: const pw.FixedColumnWidth(100), // Name
                  // Date columns (auto width)
                  for (int i = 0; i < dateRange.length; i++)
                    i + 3: const pw.FixedColumnWidth(35),
                  dateRange.length + 3: const pw.FixedColumnWidth(40), // Total
                  dateRange.length + 4: const pw.FixedColumnWidth(45), // Percentage
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children:
                        headers
                            .map(
                              (header) => pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Center(
                                  child: pw.Text(
                                    header,
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  // Data rows
                  ...dataRows
                      .map(
                        (row) => pw.TableRow(
                          children:
                              row.asMap().entries.map((entry) {
                                final isNameColumn = entry.key == 2;
                                final isAttendanceColumn =
                                    entry.key >= 3 &&
                                    entry.key < 3 + dateRange.length;

                                return pw.Padding(
                                  padding: const pw.EdgeInsets.all(2),
                                  child: pw.Text(
                                    entry.value,
                                    style: pw.TextStyle(
                                      fontSize: isNameColumn ? 7 : 8,
                                      color:
                                          isAttendanceColumn &&
                                                  entry.value == 'A'
                                              ? PdfColors.red
                                              : PdfColors.black,
                                      fontWeight:
                                          isAttendanceColumn &&
                                                  entry.value == 'P'
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal,
                                    ),
                                    textAlign:
                                        isNameColumn
                                            ? pw.TextAlign.left
                                            : pw.TextAlign.center,
                                  ),
                                );
                              }).toList(),
                        ),
                      )
                      .toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer with date range
              pw.Text(
                'Period: ${DateFormat('dd/MM/yyyy').format(reportData['startDate'])} to ${DateFormat('dd/MM/yyyy').format(reportData['endDate'])}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
      ),
    );

    return pdf;
  }

  // CSV Export Methods
  void _generateCSV() async {
    setState(() => _generating = true);
    try {
      if (_reportType == 'attendance_report') {
        await _generateAttendanceReportCSV();
      } else {
        await _generateStudentDataCSV();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV file downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('CSV generation error: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to generate CSV file. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _generateStudentDataCSV() async {
    final columns =
        _selectedColumns.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

    final data = await _hodService.fetchCustomStudentData(
      columns,
      department: widget.department,
      semester: _selectedSemester,
      section: _selectedSection,
    );

    List<List<dynamic>> csvData = [];
    // Add headers
    csvData.add(columns);

    // Add data rows
    for (final row in data) {
      List<dynamic> csvRow = [];
      for (final column in columns) {
        csvRow.add(row[column]?.toString() ?? '');
      }
      csvData.add(csvRow);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    _downloadCSV(
      csv,
      'student_data_${widget.department}_${_selectedSemester ?? 'all'}_${_selectedSection ?? 'all'}.csv',
    );
  }

  Future<void> _generateAttendanceReportCSV() async {
    // Check if any working days are selected
    if (_dateSelectionMode == 'custom' && _selectedWorkingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one working day.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Use custom dates if custom mode is selected
    final effectiveStartDate = _dateSelectionMode == 'custom' ? _customStartDate : _startDate;
    final effectiveEndDate = _dateSelectionMode == 'custom' ? _customEndDate : _endDate;
    
    final reportData = await _hodService.fetchAttendanceReportData(
      department: widget.department,
      semester: _selectedSemester,
      section: _selectedSection,
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
    );
    
    // Filter to only include selected working days
    if (_dateSelectionMode == 'custom') {
      final workingDays = _getWorkingDaysDateRange();
      reportData['dateRange'] = workingDays;
    }

    print('CSV Debug: reportData keys: ${reportData.keys}');
    print(
      'CSV Debug: students count: ${(reportData['students'] as List).length}',
    );
    print(
      'CSV Debug: dateRange count: ${(reportData['dateRange'] as List).length}',
    );
    print(
      'CSV Debug: attendanceMap keys count: ${(reportData['attendanceMap'] as Map).keys.length}',
    );

    List<List<dynamic>> csvData = [];

    final students = reportData['students'] as List<Map<String, dynamic>>;
    final dateRange = reportData['dateRange'] as List<DateTime>;
    final attendanceMap =
        reportData['attendanceMap'] as Map<String, Map<String, bool>>;
    
    final totalDays = dateRange.length;

    // Create header with dates (same format as PDF)
    final dateHeaders =
        dateRange.map((date) {
          return DateFormat('dd.MM.yy').format(date);
        }).toList();

    // Add headers
    List<dynamic> headers = ['S.No', 'Reg No', 'Name of the Student'];
    headers.addAll(dateHeaders);
    headers.add('Total Days Present');
    headers.add('Attendance %');
    csvData.add(headers);

    // Add data rows (same logic as PDF)
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final regNo = student['registration_no'] as String;
      final studentName = student['student_name'] as String? ?? regNo;

      List<dynamic> row = [];
      row.add(i + 1); // S.No
      row.add(regNo); // Registration No
      row.add(studentName); // Student Name

      int presentDays = 0;

      // Add attendance for each date (same logic as PDF)
      for (final date in dateRange) {
        final dateStr = date.toIso8601String().split('T')[0];
        final isPresent = attendanceMap[regNo]?[dateStr] ?? false;
        row.add(isPresent ? 'P' : 'A');
        if (isPresent) presentDays++;
      }

      // Add total present days
      row.add(presentDays);
      
      // Add attendance percentage
      final percentage = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;
      row.add('${percentage.toStringAsFixed(1)}%');

      csvData.add(row);
    }

    print(
      'CSV Debug: Generated ${csvData.length} rows with ${csvData[0].length} columns',
    );

    final csv = const ListToCsvConverter().convert(csvData);
    final startDateStr = DateFormat('yyyy-MM-dd').format(effectiveStartDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(effectiveEndDate);
    _downloadCSV(
      csv,
      'attendance_report_${widget.department}_${_selectedSemester ?? 'all'}_${_selectedSection ?? 'all'}_${startDateStr}_to_${endDateStr}.csv',
    );
  }

  void _downloadCSV(String csvContent, String filename) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename);
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Export Student Data to PDF')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                child: Column(
                children: [
                  // Report Type Selection
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Report Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadioListTile<String>(
                          title: const Text('Student Data Export'),
                          subtitle: const Text(
                            'Export selected student information columns',
                          ),
                          value: 'student_data',
                          groupValue: _reportType,
                          onChanged: (value) {
                            setState(() {
                              _reportType = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Attendance Report'),
                          subtitle: const Text(
                            'Weekly attendance report with P/A markings',
                          ),
                          value: 'attendance_report',
                          groupValue: _reportType,
                          onChanged: (value) {
                            setState(() {
                              _reportType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Semester Selection
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Semester Filter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Text(
                            'Filter students and attendance by semester. Select "All Semesters" to include all students.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Select Semester',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedSemester,
                            hint: const Text('All Semesters'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('All Semesters'),
                              ),
                              for (int i = 1; i <= 8; i++)
                                DropdownMenuItem<int>(
                                  value: i,
                                  child: Text('Semester $i'),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSemester = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Filter
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Section Filter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Text(
                            'Filter students and attendance by section. Select "All Sections" to include all sections.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Section',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedSection,
                            hint: const Text('All Sections'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Sections'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'A',
                                child: Text('Section A'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'B',
                                child: Text('Section B'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'C',
                                child: Text('Section C'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSection = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date Range Selection (for attendance report)
                  if (_reportType == 'attendance_report')
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Date Range Selection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Mode selector: Week or Custom
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'week',
                                  label: Text('Week'),
                                  icon: Icon(Icons.calendar_view_week),
                                ),
                                ButtonSegment(
                                  value: 'custom',
                                  label: Text('Custom Range'),
                                  icon: Icon(Icons.date_range),
                                ),
                              ],
                              selected: {_dateSelectionMode},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _dateSelectionMode = newSelection.first;
                                  if (_dateSelectionMode == 'custom') {
                                    _initializeWorkingDays(); // Initialize working days when switching to custom
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Week Selection
                          if (_dateSelectionMode == 'week')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _startDate = picked.subtract(
                                            Duration(days: picked.weekday - 1),
                                          );
                                          _endDate = _startDate.add(
                                            const Duration(days: 6),
                                          );
                                        });
                                      }
                                    },
                                    child: const Text('Change Week'),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Custom Date Range Selection
                          if (_dateSelectionMode == 'custom')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                children: [
                                  // Start Date
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _customStartDate,
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        lastDate: _customEndDate,
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _customStartDate = picked;
                                          _initializeWorkingDays(); // Re-initialize working days for new range
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Start Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(_customStartDate),
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // End Date
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _customEndDate,
                                        firstDate: _customStartDate,
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _customEndDate = picked;
                                          _initializeWorkingDays(); // Re-initialize working days for new range
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'End Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(_customEndDate),
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Show duration
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Duration: ${_customEndDate.difference(_customStartDate).inDays + 1} days',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Working Days Selection Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Select Working Days',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_selectedWorkingDays.length} of ${_getAllDatesInRange().length} selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Quick Action Buttons
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(Icons.select_all, size: 16),
                                        label: const Text('Select All'),
                                        onPressed: _selectAllWorkingDays,
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.deselect, size: 16),
                                        label: const Text('Deselect All'),
                                        onPressed: _deselectAllWorkingDays,
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.weekend, size: 16),
                                        label: const Text('Exclude Sundays'),
                                        backgroundColor: Colors.red[50],
                                        onPressed: _excludeAllSundays,
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.weekend_outlined, size: 16),
                                        label: const Text('Exclude Saturdays'),
                                        backgroundColor: Colors.orange[50],
                                        onPressed: _excludeAllSaturdays,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Date Grid
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        // Day headers
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                          ),
                                          child: Row(
                                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                                .map((day) => Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          day,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: day == 'Sun' ? Colors.red : (day == 'Sat' ? Colors.orange : Colors.black),
                                                          ),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        // Date chips grid
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: _buildWorkingDaysGrid(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  // Summary
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Working Days: ${_selectedWorkingDays.length}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Column Selection (for student data only)
                  if (_reportType == 'student_data')
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView(
                        shrinkWrap: true,
                        children:
                            _allColumns
                                .map(
                                  (col) => CheckboxListTile(
                                    title: Text(col),
                                    value: _selectedColumns[col] ?? false,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedColumns[col] = val ?? false;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      child: const Center(
                        child: Text(
                          'Attendance report will include:\n'
                          '• Student registration numbers and names\n'
                          '• Daily attendance for the selected week\n'
                          '• Present/Absent markings (P/A)',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          elevation: 3,
                        ),
                        label:
                            _generating
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                                : Text(
                                  _reportType == 'attendance_report'
                                      ? 'Generate PDF Report'
                                      : 'Generate PDF',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        onPressed: _generating ? null : _generatePDF,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.table_view, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        label:
                            _generating
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  _reportType == 'attendance_report'
                                      ? 'Download CSV Report'
                                      : 'Download CSV',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        onPressed: _generating ? null : _generateCSV,
                      ),
                    ),
                  ),
                ],
              ),
              ),
    );
  }
}
