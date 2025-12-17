import 'package:flutter/material.dart';
import '../screens/edit_period_attendance_screen.dart';
import '../screens/edit_daily_attendance_screen.dart';

/// A floating action button widget that shows edit attendance options
/// Only visible to Staff, Admin, and HOD roles
class EditAttendanceButton extends StatelessWidget {
  final String userRole;
  final Color? backgroundColor;
  final Color? iconColor;

  const EditAttendanceButton({
    Key? key,
    required this.userRole,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  bool get _canEdit {
    final role = userRole.toLowerCase();
    return role == 'staff' || 
           role == 'admin' || 
           role == 'hod' || 
           role == 'faculty';
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the type of attendance to edit',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // Edit Period Attendance Option
            _EditOption(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: 'Edit Period Attendance',
              subtitle: 'Modify attendance for a specific period',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPeriodAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Edit Daily Attendance Option
            _EditOption(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: 'Edit Daily Attendance',
              subtitle: 'Modify daily attendance records',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditDailyAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the button if user doesn't have edit permission
    if (!_canEdit) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _showEditOptions(context),
      backgroundColor: backgroundColor ?? Colors.orange,
      icon: Icon(Icons.edit, color: iconColor ?? Colors.white),
      label: Text(
        'Edit',
        style: TextStyle(color: iconColor ?? Colors.white),
      ),
      tooltip: 'Edit Attendance',
    );
  }
}

/// A compact version of the edit button (just icon, no label)
class EditAttendanceButtonCompact extends StatelessWidget {
  final String userRole;
  final Color? backgroundColor;
  final Color? iconColor;

  const EditAttendanceButtonCompact({
    Key? key,
    required this.userRole,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  bool get _canEdit {
    final role = userRole.toLowerCase();
    return role == 'staff' || 
           role == 'admin' || 
           role == 'hod' || 
           role == 'faculty';
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the type of attendance to edit',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            // Edit Period Attendance Option
            _EditOption(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: 'Edit Period Attendance',
              subtitle: 'Modify attendance for a specific period',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPeriodAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Edit Daily Attendance Option
            _EditOption(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: 'Edit Daily Attendance',
              subtitle: 'Modify daily attendance records',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditDailyAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the button if user doesn't have edit permission
    if (!_canEdit) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _showEditOptions(context),
      backgroundColor: backgroundColor ?? Colors.orange,
      child: Icon(Icons.edit, color: iconColor ?? Colors.white),
      tooltip: 'Edit Attendance',
    );
  }
}

/// Individual edit option in the bottom sheet
class _EditOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EditOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}
