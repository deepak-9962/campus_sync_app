import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AllStudentsAttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;

  const AllStudentsAttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  _AllStudentsAttendanceScreenState createState() =>
      _AllStudentsAttendanceScreenState();
}

class _AllStudentsAttendanceScreenState
    extends State<AllStudentsAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<Map<String, dynamic>> _allStudentsAttendance = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _sortBy = 'registration_no'; // registration_no, percentage
  bool _sortAscending = true;
  bool _showTodayAttendance =
      false; // Toggle between today's and overall attendance

  @override
  void initState() {
    super.initState();
    _loadAllStudentsAttendance();
  }

  Future<void> _loadAllStudentsAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        'Loading attendance data for: ${widget.department}, Semester: ${widget.semester}',
      );

      List<Map<String, dynamic>> attendanceData;

      if (_showTodayAttendance) {
        // Get today's attendance records
        attendanceData = await _attendanceService.getTodayAttendance(
          department: widget.department,
          semester: widget.semester,
        );
      } else {
        // Get overall attendance data
        attendanceData = await _attendanceService.getAllStudentsAttendance(
          department: widget.department,
          semester: widget.semester,
        );
      }

      print('Received ${attendanceData.length} attendance records');

      setState(() {
        _allStudentsAttendance = attendanceData;
        _sortAttendanceData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load attendance data: $e';
        _isLoading = false;
      });
    }
  }

  void _sortAttendanceData() {
    _allStudentsAttendance.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'registration_no':
          comparison = a['registration_no'].compareTo(b['registration_no']);
          break;
        case 'percentage':
          final aPercent = a['percentage'] ?? 0.0;
          final bPercent = b['percentage'] ?? 0.0;
          comparison = aPercent.compareTo(bPercent);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudentsAttendance;

    return _allStudentsAttendance.where((student) {
      final regNo = student['registration_no'].toString().toLowerCase();
      final name = (student['student_name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return regNo.contains(query) || name.contains(query);
    }).toList();
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 60) return Colors.red[300]!;
    return Colors.red;
  }

  String _getPerformanceLabel(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Average';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showTodayAttendance ? 'Today\'s Attendance' : 'Overall Attendance',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
                _sortAttendanceData();
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'registration_no',
                    child: Text('Sort by Registration No'),
                  ),
                  const PopupMenuItem(
                    value: 'percentage',
                    child: Text('Sort by Percentage'),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllStudentsAttendance,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primaryContainer, colorScheme.surface],
          ),
        ),
        child: Column(
          children: [
            // Department and Semester Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.department,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Semester ${widget.semester}',
                    style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            ),

            // Toggle Buttons for Today's vs Overall Attendance
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_showTodayAttendance) {
                          setState(() {
                            _showTodayAttendance = false;
                          });
                          _loadAllStudentsAttendance();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              !_showTodayAttendance
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Overall Attendance',
                            style: TextStyle(
                              color:
                                  !_showTodayAttendance
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_showTodayAttendance) {
                          setState(() {
                            _showTodayAttendance = true;
                          });
                          _loadAllStudentsAttendance();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _showTodayAttendance
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Today\'s Attendance',
                            style: TextStyle(
                              color:
                                  _showTodayAttendance
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Registration Number',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Statistics Summary
            if (!_isLoading && _allStudentsAttendance.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      _showTodayAttendance
                          ? 'Total Present Today'
                          : 'Total Students',
                      _allStudentsAttendance.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    if (_showTodayAttendance) ...[
                      _buildStatItem(
                        'Present',
                        _allStudentsAttendance
                            .where((s) => s['status'] == 'present')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Absent',
                        _allStudentsAttendance
                            .where((s) => s['status'] == 'absent')
                            .length
                            .toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ] else ...[
                      _buildStatItem(
                        'Above 75%',
                        _allStudentsAttendance
                            .where((s) => (s['percentage'] ?? 0) >= 75)
                            .length
                            .toString(),
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Below 75%',
                        _allStudentsAttendance
                            .where((s) => (s['percentage'] ?? 0) < 75)
                            .length
                            .toString(),
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Students List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAllStudentsAttendance,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _filteredStudents.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allStudentsAttendance.isEmpty
                                  ? (_showTodayAttendance
                                      ? 'No attendance data available for today'
                                      : 'No overall attendance data available')
                                  : 'No students match your search',
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allStudentsAttendance.isEmpty
                                  ? (_showTodayAttendance
                                      ? 'Attendance for today will appear here once marked'
                                      : 'Please ensure attendance data has been added to the database')
                                  : 'Try adjusting your search criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_allStudentsAttendance.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton.icon(
                                  onPressed: _loadAllStudentsAttendance,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return _buildStudentCard(student);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = student['percentage'] ?? 0.0;
    final attendedClasses = student['attended_classes'] ?? 0;
    final totalClasses = student['total_classes'] ?? 0;
    final registrationNo = student['registration_no'] ?? '';
    final studentName = student['student_name'] ?? '';
    final status = student['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Percentage Circle or Status Indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      _showTodayAttendance
                          ? (status == 'present' ? Colors.green : Colors.red)
                          : _getPercentageColor(percentage),
                  width: 3,
                ),
                color:
                    _showTodayAttendance
                        ? (status == 'present'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1))
                        : _getPercentageColor(percentage).withOpacity(0.1),
              ),
              child: Center(
                child:
                    _showTodayAttendance
                        ? Icon(
                          status == 'present' ? Icons.check : Icons.close,
                          color:
                              status == 'present' ? Colors.green : Colors.red,
                          size: 30,
                        )
                        : Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getPercentageColor(percentage),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName.isNotEmpty ? studentName : registrationNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (studentName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      registrationNo,
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _showTodayAttendance
                        ? 'Status: ${status.toUpperCase()}'
                        : '$attendedClasses / $totalClasses classes',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),

            // Performance Badge or Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _showTodayAttendance
                        ? (status == 'present' ? Colors.green : Colors.red)
                            .withOpacity(0.1)
                        : _getPercentageColor(percentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _showTodayAttendance
                          ? (status == 'present' ? Colors.green : Colors.red)
                              .withOpacity(0.3)
                          : _getPercentageColor(percentage).withOpacity(0.3),
                ),
              ),
              child: Text(
                _showTodayAttendance
                    ? (status == 'present' ? 'Present' : 'Absent')
                    : _getPerformanceLabel(percentage),
                style: TextStyle(
                  color:
                      _showTodayAttendance
                          ? (status == 'present' ? Colors.green : Colors.red)
                          : _getPercentageColor(percentage),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
