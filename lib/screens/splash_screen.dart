// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Key to store login status
  static const String _firstTimeKey = 'first_time_open';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() async {
    // Wait for animation to play
    await Future.delayed(const Duration(seconds: 2));

    // Check if this is the first time opening the app
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

    // Get current authentication session
    final session = Supabase.instance.client.auth.currentSession;

    // Begin reverse animation before navigation
    _controller.reverse().then((_) {
      // If it's first time or user is not logged in, go to auth screen
      if (isFirstTime || session == null) {
        // If first time, update the preference to false for next time
        if (isFirstTime) {
          prefs.setBool(_firstTimeKey, false);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      } else {
        // User is already logged in and it's not first time
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeScreen(
                  userName: session.user.email ?? '',
                  department: 'Computer Science and Engineering',
                  semester: 5,
                ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school,
                      size: 70,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // App name
                Text(
                  'Campus Sync',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,

                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 20),
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
