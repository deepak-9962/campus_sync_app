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
    with SingleTickerProviderStateMixin {
  final _attendanceService = AttendanceService();
  late TabController _tabController;

  List<Map<String, dynamic>> _periodAttendance = [];
  List<Map<String, dynamic>> _dailyAttendance = [];
  bool _isLoading = true;
  String _selectedSection = 'A';
  DateTime _selectedDate = DateTime.now();

  // New state for period browsing
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectCode;
  int? _selectedPeriodNumber;
  final List<int> _periods = const [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load subjects for department/semester
      _subjects = await _attendanceService.getSubjects(
        department: widget.department,
        semester: widget.semester,
      );
      // Default selections if available
      _selectedSubjectCode =
          _subjects.isNotEmpty ? _subjects.first['subject_code'] : null;
      _selectedPeriodNumber = _periods.first;
      await _loadAttendanceData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading subjects: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily
      final dailyData = await _attendanceService.getDailyAttendanceForDate(
        widget.department,
        widget.semester,
        _selectedSection,
        _selectedDate,
      );

      // Load period view for chosen subject/period if selected
      List<Map<String, dynamic>> periodData = [];
      if (_selectedSubjectCode != null && _selectedPeriodNumber != null) {
        periodData = await _attendanceService.getPeriodAttendanceForDate(
          subjectCode: _selectedSubjectCode!,
          periodNumber: _selectedPeriodNumber!,
          date: _selectedDate,
          department: widget.department,
          semester: widget.semester,
          section: _selectedSection,
        );
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
        title: Text('Attendance Records - ${widget.department}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [Tab(text: 'Period Attendance'), Tab(text: 'Daily Attendance')],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.group, color: Colors.white),
            onSelected: (String section) {
              setState(() {
                _selectedSection = section;
              });
              _loadAttendanceData();
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'A', child: Text('Section A')),
                  PopupMenuItem<String>(value: 'B', child: Text('Section B')),
                ],
            tooltip: 'Select section',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date + selectors (period tab also uses these)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Section: $_selectedSection',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.date_range, size: 18),
                      label: Text('Change Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: _selectDate,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Subject + Period pickers (for period view)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectCode,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items:
                            _subjects
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s['subject_code'],
                                    child: Text(
                                      s['subject_name'] ?? s['subject_code'],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setState(() => _selectedSubjectCode = v);
                          _loadAttendanceData();
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedPeriodNumber,
                        decoration: InputDecoration(
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
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPeriodAttendanceTab(),
                        _buildDailyAttendanceTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodAttendanceTab() {
    if (_selectedSubjectCode == null || _selectedPeriodNumber == null) {
      return Center(child: Text('Select a subject and period to view records'));
    }
    if (_periodAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No records for ${DateFormat('dd MMM').format(_selectedDate)}, '
              'Sub: ${_selectedSubjectCode ?? '-'}, '
              'Period: ${_selectedPeriodNumber ?? '-'}, '
              'Sec: $_selectedSection',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _periodAttendance.length,
      itemBuilder: (context, index) {
        final record = _periodAttendance[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  record['is_present'] ? Colors.green[100] : Colors.red[100],
              child: Icon(
                record['is_present'] ? Icons.check : Icons.close,
                color: record['is_present'] ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              '${record['student_name'] ?? 'Unknown'}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reg No: ${record['registration_no']}'),
                Text('Subject: ${_selectedSubjectCode}'),
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
    );
  }

  Widget _buildDailyAttendanceTab() {
    if (_dailyAttendance.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _dailyAttendance.length,
      itemBuilder: (context, index) {
        final record = _dailyAttendance[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  record['is_present'] ? Colors.blue[100] : Colors.orange[100],
              child: Icon(
                record['is_present'] ? Icons.check : Icons.close,
                color: record['is_present'] ? Colors.blue : Colors.orange,
              ),
            ),
            title: Text(
              '${record['student_name'] ?? 'Unknown'}',
              style: TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}
