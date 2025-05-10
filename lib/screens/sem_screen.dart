import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:math' as math;

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

  // Colors for gradient
  final List<Color> _gradientColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFF512DA8), // Deep Purple
    Color(0xFF5C6BC0), // Indigo
  ];

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continue() {
    if (selectedDepartment != null && selectedSemester != null) {
      setState(() => _isLoading = true);

      // Add a small delay to show the loading indicator
      Future.delayed(const Duration(milliseconds: 300), () {
        // Navigate to student home screen
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
      });
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Student Setup',
          style: TextStyle(
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(painter: WavesPainter(), child: Container()),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and welcome text
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          height: 100,
                          width: 100,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.school,
                            size: 60,
                            color: _gradientColors[1],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Welcome, ${widget.userName}!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Clash Grotesk',
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Set up your academic profile to continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'Clash Grotesk',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 50),

                      // Department dropdown
                      _buildDropdownField(
                        icon: Icons.school,
                        title: 'Department',
                        errorText:
                            _showError && selectedDepartment == null
                                ? 'Please select a department'
                                : null,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'Select your department',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(
                                0.75,
                              ), // Increased opacity
                              fontFamily: 'Clash Grotesk',
                            ),
                            border: InputBorder.none,
                          ),
                          dropdownColor: _gradientColors[0],
                          style: TextStyle(
                            color: Colors.white, // Selected item text color
                            fontFamily: 'Clash Grotesk',
                            fontSize: 15,
                          ),
                          iconEnabledColor: Colors.white, // Arrow color
                          icon: Icon(
                            Icons.arrow_drop_down,
                          ), // Removed explicit color here, using iconEnabledColor
                          value: selectedDepartment,
                          items:
                              departments.map((String department) {
                                return DropdownMenuItem<String>(
                                  value: department,
                                  child: Text(department),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDepartment = newValue;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // Semester dropdown
                      _buildDropdownField(
                        icon: Icons.calendar_today,
                        title: 'Semester',
                        errorText:
                            _showError && selectedSemester == null
                                ? 'Please select a semester'
                                : null,
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            hintText: 'Select your semester',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(
                                0.75,
                              ), // Increased opacity
                              fontFamily: 'Clash Grotesk',
                            ),
                            border: InputBorder.none,
                          ),
                          dropdownColor: _gradientColors[0],
                          style: TextStyle(
                            color: Colors.white, // Selected item text color
                            fontFamily: 'Clash Grotesk',
                            fontSize: 15,
                          ),
                          iconEnabledColor: Colors.white, // Arrow color
                          icon: Icon(
                            Icons.arrow_drop_down,
                          ), // Removed explicit color here, using iconEnabledColor
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
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 60),

                      // Continue button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _gradientColors[1],
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _continue,
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _gradientColors[1],
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Clash Grotesk',
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String title,
    required Widget child,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Clash Grotesk',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  errorText != null
                      ? Colors.red.shade300
                      : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
                fontFamily: 'Clash Grotesk',
              ),
            ),
          ),
      ],
    );
  }
}

// Custom Painter for Wave Background
class WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    final path = Path();

    // First wave
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    paint.color = Colors.white.withOpacity(0.05);

    path2.moveTo(0, size.height * 0.9);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.9,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.9,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
