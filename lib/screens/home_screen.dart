import 'package:flutter/material.dart';
import 'timetable_screen.dart';
import 'timetable_editor_screen.dart'; // Added for direct timetable editing
import 'resource_hub_screen.dart';
import 'announcements_screen.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';
import 'attendance_screen.dart';
import 'regulation_selection_screen.dart';
import 'lost_and_found_screen.dart'; // Added for Lost and Found
import 'about_us_screen.dart'; // Added for About Us
import 'dbms_marks_screen.dart'; // Added for DBMS marks
import 'my_marks_screen.dart'; // Added for student individual marks
import 'faculty_dashboard_screen.dart'; // Added for Faculty Dashboard
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_attendance_screen.dart';
import '../services/auth_service.dart';
import 'role_test_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String department;
  final int semester;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.department,
    required this.semester,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? selectedSemester;
  String? selectedDepartment;
  late AnimationController _animationController;
  bool _isStaff = false;
  bool _isAdmin = false;
  String _userRole = 'student';
  bool _isLoadingRole = true;
  final AuthService _authService = AuthService();

  final List<String> semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> departments = [
    'Computer Science and Engineering',
    'Information Technology',
    'Electronics and Communication Engineering',
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
    'Biomedical Engineering',
    'Robotics and Automation',
    'Mechanical Engineering',
  ];

  @override
  void initState() {
    super.initState();
    selectedSemester = widget.semester.toString();
    if (departments.contains(widget.department)) {
      selectedDepartment = widget.department;
    } else {
      selectedDepartment = 'Computer Science and Engineering';
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

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
        _isLoadingRole = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0.5, // Subtle elevation for light theme
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              color: colorScheme.primary,
              size: 24,
            ), // Accent color for app icon
            SizedBox(width: 8),
            Text(
              'Campus Sync',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _animationController,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                                Text(
                                  widget.userName,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoChip(
                            "Sem: ${selectedSemester ?? widget.semester.toString()}",
                            Icons.calendar_month_outlined,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoChip(
                              "Dept: ${selectedDepartment ?? widget.department}",
                              Icons.school_outlined,
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                      if (!_isLoadingRole) ...[
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  _userRole,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getRoleColor(_userRole),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getRoleIcon(_userRole),
                                    size: 16,
                                    color: _getRoleColor(_userRole),
                                  ),
                                  SizedBox(width: 6),
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
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            _buildSectionTitle("Features", Icons.dashboard_customize_outlined),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFeatureListItem(
                    title: 'Timetable',
                    description: 'View your class schedule',
                    icon: Icons.calendar_today,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TimetableScreen(
                                department: selectedDepartment!,
                                semester: int.parse(selectedSemester!),
                              ),
                        ),
                      );
                    },
                  ),
                  _buildFeatureListItem(
                    title: 'Resource Hub',
                    description: 'Access learning materials',
                    icon: Icons.folder_open,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ResourceHubScreen(
                                department: selectedDepartment!,
                                semester: int.parse(selectedSemester!),
                              ),
                        ),
                      );
                    },
                  ),
                  _buildFeatureListItem(
                    title: 'Announcements',
                    description: 'Latest news and updates',
                    icon: Icons.campaign,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureListItem(
                    title: 'GPA/CGPA Calculator',
                    description: 'Calculate your grades',
                    icon: Icons.calculate,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RegulationSelectionScreen(
                                userDepartment: selectedDepartment!,
                                userSemester: int.parse(selectedSemester!),
                              ),
                        ),
                      );
                    },
                  ),
                  _buildFeatureListItem(
                    title: 'Lost and Found',
                    description: 'Report or find lost items',
                    icon:
                        Icons.find_in_page_outlined, // Icon for Lost and Found
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostAndFoundScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureListItem(
                    title:
                        _isStaff || _isAdmin
                            ? 'Take Attendance'
                            : 'View Attendance',
                    description:
                        _isStaff || _isAdmin
                            ? 'Take daily attendance for your classes'
                            : 'Check your attendance records',
                    icon:
                        _isStaff || _isAdmin
                            ? Icons.assignment_turned_in
                            : Icons.visibility,
                    onTap: () async {
                      if (_isStaff || _isAdmin) {
                        // Staff and Admin can take attendance
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => StaffAttendanceScreen(
                                  department: selectedDepartment!,
                                  semester: int.parse(selectedSemester!),
                                ),
                          ),
                        );
                      } else {
                        // Students can only view attendance
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AttendanceScreen(
                                  department: selectedDepartment!,
                                  semester: int.parse(selectedSemester!),
                                ),
                          ),
                        );
                      }
                    },
                  ),
                  // Separate View Attendance for Staff/Admin
                  if (_isStaff || _isAdmin)
                    _buildFeatureListItem(
                      title: 'View Attendance Records',
                      description: 'Check attendance history and reports',
                      icon: Icons.visibility,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AttendanceScreen(
                                  department: selectedDepartment!,
                                  semester: int.parse(selectedSemester!),
                                ),
                          ),
                        );
                      },
                    ),
                  // Faculty Dashboard for Staff/Admin
                  if (_isStaff || _isAdmin)
                    _buildFeatureListItem(
                      title: 'Faculty Dashboard',
                      description:
                          'Access timetable management, resources, and announcements',
                      icon: Icons.dashboard,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FacultyDashboardScreen(
                                  userName: widget.userName,
                                  department: selectedDepartment!,
                                  semester: int.parse(selectedSemester!),
                                ),
                          ),
                        );
                      },
                    ),
                  // Marks feature
                  _buildFeatureListItem(
                    title:
                        _isStaff || _isAdmin
                            ? 'View All Students\' Marks'
                            : 'My Exam Results',
                    description:
                        _isStaff || _isAdmin
                            ? 'View class examination results'
                            : 'Check your examination marks',
                    icon: Icons.grade,
                    onTap: () {
                      if (_isStaff || _isAdmin) {
                        // Staff/Admin can view all students' marks
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DBMSMarksScreen(),
                          ),
                        );
                      } else {
                        // Students can only view their own marks
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyMarksScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ]),
              ),
            ),

            _buildSectionTitle("Quick Actions", Icons.bolt),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFeatureListItem(
                    title: 'View Today\'s Schedule',
                    description: 'Check classes for today',
                    icon: Icons.today,
                    onTap: () {
                      bool isCSESem4 =
                          (selectedDepartment ?? widget.department).contains(
                            'Computer Science',
                          ) &&
                          (selectedSemester ?? widget.semester.toString()) ==
                              '4';
                      if (isCSESem4) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TimetableScreen(
                                  department: selectedDepartment!,
                                  semester: int.parse(selectedSemester!),
                                ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Detailed timetable is only available for Computer Science Engineering Semester 4',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  // Edit Timetable for Staff/Admin
                  if (_isStaff || _isAdmin)
                    _buildFeatureListItem(
                      title: 'Edit Timetable',
                      description: 'Manage class schedules and periods',
                      icon: Icons.edit_calendar,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TimetableEditorScreen(),
                          ),
                        );
                      },
                    ),
                  _buildFeatureListItem(
                    title: 'Profile Settings',
                    description: 'Manage your account',
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
            // About Us Section
            _buildSectionTitle("Information", Icons.info_outline),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFeatureListItem(
                    title: 'About Us',
                    description: 'Learn more about Campus Sync',
                    icon: Icons.info_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add action
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {bool isExpanded = false}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    Widget chipContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(
          0.08,
        ), // Subtle accent background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary, size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    // return isExpanded ? Expanded(child: chipContent) : chipContent; // Remove Expanded from here
    return chipContent; // Always return just the chip content
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 24.0,
          bottom: 8.0,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureListItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0.5,
      color: colorScheme.surface,
      margin: EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onBackground,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onBackground,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Drawer(
      backgroundColor: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.background),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary.withOpacity(0.8),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(height: 12),
                Text(
                  widget.userName,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${selectedDepartment ?? widget.department} - Sem ${selectedSemester ?? widget.semester.toString()}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(),
                ),
              );
            },
          ),
          // Temporarily show test screen to all users for debugging
          Divider(color: Colors.grey[300]),
          _buildDrawerItem(
            icon: Icons.bug_report_outlined,
            title: 'Role Setup Test',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RoleTestScreen()),
              );
            },
          ),
          Divider(color: Colors.grey[300]),
          _buildDrawerItem(
            icon: Icons.school_outlined,
            title: 'Switch Department/Semester',
            onTap: () {
              Navigator.pop(context);
              _showDepartmentSemesterDialog();
            },
          ),
          if (_isAdmin) ...[
            Divider(color: Colors.grey[300]),
            _buildDrawerItem(
              icon: Icons.admin_panel_settings,
              title: 'Admin Tools',
              onTap: () {
                Navigator.pop(context);
                // Add admin-specific functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admin tools coming soon!')),
                );
              },
            ),
          ],
          Divider(color: Colors.grey[300]),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
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
        throw Exception("Unknown role: $role");
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
        throw Exception("Unknown role: $role");
    }
  }

  void _showDepartmentSemesterDialog() {
    String tempDepartment = selectedDepartment ?? widget.department;
    String tempSemester = selectedSemester ?? widget.semester.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.school, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text('Switch Department & Semester'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Department:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempDepartment,
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        items:
                            [
                              'Computer Science and Engineering',
                              'Electronics and Communication Engineering',
                              'Mechanical Engineering',
                              'Civil Engineering',
                              'Electrical and Electronics Engineering',
                              'Information Technology',
                              'Chemical Engineering',
                              'Biotechnology',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              tempDepartment = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select Semester:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempSemester,
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        items:
                            ['1', '2', '3', '4', '5', '6', '7', '8'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  'Semester $value',
                                  style: TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              tempSemester = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will change your view to show content for the selected department and semester.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the selected department and semester
                    this.setState(() {
                      selectedDepartment = tempDepartment;
                      selectedSemester = tempSemester;
                    });

                    Navigator.of(context).pop();

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Switched to $tempDepartment - Semester $tempSemester',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Apply Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
