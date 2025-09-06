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
  DateTime? _lastRefreshTime;

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

      print('Loading attendance for user: ${user.email}');

      // FIRST: Try to get attendance directly from email
      final emailBasedAttendance =
          await _attendanceService.getAttendanceFromEmail();

      if (emailBasedAttendance != null) {
        print(
          'Successfully loaded attendance using email-based registration number',
        );
        setState(() {
          _attendanceData = emailBasedAttendance;
          _studentRegNo = emailBasedAttendance['registration_no'];
          _lastRefreshTime = DateTime.now();
          _isLoading = false;
        });
        return;
      }

      print(
        'Email-based attendance lookup failed, trying linked account method...',
      );

      // FALLBACK: Try linked account method
      final studentResponse = await Supabase.instance.client.rpc(
        'get_my_student_info',
      );

      if (studentResponse != null &&
          studentResponse is List &&
          studentResponse.isNotEmpty) {
        final studentData = studentResponse.first;
        _studentRegNo = studentData['registration_no'];
        _studentInfo = studentData;

        print('Found linked student info for registration: $_studentRegNo');

        // Get attendance data using linked registration number
        final attendanceResult = await _attendanceService
            .getAttendanceByRegistrationNo(_studentRegNo!);

        setState(() {
          _attendanceData = attendanceResult;
          _lastRefreshTime = DateTime.now();
          _isLoading = false;
        });
      } else {
        // If no student linked and email method failed, show helpful message
        print('No linked account found and email-based lookup failed');

        // Extract registration number from email for display
        final extractedRegNo = _attendanceService.extractRegistrationFromEmail(
          user.email ?? '',
        );

        if (extractedRegNo != null) {
          throw Exception(
            'No attendance data found for registration number: $extractedRegNo\n\n'
            'Possible reasons:\n'
            '• Attendance data not yet uploaded to the system\n'
            '• Registration number format mismatch\n'
            '• You may need to link your student account manually\n\n'
            'Extracted from email: ${user.email}',
          );
        } else {
          // If we can't extract reg number from email, navigate to link account screen
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
            'Could not determine your registration number from email: ${user.email}\n\n'
            'Please link your student account manually to view attendance.',
          );
        }
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStudentAttendance,
            tooltip: 'Refresh Data',
          ),
        ],
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
    final attendancePercentage =
        data['attendance_percentage'] != null
            ? data['attendance_percentage'].toStringAsFixed(1)
            : totalClasses > 0
            ? (presentClasses / totalClasses * 100).toStringAsFixed(1)
            : '0.0';

    final status =
        data['status'] ??
        _getStatusFromPercentage(double.parse(attendancePercentage));
    Color percentageColor = _getPercentageColor(
      double.parse(attendancePercentage),
    );

    return RefreshIndicator(
      onRefresh: _loadStudentAttendance,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
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
                  if (_lastRefreshTime != null) ...[
                    SizedBox(height: 8),
                    Divider(),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last updated: ${_formatRefreshTime(_lastRefreshTime!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 8),

          // Helpful instruction for pull-to-refresh
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pull down to refresh or tap the refresh button to get the latest attendance data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentageColor,
                            ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
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
                              _getStatusTitle(
                                double.parse(attendancePercentage),
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: percentageColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getStatusMessage(
                                double.parse(attendancePercentage),
                              ),
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

  String _formatRefreshTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
