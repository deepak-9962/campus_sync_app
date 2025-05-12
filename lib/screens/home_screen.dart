import 'package:flutter/material.dart';
import 'timetable_screen.dart';
import 'resource_hub_screen.dart';
import 'announcements_screen.dart';
import 'library_screen.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';
import 'exams_screen.dart';
import 'attendance_screen.dart';
import 'regulation_selection_screen.dart';
import 'lost_and_found_screen.dart'; // Added for Lost and Found
import 'about_us_screen.dart'; // Added for About Us
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Light Theme Colors
  static const Color primaryLightBackground = Color(0xFFF5F5F5); // Off-white
  static const Color cardLightBackground = Colors.white;
  static const Color primaryTextLight = Color(
    0xFF212121,
  ); // Very dark grey (almost black)
  static const Color secondaryTextLight = Color(0xFF757575); // Medium grey
  static const Color iconLight = Color(0xFF424242); // Darker grey for icons
  static const Color accentColorLight = Color(0xFF1976D2); // Blue 700

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLightBackground,
      appBar: AppBar(
        backgroundColor: cardLightBackground,
        elevation: 0.5, // Subtle elevation for light theme
        centerTitle: true,
        iconTheme: IconThemeData(color: iconLight),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              color: accentColorLight,
              size: 24,
            ), // Accent color for app icon
            SizedBox(width: 8),
            Text(
              'Campus Sync',
              style: TextStyle(
                fontFamily: 'Clash Grotesk',
                fontWeight: FontWeight.bold,
                color: primaryTextLight,
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
                    color: cardLightBackground,
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
                            backgroundColor: accentColorLight.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: accentColorLight,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextLight,
                                    fontFamily: 'Clash Grotesk',
                                  ),
                                ),
                                Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextLight,
                                    fontFamily: 'Clash Grotesk',
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
        backgroundColor: accentColorLight,
        foregroundColor: Colors.white,
        child: Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {bool isExpanded = false}) {
    Widget chipContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColorLight.withOpacity(0.08), // Subtle accent background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColorLight, size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: accentColorLight,
                fontFamily: 'Clash Grotesk',
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
                color: accentColorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColorLight, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextLight,
                letterSpacing: 1.1,
                fontFamily: 'Clash Grotesk',
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
    return Card(
      elevation: 0.5,
      color: cardLightBackground,
      margin: EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? accentColorLight).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? accentColorLight, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryTextLight,
            fontWeight: FontWeight.w500,
            fontFamily: 'Clash Grotesk',
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: secondaryTextLight,
            fontFamily: 'Clash Grotesk',
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: secondaryTextLight,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardLightBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryLightBackground),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: accentColorLight.withOpacity(0.8),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(height: 12),
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: primaryTextLight,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Clash Grotesk',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${selectedDepartment ?? widget.department} - Sem ${selectedSemester ?? widget.semester.toString()}',
                  style: TextStyle(
                    color: secondaryTextLight,
                    fontSize: 13,
                    fontFamily: 'Clash Grotesk',
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
    return ListTile(
      leading: Icon(icon, color: iconLight),
      title: Text(
        title,
        style: TextStyle(
          color: primaryTextLight,
          fontFamily: 'Clash Grotesk',
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
