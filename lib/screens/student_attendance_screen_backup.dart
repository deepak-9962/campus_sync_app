import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'link_student_account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;

  const StudentAttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final _attendanceService = AttendanceService();

  Map<String, dynamic>? _attendanceData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _studentRegNo;
  Map<String, dynamic>? _studentInfo;

  @override
  void initState() {
    super.initState();
    _loadStudentAttendance();
  }

  Future<void> _loadStudentAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get student information using the new RPC function
      final studentResponse = await Supabase.instance.client.rpc(
        'get_my_student_info',
      );

      if (studentResponse != null &&
          studentResponse is List &&
          studentResponse.isNotEmpty) {
        final studentData = studentResponse.first;
        _studentRegNo = studentData['registration_no'];
        _studentInfo = studentData;
      } else {
        // If no student linked, navigate to link account screen
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LinkStudentAccountScreen(
                    department: widget.department,
                    semester: widget.semester,
                  ),
            ),
          );

          // If account was successfully linked, retry loading attendance
          if (result == true && mounted) {
            _loadStudentAttendance();
            return;
          }
        }
        throw Exception(
          'Student account not linked. Please link your account to view attendance.',
        );
      }

      // Get attendance data
      if (_studentRegNo != null) {
        final attendanceResult = await _attendanceService
            .getAttendanceByRegistrationNo(_studentRegNo!);

        setState(() {
          _attendanceData = attendanceResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
              ? _buildErrorState()
              : _attendanceData != null
              ? _buildAttendanceData()
              : _buildNoDataState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading your attendance...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Unable to Load Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStudentAttendance,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No attendance records found for your account.\nAttendance will appear here once classes begin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceData() {
    final data = _attendanceData!;
    final totalClasses = data['total_classes'] ?? 0;
    final presentClasses = data['present_classes'] ?? 0;
    
    // Use the percentage from database if available, otherwise calculate
    final attendancePercentage = data['attendance_percentage'] != null 
        ? data['attendance_percentage'].toStringAsFixed(1)
        : totalClasses > 0
            ? (presentClasses / totalClasses * 100).toStringAsFixed(1)
            : '0.0';

    final status = data['status'] ?? _getStatusFromPercentage(double.parse(attendancePercentage));

    // Color coding based on attendance percentage
    Color percentageColor = _getPercentageColor(double.parse(attendancePercentage));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow('Registration No:', _studentRegNo ?? 'Unknown'),
                  _buildInfoRow(
                    'Department:',
                    _studentInfo?['department'] ?? widget.department,
                  ),
                  _buildInfoRow(
                    'Semester:',
                    _studentInfo?['current_semester']?.toString() ??
                        widget.semester.toString(),
                  ),
                  _buildInfoRow(
                    'Section:',
                    _studentInfo?['section'] ?? 'Unknown',
                  ),
                  _buildInfoRow('Batch:', _studentInfo?['batch'] ?? 'Unknown'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Enhanced Attendance Summary Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Enhanced Percentage Circle with gradient
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                percentageColor.withOpacity(0.1),
                                percentageColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: double.parse(attendancePercentage) / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(percentageColor),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$attendancePercentage%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: percentageColor,
                              ),
                            ),
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: percentageColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: percentageColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Enhanced Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Classes',
                          totalClasses.toString(),
                          Icons.school,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Present',
                          presentClasses.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Absent',
                          (totalClasses - presentClasses).toString(),
                          Icons.cancel,
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Required',
                          '75%',
                          Icons.track_changes,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Enhanced Status Card with more details
          Card(
            color: _getStatusCardColor(double.parse(attendancePercentage)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(double.parse(attendancePercentage)),
                        color: percentageColor,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusTitle(double.parse(attendancePercentage)),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: percentageColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getStatusMessage(double.parse(attendancePercentage)),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (double.parse(attendancePercentage) < 75) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You need ${(75 - double.parse(attendancePercentage)).toStringAsFixed(1)}% more attendance to meet requirements.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for enhanced attendance display
  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getStatusFromPercentage(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Average';
    return 'Needs Improvement';
  }

  Color _getStatusCardColor(double percentage) {
    if (percentage >= 90) return Colors.green.shade50;
    if (percentage >= 75) return Colors.blue.shade50;
    if (percentage >= 60) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  IconData _getStatusIcon(double percentage) {
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 75) return Icons.thumb_up;
    if (percentage >= 60) return Icons.warning;
    return Icons.error;
  }

  String _getStatusTitle(double percentage) {
    if (percentage >= 90) return 'Excellent Performance!';
    if (percentage >= 75) return 'Good Attendance';
    if (percentage >= 60) return 'Average Attendance';
    return 'Low Attendance Warning';
  }

  String _getStatusMessage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding! You have excellent attendance. Keep up the great work!';
    } else if (percentage >= 75) {
      return 'Great job! Your attendance meets the required standards.';
    } else if (percentage >= 60) {
      return 'Your attendance is average. Try to attend more classes to improve.';
    } else {
      return 'Your attendance is below requirements. Please attend more classes regularly.';
    }
  }
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Percentage Circle
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: percentageColor, width: 8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$attendancePercentage%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: percentageColor,
                              ),
                            ),
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Classes',
                          totalClasses.toString(),
                          Icons.school,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Present',
                          presentClasses.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Absent',
                          (totalClasses - presentClasses).toString(),
                          Icons.cancel,
                          Colors.red,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Required %',
                          '75%',
                          Icons.track_changes,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Status Card
          Card(
            color:
                double.parse(attendancePercentage) >= 75
                    ? Colors.green.shade50
                    : Colors.red.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    double.parse(attendancePercentage) >= 75
                        ? Icons.check_circle
                        : Icons.warning,
                    color:
                        double.parse(attendancePercentage) >= 75
                            ? Colors.green
                            : Colors.red,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          double.parse(attendancePercentage) >= 75
                              ? 'Good Attendance!'
                              : 'Low Attendance Warning',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                double.parse(attendancePercentage) >= 75
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          double.parse(attendancePercentage) >= 75
                              ? 'Keep up the good work! Your attendance is above the required 75%.'
                              : 'Your attendance is below 75%. Please attend more classes.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
