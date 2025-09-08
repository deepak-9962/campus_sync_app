import 'package:flutter/material.dart';
import '../services/hod_service.dart';
import 'attendance_view_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // Clear any stale data and fetch fresh data
    _clearData();
    _loadDepartmentData();
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

  Future<void> _loadDepartmentData() async {
    print(
      'HOD Dashboard: Loading fresh data for ${currentDate.toIso8601String().split('T')[0]}',
    );

    setState(() {
      isLoading = true;
    });

    try {
      // Load TODAY'S department summary using HOD service
      final summary = await _hodService.getDepartmentAttendanceSummary(
        widget.department,
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
        widget.department,
        selectedSemester: widget.selectedSemester,
        date: currentDate,
      );

      // Load students with low attendance TODAY using HOD service
      final lowAttendance = await _hodService.getTodayLowAttendanceStudents(
        widget.department,
        selectedSemester: widget.selectedSemester,
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
      
      // ENHANCED: Log detailed state for debugging
      print('HOD Dashboard: Final departmentSummary state - $departmentSummary');
      
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      print('HOD Dashboard: CRITICAL ERROR during data loading - $e');
      print('HOD Dashboard: Error type - ${e.runtimeType}');
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
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
      ));
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
              widget.selectedSemester != null
                  ? 'HOD Dashboard - ${widget.department} - Semester ${widget.selectedSemester}'
                  : 'HOD Dashboard - ${widget.department}',
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
              : Column(
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
                          'Department: ${widget.department}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View selector
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildViewTab('summary', 'Summary'),
                        _buildViewTab('semester-wise', 'Semester-wise'),
                        _buildViewTab('low-attendance', 'Low Attendance'),
                      ],
                    ),
                  ),

                  // Content based on selected view
                  Expanded(child: _buildSelectedView()),
                ],
              ),
    );
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
            title: Text('Semester ${semester['semester']}'),
            subtitle: Text(
              'Students: ${semester['total_students']} | Today: ${semester['today_present'] ?? 0}P/${semester['today_absent'] ?? 0}A | Today\'s Avg: ${(semester['today_percentage'] ?? 0.0).toStringAsFixed(1)}%',
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
                            'Today Present',
                            '${semester['today_present'] ?? 0}',
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Today Absent',
                            '${semester['today_absent'] ?? 0}',
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Today Total',
                            '${(semester['today_present'] ?? 0) + (semester['today_absent'] ?? 0)}',
                            Icons.people,
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
              department: widget.department,
              semester: semester['semester'] as int,
            ),
      ),
    );
  }
}
