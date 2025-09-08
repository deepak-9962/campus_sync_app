import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/auth_service.dart';
// import 'dart:math' as math; // WavesPainter removed

class SemScreen extends StatefulWidget {
  final String userName;

  const SemScreen({super.key, required this.userName});

  @override
  _SemScreenState createState() => _SemScreenState();
}

class _SemScreenState extends State<SemScreen>
    with SingleTickerProviderStateMixin {
  String? selectedDepartment;
  int? selectedSemester;
  bool _showError = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  final List<String> departments = [
    'Artificial Intelligence & Data Science',
    'Artificial Intelligence & Machine Learning',
    'Biomedical Engineering',
    'Computer Science and Engineering',
    'Electronics and Communication Engineering',
    'Information Technology',
    'Robotics and Automation',
    'Mechanical Engineering',
  ];

  final List<int> semesters = List<int>.generate(8, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndNavigate();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkUserRoleAndNavigate() async {
    try {
      // Check if user is admin
      final isAdmin = await _authService.isAdmin();

      if (isAdmin) {
        // Admin users skip department/semester selection and go directly to admin dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AdminDashboardScreen(userName: widget.userName),
              ),
            );
          }
        });
      }
      // Non-admin users continue with normal flow (department/semester selection)
    } catch (e) {
      print('Error checking user role: $e');
      // Continue with normal flow if role check fails
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continue() {
    if (selectedDepartment != null && selectedSemester != null) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Check if widget is still in the tree
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => HomeScreen(
                    department: selectedDepartment!,
                    semester: selectedSemester!,
                    userName: widget.userName,
                  ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                var begin = const Offset(0.0, 0.1);
                var end = Offset.zero;
                var curve = Curves.easeOutQuint;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              transitionDuration: const Duration(milliseconds: 450),
            ),
          );
        }
      });
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // extendBodyBehindAppBar: true, // Not needed with solid AppBar
      appBar: AppBar(
        // backgroundColor: Colors.transparent, // Will use theme's AppBarTheme
        // elevation: 0,
        title: Text(
          'Student Setup',
          // style will be picked from appBarTheme.titleTextStyle
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(scale: _scaleAnimation, child: child),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      height: 100,
                      width: 100,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface, // Use theme surface
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: theme.colorScheme.primary, // Use theme accent
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Welcome, ${widget.userName}!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set up your academic profile to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 50),

                  _buildDropdownField(
                    context: context,
                    icon: Icons.school,
                    title: 'Department',
                    errorText:
                        _showError && selectedDepartment == null
                            ? 'Please select a department'
                            : null,
                    child: DropdownButtonFormField<String>(
                      // decoration will be from theme.inputDecorationTheme
                      decoration: InputDecoration(
                        hintText: 'Select your department',
                        // hintStyle will be from theme
                      ),
                      dropdownColor: theme.cardColor,
                      style: TextStyle(
                        color:
                            theme
                                .colorScheme
                                .onSurface, // Selected item text color

                        fontSize: 15,
                      ),
                      iconEnabledColor: theme.iconTheme.color,
                      value: selectedDepartment,
                      items:
                          departments.map((String department) {
                            return DropdownMenuItem<String>(
                              value: department,
                              child: Text(
                                department,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDepartment = newValue;
                          if (newValue != null) _showError = false;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  SizedBox(height: 20),

                  _buildDropdownField(
                    context: context,
                    icon: Icons.calendar_today,
                    title: 'Semester',
                    errorText:
                        _showError && selectedSemester == null
                            ? 'Please select a semester'
                            : null,
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        hintText: 'Select your semester',
                        // hintStyle will be from theme
                      ),
                      dropdownColor: theme.cardColor,
                      style: TextStyle(
                        color:
                            theme
                                .colorScheme
                                .onSurface, // Selected item text color

                        fontSize: 15,
                      ),
                      iconEnabledColor: theme.iconTheme.color,
                      value: selectedSemester,
                      items:
                          semesters.map((int semester) {
                            return DropdownMenuItem<int>(
                              value: semester,
                              child: Text(semester.toString()),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedSemester = newValue;
                          if (newValue != null) _showError = false;
                        });
                      },
                      isExpanded: true,
                    ),
                  ),
                  SizedBox(height: 60),

                  ElevatedButton(
                    // Style from ElevatedButtonThemeData
                    onPressed: _isLoading ? null : _continue,
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                            : Text('CONTINUE'),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context, // Added context to access theme
    required IconData icon,
    required String title,
    required Widget child,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.iconTheme.color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,

                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // The DropdownButtonFormField itself will use the InputDecorationTheme
        // for its background/border, so no need for an extra container here
        // if the global theme is set up correctly.
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorText,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// WavesPainter removed as background is now solid based on theme
