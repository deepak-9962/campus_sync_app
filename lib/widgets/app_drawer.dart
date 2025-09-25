import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class AppDrawer extends StatelessWidget {
  final AuthService _authService = AuthService();

  AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Campus Sync',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.home_outlined,
              color: Colors.blue,
              size: 24,
            ),
            title: const Text(
              'Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.schedule_outlined,
              color: Colors.green,
              size: 24,
            ),
            title: const Text(
              'Timetable',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/timetable');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.assignment_outlined,
              color: Colors.orange,
              size: 24,
            ),
            title: const Text(
              'Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/attendance');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.library_books_outlined,
              color: Colors.purple,
              size: 24,
            ),
            title: const Text(
              'Library',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/library');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.quiz_outlined,
              color: Colors.red,
              size: 24,
            ),
            title: const Text(
              'Exams',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/exams');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.announcement_outlined,
              color: Colors.teal,
              size: 24,
            ),
            title: const Text(
              'Announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/announcements');
            },
          ),
          // Context switcher for all roles
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.indigo, size: 24),
            title: const Text(
              'Switch Dept & Semester',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Affects dashboards and attendance',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              String selectedDept =
                  prefs.getString('selected_department') ??
                  prefs.getString('admin_selected_department') ??
                  'Computer Science and Engineering';
              int selectedSem =
                  prefs.getInt('selected_semester') ??
                  prefs.getInt('admin_selected_semester') ??
                  5;
              const departments = [
                'Computer Science and Engineering',
                'Information Technology',
                'Electronics and Communication Engineering',
                'Artificial Intelligence & Data Science',
                'Artificial Intelligence & Machine Learning',
                'Biomedical Engineering',
                'Robotics and Automation',
                'Mechanical Engineering',
              ];
              await showDialog<void>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Switch Department & Semester'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedDept,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                          items:
                              departments
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) selectedDept = v;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedSem,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                          ),
                          items:
                              List.generate(8, (i) => i + 1)
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text('$s'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) selectedSem = v;
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Persist for all roles
                          await prefs.setString(
                            'selected_department',
                            selectedDept,
                          );
                          await prefs.setInt('selected_semester', selectedSem);
                          // Backward-compat for any admin-specific readers
                          await prefs.setString(
                            'admin_selected_department',
                            selectedDept,
                          );
                          await prefs.setInt(
                            'admin_selected_semester',
                            selectedSem,
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Context updated')),
                          );

                          // Rebuild Home with new context immediately
                          final email =
                              Supabase
                                  .instance
                                  .client
                                  .auth
                                  .currentUser
                                  ?.email ??
                              '';
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder:
                                  (_) => HomeScreen(
                                    userName: email,
                                    department: selectedDept,
                                    semester: selectedSem,
                                  ),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: Colors.grey,
              size: 24,
            ),
            title: const Text(
              'Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 24),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              // Close the drawer first
              Navigator.pop(context);

              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                // Sign out the user
                await _authService.signOut();

                // Navigate to login screen and clear navigation stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
