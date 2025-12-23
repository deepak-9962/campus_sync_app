import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
// import 'dart:math' as math; // BubblesPainter removed

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  String? _userRole;
  String? _registrationError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    if (session != null && mounted) {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/selection');
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _registrationError = null;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    try {
      if (_isLogin) {
        final AuthResponse response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.session != null && mounted) {
          await Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/selection');
            }
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } else {
        // SIGNUP FLOW
        final registrationNo = _registrationController.text.trim().toUpperCase();
        
        // Validate registration number is provided
        if (registrationNo.isEmpty) {
          setState(() {
            _registrationError = 'Registration number is required';
            _isLoading = false;
          });
          return;
        }
        
        // Verify registration number exists in students table
        final studentCheck = await supabase
            .from('students')
            .select('registration_no, student_name, department, current_semester, section, user_id')
            .eq('registration_no', registrationNo)
            .maybeSingle();
        
        if (studentCheck == null) {
          setState(() {
            _registrationError = 'Registration number not found. Contact admin.';
            _isLoading = false;
          });
          return;
        }
        
        // Check if already linked to another account
        if (studentCheck['user_id'] != null) {
          setState(() {
            _registrationError = 'This registration number is already linked to an account';
            _isLoading = false;
          });
          return;
        }
        
        // Clear any previous error
        setState(() => _registrationError = null);
        
        // Proceed with signup
        final AuthResponse response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null && mounted) {
          // Create users table record with proper defaults
          try {
            final studentName = studentCheck['student_name'] ?? '';
            await supabase.from('users').upsert({
              'id': response.user!.id,
              'email': _emailController.text.trim(),
              'name': studentName,
              'role': 'student',
              'is_admin': false,
            }, onConflict: 'id');
            
            // Link user_id to students table record
            await supabase
                .from('students')
                .update({'user_id': response.user!.id})
                .eq('registration_no', registrationNo);
                
            print('Successfully linked user to student record');
          } catch (e) {
            print('Error creating/linking user record: $e');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration successful! Please check your email to verify your account.',
              ),
            ),
          );
          setState(() {
            _isLogin = true;
            _registrationController.clear();
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed. Please try again.'),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _socialLogin(String provider) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$provider login coming soon!')));
  }

  void _demoLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        setState(() => _isLoading = false);
        await Future.microtask(() {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const HomeScreen(
                          userName: 'demo.user@example.com',
                          department: 'Computer Science and Engineering',
                          semester: 5,
                        ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  var begin = const Offset(1.0, 0.0);
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
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // backgroundColor will be set by the global theme
      // extendBodyBehindAppBar: true, // Can be removed if AppBar has solid color
      appBar: AppBar(
        // backgroundColor: Colors.transparent, // Will use theme's AppBarTheme
        elevation: 0, // Keep it flat or use theme's default
        title: Text(
          _isLogin ? 'Login' : 'Sign Up',
          // style will be picked from appBarTheme.titleTextStyle
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color:
                                theme
                                    .colorScheme
                                    .surface, // Use theme surface color
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school_rounded,
                                size: 48,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _isLogin
                            ? 'Sign in to continue'
                            : 'Sign up to get started',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: 40),
                      TextField(
                        controller: _emailController,
                        cursorColor: theme.colorScheme.primary,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),
                      // Registration Number field - only shown during signup
                      if (!_isLogin) ...[  
                        TextField(
                          controller: _registrationController,
                          cursorColor: theme.colorScheme.primary,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Registration Number',
                            hintText: 'e.g., 921322205001',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            errorText: _registrationError,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      TextField(
                        controller: _passwordController,
                        // style: TextStyle(color: theme.colorScheme.onSurface), // Will use InputDecorationTheme
                        cursorColor: theme.colorScheme.primary,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          suffixIcon: IconButton(
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      SizedBox(height: 12),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Forgot password dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final TextEditingController
                                  resetEmailController =
                                      TextEditingController();
                                  return AlertDialog(
                                    // backgroundColor will use theme.dialogBackgroundColor
                                    title: Text(
                                      'Reset Password',
                                    ), // Style from theme
                                    content: TextField(
                                      controller: resetEmailController,
                                      // style: TextStyle(color: theme.colorScheme.onSurface),
                                      cursorColor: theme.colorScheme.primary,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your email',
                                        // hintStyle will use theme
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color:
                                                theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Password reset email sent!',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Send Email',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
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
                                : Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: theme.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: _toggleAuthMode,
                            child: Text(
                              _isLogin ? 'Register' : 'Login',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    // Map icon to emoji
    String emoji = "";
    if (icon == Icons.login)
      emoji = "G";
    else if (icon == Icons.people)
      emoji = "f";
    else if (icon == Icons.phone_iphone)
      emoji = "A";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// BubblesPainter removed as background is now solid based on theme
