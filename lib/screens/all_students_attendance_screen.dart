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
            // Department and Semester Info - FIXED HEADER
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

            // Toggle Buttons - FIXED
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

            // SCROLLABLE CONTENT - Search, Stats, and List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? _buildErrorWidget(colorScheme)
                  : CustomScrollView(
                      slivers: [
                        // Search Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        ),

                        // Statistics Summary
                        if (_allStudentsAttendance.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
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
                                    Icons.people_outline,
                                    Colors.blue,
                                  ),
                                  if (_showTodayAttendance) ...[
                                    _buildStatItem(
                                      'Present',
                                      _allStudentsAttendance
                                          .where((s) => s['status'] == 'present')
                                          .length
                                          .toString(),
                                      Icons.check_circle_outline,
                                      Colors.green,
                                    ),
                                    _buildStatItem(
                                      'Absent',
                                      _allStudentsAttendance
                                          .where((s) => s['status'] == 'absent')
                                          .length
                                          .toString(),
                                      Icons.cancel_outlined,
                                      Colors.red,
                                    ),
                                  ] else ...[
                                    _buildClickableStatItem(
                                      'Above 75%',
                                      _allStudentsAttendance
                                          .where((s) => (s['percentage'] ?? 0) >= 75)
                                          .length
                                          .toString(),
                                      Icons.trending_up_outlined,
                                      Colors.green,
                                      () => _showStudentListDialog(
                                        'Students Above 75%',
                                        _allStudentsAttendance
                                            .where((s) => (s['percentage'] ?? 0) >= 75)
                                            .toList(),
                                        Colors.green,
                                      ),
                                    ),
                                    _buildClickableStatItem(
                                      'Below 75%',
                                      _allStudentsAttendance
                                          .where((s) => (s['percentage'] ?? 0) < 75)
                                          .length
                                          .toString(),
                                      Icons.trending_down_outlined,
                                      Colors.red,
                                      () => _showStudentListDialog(
                                        'Students Below 75%',
                                        _allStudentsAttendance
                                            .where((s) => (s['percentage'] ?? 0) < 75)
                                            .toList(),
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // Empty state or Student List
                        if (_filteredStudents.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyWidget(colorScheme),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final student = _filteredStudents[index];
                                  return _buildStudentCard(student);
                                },
                                childCount: _filteredStudents.length,
                              ),
                            ),
                          ),

                        // Bottom padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme) {
    return Center(
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
    );
  }

  Widget _buildEmptyWidget(ColorScheme colorScheme) {
    return Center(
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

  Widget _buildClickableStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
            const SizedBox(height: 2),
            Text(
              'Tap to view',
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentListDialog(
    String title,
    List<Map<String, dynamic>> students,
    Color themeColor,
  ) {
    // Sort students by percentage
    students.sort((a, b) {
      final aPercent = (a['percentage'] ?? 0.0).toDouble();
      final bPercent = (b['percentage'] ?? 0.0).toDouble();
      return bPercent.compareTo(aPercent); // Descending order
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        title.contains('Above')
                            ? Icons.trending_up_outlined
                            : Icons.trending_down_outlined,
                        color: themeColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${students.length} students',
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Student List
                Expanded(
                  child: students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 48,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No students in this category',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final percentage = (student['percentage'] ?? 0.0).toDouble();
                            final registrationNo = student['registration_no'] ?? '';
                            final studentName = student['student_name'] ?? '';
                            final attendedClasses = student['attended_classes'] ?? 0;
                            final totalClasses = student['total_classes'] ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank number
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Student info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName.isNotEmpty
                                              ? studentName
                                              : registrationNo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (studentName.isNotEmpty)
                                          Text(
                                            registrationNo,
                                            style: TextStyle(
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        Text(
                                          '$attendedClasses / $totalClasses days',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Percentage
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPercentageColor(percentage).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getPercentageColor(percentage).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: _getPercentageColor(percentage),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (student['percentage'] ?? 0.0).toDouble();
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
                        : '$attendedClasses / $totalClasses days',
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
