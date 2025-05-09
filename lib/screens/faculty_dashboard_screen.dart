import 'package:flutter/material.dart';
import 'timetable_screen.dart';
import 'resource_hub_screen.dart';
import 'announcements_screen.dart';
import 'exams_screen.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacultyDashboardScreen extends StatefulWidget {
  final String userName;
  final String department;
  final int semester;

  const FacultyDashboardScreen({
    super.key,
    required this.userName,
    required this.department,
    required this.semester,
  });

  @override
  _FacultyDashboardScreenState createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Colors for gradient
  final List<Color> _gradientColors = [
    Color(0xFF1A237E), // Deep blue
    Color(0xFF512DA8), // Deep purple
    Color(0xFF303F9F), // Indigo
  ];

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF1976D2), const Color(0xFF42A5F5)], // Blue
    [const Color(0xFF7B1FA2), const Color(0xFFAB47BC)], // Purple
    [const Color(0xFF512DA8), const Color(0xFF673AB7)], // Deep Purple
    [const Color(0xFF00796B), const Color(0xFF26A69A)], // Teal
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Faculty Dashboard',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // Header section with welcome message
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.0, 0.4, curve: Curves.easeOut),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, -0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.0, 0.4, curve: Curves.easeOut),
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.person_2,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Professor,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                  ),
                                  Text(
                                    widget.userName,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Department info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Department',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontFamily: 'Clash Grotesk',
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.department,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 16),

                            // Semester info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Teaching Semester',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontFamily: 'Clash Grotesk',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.semester.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Clash Grotesk',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Class stats section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'TODAY\'S CLASSES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontFamily: 'Clash Grotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's classes list
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Examples of today's classes - these would be dynamic in a real app
                        _buildClassCard(
                          'Database Management Systems',
                          'CSE 4A - Room 302',
                          '9:00 AM - 10:30 AM',
                          Colors.blue.shade700,
                        ),
                        SizedBox(height: 16),
                        _buildClassCard(
                          'Artificial Intelligence',
                          'CSE 4B - Lab 103',
                          '11:00 AM - 12:30 PM',
                          Colors.purple.shade700,
                        ),
                        SizedBox(height: 16),
                        _buildClassCard(
                          'Operating Systems',
                          'CSE 4C - Room 205',
                          '2:00 PM - 3:30 PM',
                          Colors.deepPurple.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Functions section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.dashboard_customize_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'FACULTY FUNCTIONS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontFamily: 'Clash Grotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Faculty functions grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.5, 0.9, curve: Curves.easeOut),
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildFunctionCard(
                          'Class Schedule',
                          Icons.calendar_today_outlined,
                          _cardGradients[0],
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => TimetableScreen(
                                      department: widget.department,
                                      semester: widget.semester,
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildFunctionCard(
                          'Upload Resources',
                          Icons.upload_file_outlined,
                          _cardGradients[1],
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ResourceHubScreen(
                                      department: widget.department,
                                      semester: widget.semester,
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildFunctionCard(
                          'Manage Exams',
                          Icons.quiz_outlined,
                          _cardGradients[2],
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ExamsScreen(
                                      department: widget.department,
                                      semester: widget.semester,
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildFunctionCard(
                          'Post Announcements',
                          Icons.campaign_outlined,
                          _cardGradients[3],
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradientColors[0], _gradientColors[1]],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person_2,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Prof. ${widget.userName}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Clash Grotesk',
                      ),
                    ),
                    Text(
                      widget.department,
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Clash Grotesk',
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerTile('Dashboard', Icons.dashboard_outlined, () {
                Navigator.pop(context);
              }),
              _buildDrawerTile(
                'Class Schedule',
                Icons.calendar_today_outlined,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TimetableScreen(
                            department: widget.department,
                            semester: widget.semester,
                          ),
                    ),
                  );
                },
              ),
              _buildDrawerTile(
                'Upload Resources',
                Icons.upload_file_outlined,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ResourceHubScreen(
                            department: widget.department,
                            semester: widget.semester,
                          ),
                    ),
                  );
                },
              ),
              _buildDrawerTile('Manage Exams', Icons.quiz_outlined, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ExamsScreen(
                          department: widget.department,
                          semester: widget.semester,
                        ),
                  ),
                );
              }),
              _buildDrawerTile(
                'Post Announcements',
                Icons.campaign_outlined,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementsScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerTile('Profile Settings', Icons.settings_outlined, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsScreen(),
                  ),
                );
              }),
              Divider(color: Colors.white24, thickness: 1),
              _buildDrawerTile('Logout', Icons.logout, () async {
                Navigator.pop(context); // Close the drawer

                try {
                  // Sign out from Supabase
                  await Supabase.instance.client.auth.signOut();

                  if (mounted) {
                    // Navigate to AuthScreen and clear all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => AuthScreen()),
                      (route) => false, // This removes all previous routes
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement quick action for faculty
        },
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: _gradientColors[0]),
      ),
    );
  }

  Widget _buildClassCard(
    String className,
    String classDetails,
    String timeSlot,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Show class details
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Clash Grotesk',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        classDetails,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Clash Grotesk',
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            timeSlot,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Clash Grotesk',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionCard(
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 42),
                  SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Clash Grotesk',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontFamily: 'Clash Grotesk'),
      ),
      onTap: onTap,
    );
  }
}
