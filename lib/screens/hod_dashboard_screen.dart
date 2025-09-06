import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

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
  final AttendanceService _attendanceService = AttendanceService();

  Map<String, dynamic> departmentSummary = {};
  List<Map<String, dynamic>> semesterWiseData = [];
  List<Map<String, dynamic>> lowAttendanceStudents = [];
  bool isLoading = true;
  String selectedView = 'summary'; // summary, semester-wise, low-attendance

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load TODAY'S department summary (instead of overall)
      final summary = await _attendanceService.getTodayDepartmentSummary(
        widget.department,
      );

      // Load TODAY'S semester-wise data
      final semesterData = await _loadTodaySemesterWiseData();

      // Load students with low attendance TODAY
      final lowAttendance = await _attendanceService.getTodayLowAttendanceStudents(
        department: widget.department,
        threshold: 75.0,
      );

      // Filter low attendance by semester if specified
      final filteredLowAttendance = widget.selectedSemester != null
          ? lowAttendance.where((student) => student['semester'] == widget.selectedSemester).toList()
          : lowAttendance;

      setState(() {
        departmentSummary = summary;
        semesterWiseData = semesterData;
        lowAttendanceStudents = filteredLowAttendance;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<List<Map<String, dynamic>>> _loadTodaySemesterWiseData() async {
    List<Map<String, dynamic>> data = [];

    // If a specific semester is selected, only load that semester
    final semestersToLoad = widget.selectedSemester != null 
        ? [widget.selectedSemester!] 
        : [1, 2, 3, 4, 5, 6, 7, 8]; // Load all semesters if none selected

    // Load TODAY'S data for specified semesters
    for (int semester in semestersToLoad) {
      try {
        print(
          'HOD Dashboard: Loading TODAY\'S data for semester $semester for department: ${widget.department}',
        );

        // Get today's attendance data for this semester
        final semesterTodayData = await _attendanceService.getTodaySemesterAttendance(
          department: widget.department,
          semester: semester,
        );

        print(
          'HOD Dashboard: Semester $semester TODAY - ${semesterTodayData['total_students']} total students, ${semesterTodayData['today_present']} present, ${semesterTodayData['today_absent']} absent',
        );

        if (semesterTodayData['total_students'] > 0) {
          data.add({
            'semester': semester,
            'total_students': semesterTodayData['total_students'],
            'today_present': semesterTodayData['today_present'],
            'today_absent': semesterTodayData['today_absent'],
            'today_percentage': semesterTodayData['today_percentage'],
            'students': semesterTodayData['students'],
          });
        } else {
          print('HOD Dashboard: No students found for semester $semester');
        }
      } catch (e) {
        print('HOD Dashboard: Error loading semester $semester: $e');
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedSemester != null 
          ? 'HOD Dashboard - ${widget.department} - Semester ${widget.selectedSemester}'
          : 'HOD Dashboard - ${widget.department}'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                  'Today\'s Avg Attendance',
                  '${(departmentSummary['today_percentage'] ?? 0).toStringAsFixed(1)}%',
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
                  '${departmentSummary['today_present'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Today Absent',
                  '${departmentSummary['today_absent'] ?? 0}',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'Low Attendance Today (<75%)',
            '${departmentSummary['low_attendance_today'] ?? 0}',
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
              'Students: ${semester['total_students']} | Today: ${semester['today_present'] ?? 0}P/${semester['today_absent'] ?? 0}A | Today\'s Avg: ${(semester['today_percentage'] ?? 0.0).toStringAsFixed(1)}%'
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
                            'Today\'s Avg',
                            '${(semester['today_percentage'] ?? 0.0).toStringAsFixed(1)}%',
                            Icons.analytics,
                            color:
                                (semester['today_percentage'] ?? 0.0) >= 75.0
                                    ? Colors.green
                                    : (semester['today_percentage'] ?? 0.0) >= 50.0
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
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  '${widget.department} - Semester ${semester['semester']}',
                ),
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: semester['students'].length,
                itemBuilder: (context, index) {
                  final student = semester['students'][index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getAttendanceColor(
                          student['percentage'] ?? 0,
                        ),
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
                        'Registration: ${student['registration_no']}',
                      ),
                      trailing: Text(
                        'Section ${student['section']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}
