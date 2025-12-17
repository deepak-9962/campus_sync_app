import 'package:flutter/material.dart';
import 'timetable_screen.dart';
import 'resource_hub_screen.dart';
import 'announcements_screen.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';
import 'regulation_selection_screen.dart';
import 'lost_and_found_screen.dart';
import 'about_us_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'attendance_screen.dart';
import 'staff_attendance_screen.dart';
import 'faculty_dashboard_screen.dart';
import 'timetable_editor_screen.dart';
import 'exams_screen.dart';
import 'attendance_view_screen.dart';
import 'all_students_attendance_screen.dart';
import 'daily_attendance_screen.dart';
import 'hod_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../services/hod_service.dart';
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
  final HODService _hodService = HODService();
  String? _assignedDepartment;

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

      // Fetch assigned department (for HOD/Admin)
      try {
        final info = await _hodService.getUserRoleInfo();
        _assignedDepartment =
            (info['assignedDepartment'] is String &&
                    (info['assignedDepartment'] as String).isNotEmpty)
                ? info['assignedDepartment'] as String
                : null;
      } catch (_) {
        _assignedDepartment = null;
      }

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

  Future<void> _refreshHome() async {
    await _checkUserRole();
  }

  Future<void> _showChangeContextDialog() async {
    String tempDepartment = selectedDepartment ?? departments.first;
    String tempSemester = selectedSemester ?? semesters.first;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Department & Semester'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempDepartment,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Department'),
                items:
                    departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) tempDepartment = v;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tempSemester,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Semester'),
                items:
                    semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) tempSemester = v;
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
              onPressed: () {
                setState(() {
                  selectedDepartment = tempDepartment;
                  selectedSemester = tempSemester;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
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
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: colorScheme.primary, size: 24),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Change Department & Semester',
            onPressed: _showChangeContextDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
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
                              if ((_userRole.toLowerCase() == 'hod' ||
                                      _isAdmin) &&
                                  _assignedDepartment != null) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(
                                      _userRole,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getRoleColor(
                                        _userRole,
                                      ).withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.apartment,
                                        size: 16,
                                        color: _getRoleColor(_userRole),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Dept: ${_assignedDepartment!}',
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
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              _buildSectionTitle(
                "Features",
                Icons.dashboard_customize_outlined,
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // HOD Dashboard pinned to top for HOD/Admin
                    if (_userRole.toLowerCase() == 'hod' || _isAdmin)
                      _buildFeatureListItem(
                        title: 'HOD Dashboard',
                        description: 'Department-wide attendance & insights',
                        icon: Icons.account_balance,
                        iconColor: Colors.indigo[700],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => HODDashboardScreen(
                                    department:
                                        (_assignedDepartment ??
                                            selectedDepartment ??
                                            widget.department),
                                    hodName: widget.userName,
                                  ),
                            ),
                          );
                        },
                      ),
                    // Faculty Dashboard for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'Faculty Dashboard',
                        description: 'Access faculty tools and overview',
                        icon: Icons.dashboard,
                        iconColor: Colors.orange[700],
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

                    // Timetable Editor for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'Edit Timetable',
                        description: 'Manage and edit class schedules',
                        icon: Icons.edit_calendar,
                        iconColor: Colors.purple[700],
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

                    // Exam Management for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'Manage Exams',
                        description: 'Schedule and manage examinations',
                        icon: Icons.quiz,
                        iconColor: Colors.red[700],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ExamsScreen(
                                    department: selectedDepartment!,
                                    semester: int.parse(selectedSemester!),
                                  ),
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
                      icon: Icons.find_in_page_outlined,
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

                    // View Attendance for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'View Attendance',
                        description:
                            'Monitor attendance records and statistics',
                        icon: Icons.analytics,
                        iconColor: Colors.teal[700],
                        onTap: () {
                          _showAttendanceViewOptions();
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
                    // Faculty Quick Access for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'Faculty Dashboard',
                        description: 'Quick access to faculty tools',
                        icon: Icons.dashboard_outlined,
                        iconColor: Colors.orange[600],
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

                    // Today's Attendance for Staff/Admin
                    if (_isStaff || _isAdmin)
                      _buildFeatureListItem(
                        title: 'Today\'s Attendance',
                        description: 'View and manage today\'s attendance',
                        icon: Icons.today_outlined,
                        iconColor: Colors.green[600],
                        onTap: () {
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
          ), // CustomScrollView
        ), // RefreshIndicator
      ), // SafeArea

      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
        color: colorScheme.primary.withOpacity(0.08),
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
    return chipContent;
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
          if (_isStaff || _isAdmin) ...[
            Divider(color: Colors.grey[300]),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Faculty Dashboard',
              onTap: () {
                Navigator.pop(context);
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
          ],
          // HOD Dashboard drawer entry for HOD users and Admins
          if (_userRole.toLowerCase() == 'hod' || _isAdmin) ...[
            _buildDrawerItem(
              icon: Icons.account_balance,
              title: 'HOD Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => HODDashboardScreen(
                          department: selectedDepartment ?? widget.department,
                          hodName: widget.userName,
                        ),
                  ),
                );
              },
            ),
          ],
          if (_isStaff || _isAdmin) ...[
            _buildDrawerItem(
              icon: Icons.edit_calendar,
              title: 'Edit Timetable',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimetableEditorScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.quiz,
              title: 'Manage Exams',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ExamsScreen(
                          department: selectedDepartment!,
                          semester: int.parse(selectedSemester!),
                        ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.analytics,
              title: 'View Attendance',
              onTap: () {
                Navigator.pop(context);
                _showAttendanceViewOptions();
              },
            ),
          ],
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
          _buildDrawerItem(
            icon: Icons.swap_horiz,
            title: 'Switch Dept & Semester',
            onTap: () {
              Navigator.pop(context);
              _showChangeContextDialog();
            },
          ),
          if (_isAdmin) ...[
            Divider(color: Colors.grey[300]),
            _buildDrawerItem(
              icon: Icons.admin_panel_settings,
              title: 'Admin Tools',
              onTap: () {
                Navigator.pop(context);
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

  void _showAttendanceViewOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'View Attendance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.today, color: Colors.blue[700]),
                ),
                title: Text('Today\'s Attendance'),
                subtitle: Text('View attendance records for today'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AttendanceViewScreen(
                            department: selectedDepartment!,
                            semester: int.parse(selectedSemester!),
                          ),
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics, color: Colors.green[700]),
                ),
                title: Text('Overall Attendance'),
                subtitle: Text('View overall attendance statistics'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AllStudentsAttendanceScreen(
                            department: selectedDepartment!,
                            semester: int.parse(selectedSemester!),
                          ),
                    ),
                  );
                },
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month, color: Colors.orange[700]),
                ),
                title: Text('Daily Attendance'),
                subtitle: Text('View day-wise attendance records'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showSectionSelector();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSectionSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                ['A', 'B', 'C'].map((section) {
                  return ListTile(
                    title: Text('Section $section'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DailyAttendanceScreen(
                                department: selectedDepartment!,
                                semester: int.parse(selectedSemester!),
                                section: section,
                              ),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.green[700]!;
      case 'staff':
      case 'faculty':
      case 'hod':
        return Colors.blue[700]!;
      case 'admin':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Icons.person;
      case 'staff':
      case 'faculty':
      case 'hod':
        return Icons.school;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person_outline;
    }
  }
}
