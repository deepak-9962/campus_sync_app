import 'package:flutter/material.dart';
import 'attendance_lookup_screen.dart';
import 'database_setup_screen.dart';
import 'staff_attendance_screen.dart';
import '../services/auth_service.dart';
import 'role_test_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String department;
  final int semester;

  const AttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isStaff = false;
  bool _isAdmin = false;
  String _userRole = 'student';
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final role = await _authService.getUserRole();
      final isStaff = await _authService.isStaff();
      final isAdmin = await _authService.isAdmin();

      setState(() {
        _userRole = role;
        _isStaff = isStaff;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _canTakeAttendance => _isStaff || _isAdmin;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: _canTakeAttendance ? Colors.blue[700] : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_canTakeAttendance)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Tools',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DatabaseSetupScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkUserRole();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                _canTakeAttendance
                    ? [Colors.blue[50]!, Colors.white]
                    : [Colors.blue[100]!, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Role-specific icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        _canTakeAttendance ? Colors.blue[100] : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _canTakeAttendance ? Icons.people_alt : Icons.person,
                    size: 80,
                    color: _canTakeAttendance ? Colors.blue[700] : Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),

                // Role-specific title
                Text(
                  _canTakeAttendance
                      ? 'Staff Attendance Management'
                      : 'Student Attendance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        _canTakeAttendance
                            ? Colors.blue[800]
                            : Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '${widget.department} - Semester ${widget.semester}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Role-specific description
                Text(
                  _canTakeAttendance
                      ? 'Take attendance for your classes by selecting sections and marking students present/absent'
                      : 'Check your attendance records and view your attendance statistics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                // Role-specific buttons
                if (_canTakeAttendance) ...[
                  // Staff/Admin buttons
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Take Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StaffAttendanceScreen(
                                department: widget.department,
                                semester: widget.semester,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Class Reports'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.blue[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Attendance reports feature coming soon!',
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Student buttons
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      'Check My Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceLookupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('View Class Attendance'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.blue[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Class attendance view coming soon!'),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Role indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(_userRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(_userRole),
                        size: 16,
                        color: _getRoleColor(_userRole),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(_userRole),
                        ),
                      ),
                    ],
                  ),
                ),

                // Development test button (remove in production)
                SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.bug_report, size: 16),
                  label: Text('Test Role Setup'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: BorderSide(color: Colors.orange),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoleTestScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return Colors.green[700]!;
      case 'staff':
        return Colors.blue[700]!;
      case 'admin':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'student':
        return Icons.person;
      case 'staff':
        return Icons.school;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
