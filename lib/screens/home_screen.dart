import 'package:flutter/material.dart';
import 'timetable_screen.dart';
import 'resource_hub_screen.dart';
import 'announcements_screen.dart';
import 'library_screen.dart';
import 'auth_screen.dart';
import 'profile_settings_screen.dart';
import 'exams_screen.dart';
import 'attendance_screen.dart';
// import 'gpa_cgpa_calculator_screen.dart'; // Commented out direct import
import 'regulation_selection_screen.dart'; // Added import for regulation selection
import 'dart:math' as math;
import 'dart:ui';
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
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF2C3E50), const Color(0xFF3498DB)], // Blue theme
    [const Color(0xFF34495E), const Color(0xFF2ECC71)], // Green theme
    [const Color(0xFF2C3E50), const Color(0xFFE74C3C)], // Red theme
    [const Color(0xFF34495E), const Color(0xFF9B59B6)], // Purple theme
  ];

  // Colors for drawer gradient
  final List<Color> _drawerGradientColors = [
    Color(0xFF2C3E50), // Dark blue-gray
    Color(0xFF3498DB), // Light blue
  ];

  final List<String> semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> departments = [
    'Computer Science Engineering',
    'Information Technology',
    'Electronic Communication',
    'AiML',
    'AiDS',
    'Mechanical',
  ];

  double _currentPageValue = 0.0;
  PageController _pageController = PageController(viewportFraction: 0.9);
  double _scaleFactor = 0.9;

  // Bubble animation values
  List<Offset> bubblePositions = [];
  List<double> bubbleSizes = [];
  List<double> bubbleOpacities = [];

  @override
  void initState() {
    super.initState();
    selectedSemester = widget.semester.toString();
    selectedDepartment = widget.department;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Initialize bubbles with more subtle values and ensure they're within screen bounds
    for (int i = 0; i < 10; i++) {
      bubblePositions.add(
        Offset(
          math.Random().nextDouble() * 300,
          math.Random().nextDouble() *
              600, // Reduced to avoid offscreen bubbles
        ),
      );
      bubbleSizes.add(math.Random().nextDouble() * 30 + 10); // Smaller bubbles
      bubbleOpacities.add(
        math.Random().nextDouble() * 0.1 + 0.02,
      ); // More subtle opacity
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // _pageController.dispose(); // Remove this as we're not using PageView
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Campus Sync',
              style: TextStyle(
                fontFamily: 'Clash Grotesk',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          // Simplified Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C3E50), // Dark blue-gray
                  Color(0xFF3498DB), // Light blue
                ],
              ),
            ),
          ),
          // More subtle bubble background
          CustomPaint(
            size: Size(width, double.infinity),
            painter: BubblePainter(
              bubblePositions: bubblePositions,
              bubbleSizes: bubbleSizes,
              bubbleOpacities: bubbleOpacities,
            ),
          ),
          // Main Content
          SafeArea(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              0.0,
                              0.5,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, -0.05),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.0,
                                0.5,
                                curve: Curves.easeOutQuint,
                              ),
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
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
                                      radius: 18,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back,',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                              fontFamily: 'Clash Grotesk',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            widget.userName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Clash Grotesk',
                                              letterSpacing: -0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildInfoCard(
                                      "Semester",
                                      selectedSemester ??
                                          widget.semester.toString(),
                                      Icons.calendar_month_outlined,
                                      [
                                        Colors.deepPurple.shade400,
                                        Colors.deepPurple.shade200,
                                      ],
                                    ),
                                    SizedBox(width: 8),
                                    _buildInfoCard(
                                      "Department",
                                      selectedDepartment?.substring(
                                            0,
                                            math.min(
                                              10,
                                              selectedDepartment?.length ?? 0,
                                            ),
                                          ) ??
                                          "CS",
                                      Icons.school_outlined,
                                      [
                                        Colors.blue.shade400,
                                        Colors.blue.shade200,
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Features Section Title
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
                            Icons.dashboard_customize_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'FEATURES',
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

                // Feature Cards in Vertical List
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
                        child: child,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildFeatureListItem(
                            title: 'Timetable',
                            description:
                                'View your class schedule and manage your time',
                            icon: Icons.calendar_today,
                            color: Color(0xFF3498DB),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => TimetableScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Resource Hub',
                            description:
                                'Access learning materials and resources',
                            icon: Icons.folder,
                            color: Color(0xFF2ECC71),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => ResourceHubScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Announcements',
                            description:
                                'Stay updated with the latest news and announcements',
                            icon: Icons.campaign,
                            color: Color(0xFFE74C3C),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => AnnouncementsScreen(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Library',
                            description:
                                'Browse and read books from the digital library',
                            icon: Icons.book,
                            color: Color(0xFF9B59B6),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => LibraryScreen(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Exams & Results',
                            description:
                                'View exam schedules and check your results',
                            icon: Icons.quiz,
                            color: Color(0xFFF39C12),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => ExamsScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Attendance',
                            description:
                                'Check your attendance percentages for all subjects',
                            icon: Icons.fact_check,
                            color: Color(0xFF00BCD4),
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => AttendanceScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Student Community',
                            description:
                                'Connect with peers and join discussion forums',
                            icon: Icons.people,
                            color: Color(0xFF1ABC9C),
                            onTap: () {
                              // Show a feature coming soon message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Student Community feature coming soon!',
                                  ),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            // Added GPA/CGPA Calculator
                            title: 'GPA/CGPA Calculator',
                            description: 'Calculate your Grade Point Averages',
                            icon: Icons.calculate,
                            color: Color(0xFFE67E22), // Orange color
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => RegulationSelectionScreen(
                                        userDepartment:
                                            selectedDepartment ??
                                            widget.department,
                                        userSemester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ), // Navigate to RegulationSelectionScreen
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildFeatureListItem(
                            title: 'Campus Map',
                            description:
                                'Navigate campus buildings and find classrooms',
                            icon: Icons.map,
                            color: Color(0xFF607D8B),
                            onTap: () {
                              // Show a feature coming soon message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Campus Map feature coming soon!',
                                  ),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Quick Actions Title
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
                            Icons.bolt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'QUICK ACTIONS',
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

                // Quick Action Buttons - Convert to vertical list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.5,
                                  0.9,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          _buildQuickActionItem(
                            'View Today',
                            'Check your schedule for today',
                            Icons.today,
                            Colors.purple.shade300,
                            () {
                              // Check if user is CSE sem 4 before navigating to timetable
                              bool isCSESem4 =
                                  (selectedDepartment ?? widget.department)
                                      .contains('Computer Science') &&
                                  (selectedSemester ??
                                          widget.semester.toString()) ==
                                      '4';

                              if (isCSESem4) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => TimetableScreen(
                                          department:
                                              selectedDepartment ??
                                              widget.department,
                                          semester: int.parse(
                                            selectedSemester ??
                                                widget.semester.toString(),
                                          ),
                                        ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.1),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                // Show message for students from other departments/semesters
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Detailed timetable is only available for Computer Science Engineering Semester 4',
                                    ),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          // Show special CSE Sem 4 timetable button only if applicable
                          if ((selectedDepartment ?? widget.department)
                                  .contains('Computer Science') &&
                              (selectedSemester ??
                                      widget.semester.toString()) ==
                                  '4')
                            Column(
                              children: [
                                SizedBox(height: 12),
                                _buildQuickActionItem(
                                  'CSE Sem 4 Timetable',
                                  'View detailed timetable for CSE Sem 4 Section A',
                                  Icons.calendar_view_week,
                                  Colors.indigo.shade400,
                                  () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => TimetableScreen(
                                              department:
                                                  'Computer Science Engineering',
                                              semester: 4,
                                            ),
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.1),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          SizedBox(height: 12),
                          _buildQuickActionItem(
                            'Study Resources',
                            'Access study materials and guides',
                            Icons.auto_stories,
                            Colors.orange.shade300,
                            () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => ResourceHubScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.1),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildQuickActionItem(
                            'Exams',
                            'Check your upcoming exams and results',
                            Icons.quiz,
                            Colors.teal.shade300,
                            () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => ExamsScreen(
                                        department:
                                            selectedDepartment ??
                                            widget.department,
                                        semester: int.parse(
                                          selectedSemester ??
                                              widget.semester.toString(),
                                        ),
                                      ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.1),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 12),
                          _buildQuickActionItem(
                            'Settings',
                            'Manage your profile and preferences',
                            Icons.settings,
                            Colors.blue.shade300,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileSettingsScreen(),
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
        ],
      ),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add action
        },
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2C5364),
        elevation: 10,
        child: Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _drawerGradientColors,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C3E50).withOpacity(0.9),
                    Color(0xFF3498DB).withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.department} - Semester ${widget.semester}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
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
              icon: Icons.settings,
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
            Divider(color: Colors.white.withOpacity(0.2), height: 32),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontFamily: 'Clash Grotesk'),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8), // Reduced space
            Expanded(
              // Added Expanded to ensure text fits
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Clash Grotesk',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.bold,
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
      ),
    );
  }

  // New method for quick action item in list form with blur effect
  Widget _buildQuickActionItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Clash Grotesk',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Clash Grotesk',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8), // Added spacing
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // New method for feature list items
  Widget _buildFeatureListItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Clash Grotesk',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Clash Grotesk',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8), // Added spacing
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(String department) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50).withOpacity(0.8),
            Color(0xFF3498DB).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedDepartment = department;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                department,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Clash Grotesk',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(String semester) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50).withOpacity(0.8),
            Color(0xFF3498DB).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedSemester = semester;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Semester $semester',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Clash Grotesk',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final List<Offset> bubblePositions;
  final List<double> bubbleSizes;
  final List<double> bubbleOpacities;

  BubblePainter({
    required this.bubblePositions,
    required this.bubbleSizes,
    required this.bubbleOpacities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < bubblePositions.length; i++) {
      final paint =
          Paint()
            ..color = Colors.white.withOpacity(bubbleOpacities[i])
            ..style = PaintingStyle.fill;

      canvas.drawCircle(bubblePositions[i], bubbleSizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
