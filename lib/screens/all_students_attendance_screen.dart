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
  String _sortBy = 'registration_no'; // registration_no, percentage, name
  bool _sortAscending = true;

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

      // Get all students attendance data
      final attendanceData = await _attendanceService.getAllStudentsAttendance(
        department: widget.department,
        semester: widget.semester,
      );

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
      final query = _searchQuery.toLowerCase();

      return regNo.contains(query);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Students Attendance'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
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
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Department and Semester Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.department,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Semester ${widget.semester}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                  fillColor: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
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
                      'Total Students',
                      _allStudentsAttendance.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
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
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[600],
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
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allStudentsAttendance.isEmpty
                                  ? 'No attendance data available'
                                  : 'No students match your search',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allStudentsAttendance.isEmpty
                                  ? 'Please ensure attendance data has been added to the database'
                                  : 'Try adjusting your search criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final percentage = student['percentage'] ?? 0.0;
    final attendedClasses = student['attended_classes'] ?? 0;
    final totalClasses = student['total_classes'] ?? 0;
    final registrationNo = student['registration_no'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Percentage Circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getPercentageColor(percentage),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
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
                    registrationNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$attendedClasses / $totalClasses classes',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Performance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPercentageColor(percentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getPercentageColor(percentage).withOpacity(0.3),
                ),
              ),
              child: Text(
                _getPerformanceLabel(percentage),
                style: TextStyle(
                  color: _getPercentageColor(percentage),
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
