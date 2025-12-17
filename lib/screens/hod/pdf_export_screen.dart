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
  DateTime _startDate = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  DateTime _endDate = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 7),
  );

  @override
  void initState() {
    super.initState();
    // Initialize selected semester with widget.semester
    _selectedSemester = widget.semester;
    // Set end date to end of current week
    _endDate = _startDate.add(const Duration(days: 6));
    _fetchStudentColumns();
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
        section: widget.section,
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
    setState(() => _generating = true);
    try {
      final reportData = await _hodService.fetchAttendanceReportData(
        department: widget.department,
        semester: _selectedSemester,
        section: widget.section,
        startDate: _startDate,
        endDate: _endDate,
      );
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
                  if (widget.section != null)
                    pw.Text('Section: ${widget.section}'),
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
      'Total\nDays\nPresent\nin a\nWEEK',
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

      dataRows.add([
        '${i + 1}',
        regNo,
        studentName,
        ...attendanceRow,
        presentDays.toString(),
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
                    if (widget.section != null)
                      pw.Text(
                        'CLASS: ${widget.section}',
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
      section: widget.section,
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
      'student_data_${widget.department}_${_selectedSemester ?? 'all'}_${widget.section}.csv',
    );
  }

  Future<void> _generateAttendanceReportCSV() async {
    final reportData = await _hodService.fetchAttendanceReportData(
      department: widget.department,
      semester: _selectedSemester,
      section: widget.section,
      startDate: _startDate,
      endDate: _endDate,
    );

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

    // Create header with dates (same format as PDF)
    final dateHeaders =
        dateRange.map((date) {
          return '${DateFormat('dd.MM.yy').format(date)}\n${DateFormat('EEEE').format(date).toUpperCase()}';
        }).toList();

    // Add headers
    List<dynamic> headers = ['S.No', 'Reg No', 'Name of the Student'];
    headers.addAll(dateHeaders);
    headers.add('Total Days Present in a WEEK');
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

      csvData.add(row);
    }

    print(
      'CSV Debug: Generated ${csvData.length} rows with ${csvData[0].length} columns',
    );

    final csv = const ListToCsvConverter().convert(csvData);
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);
    _downloadCSV(
      csv,
      'attendance_report_${widget.department}_${_selectedSemester ?? 'all'}_${widget.section}_${startDateStr}_to_${endDateStr}.csv',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Export Student Data to PDF')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : Column(
                children: [
                  // Report Type Selection
                  Container(
                    margin: const EdgeInsets.all(16),
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
                              'Week Selection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                        ],
                      ),
                    ),

                  // Column Selection (for student data only)
                  if (_reportType == 'student_data')
                    Expanded(
                      child: ListView(
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Attendance report will include:\n'
                          '• Student registration numbers and names\n'
                          '• Daily attendance for the selected week\n'
                          '• Present/Absent markings (P/A)\n'
                          '• Total present days count',
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
    );
  }
}
