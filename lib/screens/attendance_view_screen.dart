import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';

class AttendanceViewScreen extends StatefulWidget {
  final String department;
  final int semester;

  const AttendanceViewScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  State<AttendanceViewScreen> createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen>
    with TickerProviderStateMixin {
  final _attendanceService = AttendanceService();
  // Parent: 0 = Today's (with sub tabs), 1 = Overall
  late TabController _mainTabController;
  // Child (only used when main == 0): 0 = Period, 1 = Daily
  late TabController _todayTabController;

  List<Map<String, dynamic>> _periodAttendance = [];
  List<Map<String, dynamic>> _dailyAttendance = [];
  List<Map<String, dynamic>> _overallAttendance = [];
  // Auto-resolved subject + staff for selected period/date
  String? _resolvedSubjectCode;
  String? _resolvedSubjectName;
  String? _resolvedStaffName;
  bool _isLoading = true;
  String _selectedSection = 'A';
  DateTime _selectedDate = DateTime.now();

  // New state for period browsing
  // Period selection only (subject resolved automatically)
  int? _selectedPeriodNumber;
  final List<int> _periods = const [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _todayTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) return;
      if (mounted) {
        setState(() {});
        if (_mainTabController.index == 1) {
          _loadOverallAttendance();
        } else {
          _loadInitialData();
        }
      }
    });

    _todayTabController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _selectedPeriodNumber ??= _periods.first;
    await _loadAttendanceData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _todayTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily
      var dailyData = await _attendanceService.getDailyAttendanceForDate(
        widget.department,
        widget.semester,
        _selectedSection,
        _selectedDate,
      );

      // Fallback to derived daily view from period records if empty
      if (dailyData.isEmpty) {
        dailyData = await _attendanceService.getDerivedDailyFromPeriods(
          department: widget.department,
          semester: widget.semester,
          section: _selectedSection,
          date: _selectedDate,
        );
      }

      // Resolve subject for chosen period automatically
      List<Map<String, dynamic>> periodData = [];
      if (_selectedPeriodNumber != null) {
        final meta = await _attendanceService.getPeriodClassInfo(
          department: widget.department,
          semester: widget.semester,
          section: _selectedSection,
          date: _selectedDate,
          periodNumber: _selectedPeriodNumber!,
        );
        _resolvedSubjectCode = meta?['subject_code'];
        _resolvedSubjectName = meta?['subject_name'];
        _resolvedStaffName = meta?['staff_name'];
        if (_resolvedSubjectCode != null) {
          periodData = await _attendanceService.getPeriodAttendanceForDate(
            subjectCode: _resolvedSubjectCode!,
            periodNumber: _selectedPeriodNumber!,
            date: _selectedDate,
            department: widget.department,
            semester: widget.semester,
            section: _selectedSection,
          );
        }
      }

      setState(() {
        _periodAttendance = periodData;
        _dailyAttendance = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
    }
  }

  Future<void> _loadOverallAttendance() async {
    setState(() => _isLoading = true);
    try {
      // Prefer analytics view (includes names). Fallback to summary table if empty.
      var data = await _attendanceService.getOverallAttendanceAnalytics(
        department: widget.department,
        semester: widget.semester,
      );
      if (data.isEmpty) {
        data = await _attendanceService.getAllStudentsAttendance(
          department: widget.department,
          semester: widget.semester,
        );
      }
      setState(() {
        _overallAttendance = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading overall attendance: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.department}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: "Today's"), Tab(text: 'Overall')],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.group, color: Colors.white),
            onSelected: (String section) {
              setState(() => _selectedSection = section);
              if (_mainTabController.index == 0) {
                _loadAttendanceData();
              } else {
                _loadOverallAttendance();
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'A', child: Text('Section A')),
                  PopupMenuItem(value: 'B', child: Text('Section B')),
                ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [_buildTodayPane(), _buildOverallPane()],
      ),
    );
  }

  Widget _buildTodayPane() {
    return Column(
      children: [
        _buildDateAndSelectors(
          showPeriodSelectors: _todayTabController.index == 0,
        ),
        TabBar(
          controller: _todayTabController,
          labelColor: Colors.blue[700],
          indicatorColor: Colors.blue[700],
          tabs: const [Tab(text: 'Period'), Tab(text: 'Daily')],
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                    controller: _todayTabController,
                    children: [
                      _buildPeriodAttendanceTab(),
                      _buildDailyAttendanceTab(),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildOverallPane() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_overallAttendance.isEmpty) {
      return Center(
        child: Text(
          'No overall records for ${widget.department}, Sem ${widget.semester}',
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
          child: Text(
            'Overall Attendance (${_overallAttendance.length} students)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _overallAttendance.length,
            itemBuilder: (context, index) {
              final rec = _overallAttendance[index];
              final pct =
                  (rec['percentage'] ?? rec['attendance_percentage'] ?? 0)
                      .toDouble();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      pct >= 75
                          ? Colors.green[100]
                          : pct >= 50
                          ? Colors.orange[100]
                          : Colors.red[100],
                  child: Text(
                    pct.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(
                  (rec['student_name'] ?? '').toString().trim().isNotEmpty
                      ? '${rec['student_name']}'
                      : rec['registration_no'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(rec['registration_no'] ?? ''),
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          backgroundColor: Colors.grey[200],
                          color:
                              pct >= 75
                                  ? Colors.green
                                  : pct >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndSelectors({required bool showPeriodSelectors}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'Section: $_selectedSection',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Change Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: _selectDate,
              ),
            ],
          ),
          if (showPeriodSelectors) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: DropdownButtonFormField<int>(
                value: _selectedPeriodNumber,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    _periods
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p,
                            child: Text('Period $p'),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  setState(() => _selectedPeriodNumber = v);
                  _loadAttendanceData();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodAttendanceTab() {
    if (_selectedPeriodNumber == null) {
      return const Center(child: Text('Select a period'));
    }
    if (_resolvedSubjectCode == null) {
      return Column(
        children: [
          _buildSummaryBar(total: 0, present: 0, absent: 0),
          Expanded(
            child: Center(
              child: Text(
                'No class scheduled for Period $_selectedPeriodNumber on ${DateFormat('dd MMM').format(_selectedDate)}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    final int total = _periodAttendance.length;
    final int present =
        _periodAttendance
            .where((r) => (r['is_present'] ?? false) == true)
            .length;
    final int absent = total - present;

    if (_periodAttendance.isEmpty) {
      return Column(
        children: [
          _buildSummaryBar(total: total, present: present, absent: absent),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No records for ${DateFormat('dd MMM').format(_selectedDate)}, '
                    'Subject: ${_resolvedSubjectName ?? _resolvedSubjectCode}, '
                    'Period: ${_selectedPeriodNumber ?? '-'}, Sec: $_selectedSection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Subject / Staff header
        if (_resolvedSubjectCode != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.book, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_resolvedSubjectName ?? 'Subject'} (${_resolvedSubjectCode})' +
                        (_resolvedStaffName != null
                            ? ' • ${_resolvedStaffName}'
                            : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildSummaryBar(total: total, present: present, absent: absent),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _periodAttendance.length,
            itemBuilder: (context, index) {
              final record = _periodAttendance[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        record['is_present']
                            ? Colors.green[100]
                            : Colors.red[100],
                    child: Icon(
                      record['is_present'] ? Icons.check : Icons.close,
                      color: record['is_present'] ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final rn = (record['registration_no'] ?? '').toString();
                      final nm =
                          ((record['student_name'] ?? '') as String).trim();
                      final showName =
                          nm.isNotEmpty && nm.toUpperCase() != rn.toUpperCase();
                      final text = showName ? '$nm ($rn)' : rn;
                      return Text(
                        text,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reg No: ${record['registration_no']}'),
                      Text(
                        'Subject: ${_resolvedSubjectName ?? _resolvedSubjectCode}',
                      ),
                      Text('Period: ${_selectedPeriodNumber}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record['is_present'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record['is_present'] ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyAttendanceTab() {
    final int total = _dailyAttendance.length;
    final int present =
        _dailyAttendance
            .where((r) => (r['is_present'] ?? false) == true)
            .length;
    final int absent = total - present;

    if (_dailyAttendance.isEmpty) {
      return Column(
        children: [
          _buildSummaryBar(total: total, present: present, absent: absent),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.today, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No daily attendance records found\nfor this date and section',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSummaryBar(total: total, present: present, absent: absent),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _dailyAttendance.length,
            itemBuilder: (context, index) {
              final record = _dailyAttendance[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        record['is_present']
                            ? Colors.blue[100]
                            : Colors.orange[100],
                    child: Icon(
                      record['is_present'] ? Icons.check : Icons.close,
                      color: record['is_present'] ? Colors.blue : Colors.orange,
                    ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final rn = (record['registration_no'] ?? '').toString();
                      final nm =
                          ((record['student_name'] ?? '') as String).trim();
                      final showName =
                          nm.isNotEmpty && nm.toUpperCase() != rn.toUpperCase();
                      final text = showName ? '$nm ($rn)' : rn;
                      return Text(
                        text,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reg No: ${record['registration_no']}'),
                      if (record['marked_at'] != null)
                        Text(
                          'Marked at: ${DateFormat('HH:mm').format(DateTime.parse(record['marked_at']))}',
                        ),
                      if (record['marked_by'] != null)
                        Text('Marked by: ${record['marked_by']}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: record['is_present'] ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record['is_present'] ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar({
    required int total,
    required int present,
    required int absent,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryChip(
            label: 'Total',
            value: total.toString(),
            color: Colors.grey[700]!,
            bg: Colors.grey[200]!,
          ),
          _summaryChip(
            label: 'Present',
            value: present.toString(),
            color: Colors.green[800]!,
            bg: Colors.green[100]!,
          ),
          _summaryChip(
            label: 'Absent',
            value: absent.toString(),
            color: Colors.red[800]!,
            bg: Colors.red[100]!,
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
