import 'package:flutter/material.dart';
import 'attendance_lookup_screen.dart';
import 'database_setup_screen.dart';

class AttendanceScreen extends StatelessWidget {
  final String department;
  final int semester;

  const AttendanceScreen({
    Key? key,
    required this.department,
    required this.semester,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
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
              // Refresh functionality could be added here
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Attendance Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '$department - Semester $semester',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your attendance records and statistics',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Check My Attendance'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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
              ),
              onPressed: () {
                // This could navigate to a screen showing class-wide attendance
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class attendance view coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
