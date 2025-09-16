import 'package:flutter/material.dart';
import '../models/dashboard_feature.dart';
import '../screens/timetable_screen.dart';
import '../screens/attendance_view_screen.dart';
import '../screens/my_marks_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/resource_hub_screen.dart';
import '../screens/dbms_marks_screen.dart';
import '../screens/timetable_editor_screen.dart';
import '../screens/staff_attendance_screen.dart';
import '../screens/hod_dashboard_screen.dart';
import '../screens/admin_dashboard_screen.dart';

/// Feature configuration helper that provides role-based dashboard features
class DashboardFeatureHelper {
  /// Returns a list of dashboard features based on the user's role
  static List<DashboardFeature> getDashboardFeatures({
    required String role,
    required BuildContext context,
    required String userName,
    String? department, // Made optional since admin doesn't need it
    int? semester, // Made optional since admin doesn't need it
    String? assignedDepartment,
  }) {
    switch (role.toLowerCase()) {
      case 'student':
        return _getStudentFeatures(
          context,
          userName,
          department ?? '',
          semester ?? 1,
        );
      case 'faculty':
      case 'staff':
      case 'teacher':
        return _getFacultyFeatures(
          context,
          userName,
          department ?? '',
          semester ?? 1,
        );
      case 'hod':
        return _getHODFeatures(
          context,
          userName,
          assignedDepartment ?? department ?? '',
        );
      case 'admin':
        return _getAdminFeatures(context, userName);
      default:
        return _getStudentFeatures(
          context,
          userName,
          department ?? '',
          semester ?? 1,
        );
    }
  }

  /// Student dashboard features
  static List<DashboardFeature> _getStudentFeatures(
    BuildContext context,
    String userName,
    String department,
    int semester,
  ) {
    return [
      DashboardFeature(
        title: 'View Timetable',
        icon: Icons.schedule,
        color: Colors.blue,
        subtitle: 'Check your class schedule',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TimetableScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'My Attendance',
        icon: Icons.fact_check,
        color: Colors.green,
        subtitle: 'View attendance records',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AttendanceViewScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'My Marks',
        icon: Icons.grade,
        color: Colors.orange,
        subtitle: 'Check your marks',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyMarksScreen()),
            ),
      ),
      DashboardFeature(
        title: 'Announcements',
        icon: Icons.announcement,
        color: Colors.purple,
        subtitle: 'Latest updates',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
            ),
      ),
      DashboardFeature(
        title: 'Resource Hub',
        icon: Icons.library_books,
        color: Colors.teal,
        subtitle: 'Study materials',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ResourceHubScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'Profile',
        icon: Icons.person,
        color: Colors.indigo,
        subtitle: 'Manage your profile',
        onTap: () => _showProfileDialog(context, userName),
      ),
    ];
  }

  /// Faculty dashboard features
  static List<DashboardFeature> _getFacultyFeatures(
    BuildContext context,
    String userName,
    String department,
    int semester,
  ) {
    return [
      DashboardFeature(
        title: 'Take Attendance',
        icon: Icons.how_to_reg,
        color: Colors.green,
        subtitle: 'Mark student attendance',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => StaffAttendanceScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'Manage Marks',
        icon: Icons.edit_note,
        color: Colors.orange,
        subtitle: 'Enter and update marks',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DBMSMarksScreen()),
            ),
      ),
      DashboardFeature(
        title: 'View Timetable',
        icon: Icons.schedule,
        color: Colors.blue,
        subtitle: 'Check teaching schedule',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TimetableScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'Edit Timetable',
        icon: Icons.edit_calendar,
        color: Colors.indigo,
        subtitle: 'Modify class schedule',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TimetableEditorScreen()),
            ),
      ),
      DashboardFeature(
        title: 'Upload Resources',
        icon: Icons.cloud_upload,
        color: Colors.teal,
        subtitle: 'Share study materials',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ResourceHubScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
      DashboardFeature(
        title: 'Create Announcement',
        icon: Icons.campaign,
        color: Colors.purple,
        subtitle: 'Post updates',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
            ),
      ),
      DashboardFeature(
        title: 'Attendance Reports',
        icon: Icons.analytics,
        color: Colors.red,
        subtitle: 'View attendance analytics',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AttendanceViewScreen(
                      department: department,
                      semester: semester,
                    ),
              ),
            ),
      ),
    ];
  }

  /// HOD dashboard features
  static List<DashboardFeature> _getHODFeatures(
    BuildContext context,
    String userName,
    String department,
  ) {
    return [
      DashboardFeature(
        title: 'Department Dashboard',
        icon: Icons.dashboard,
        color: Colors.deepPurple,
        subtitle: 'Complete department overview',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HODDashboardScreen(
                      department: department,
                      hodName: userName,
                    ),
              ),
            ),
      ),
    ];
  }

  /// Admin dashboard features
  static List<DashboardFeature> _getAdminFeatures(
    BuildContext context,
    String userName,
  ) {
    return [
      DashboardFeature(
        title: 'Admin Dashboard',
        icon: Icons.admin_panel_settings,
        color: Colors.deepPurple,
        subtitle: 'Complete system access',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboardScreen(userName: userName),
              ),
            ),
      ),
      DashboardFeature(
        title: 'System Settings',
        icon: Icons.settings,
        color: Colors.grey,
        subtitle: 'Configure application',
        onTap: () => _showComingSoonDialog(context, 'System Settings'),
      ),
      DashboardFeature(
        title: 'User Management',
        icon: Icons.people,
        color: Colors.blue,
        subtitle: 'Manage users and roles',
        onTap: () => _showComingSoonDialog(context, 'User Management'),
      ),
      DashboardFeature(
        title: 'Reports',
        icon: Icons.assessment,
        color: Colors.green,
        subtitle: 'Generate system reports',
        onTap: () => _showComingSoonDialog(context, 'Reports'),
      ),
    ];
  }

  /// Show profile information dialog
  static void _showProfileDialog(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: $userName'),
              const SizedBox(height: 8),
              const Text('Role: Student'),
              const SizedBox(height: 8),
              const Text('Status: Active'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Show coming soon dialog for features not yet implemented
  static void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(featureName),
          content: const Text('This feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Get role display name
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return 'Student';
      case 'faculty':
      case 'staff':
      case 'teacher':
        return 'Faculty';
      case 'hod':
        return 'HOD';
      case 'admin':
        return 'Administrator';
      default:
        return 'Student';
    }
  }

  /// Get role color
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.blue;
      case 'faculty':
      case 'staff':
      case 'teacher':
        return Colors.green;
      case 'hod':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// Get role icon
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Icons.school;
      case 'faculty':
      case 'staff':
      case 'teacher':
        return Icons.person_outline;
      case 'hod':
        return Icons.business_center;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.school;
    }
  }
}
