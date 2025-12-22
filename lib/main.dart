// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
// import 'package:firebase_core/firebase_core.dart'; // Remove Firebase import
// import 'services/notification_service.dart'; // Remove this line
import 'screens/profile_settings_screen.dart'; // Import the ProfileScreen
import 'screens/home_screen.dart'; // Import the HomeScreen
import 'screens/auth_screen.dart'; // Import the AuthScreen
import 'screens/sem_screen.dart'; // Import the SemScreen
import 'screens/timetable_screen.dart';
import 'screens/resource_hub_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/library_screen.dart';
import 'screens/exams_screen.dart';
import 'screens/attendance_screen.dart'; // Add this import for Attendance
import 'screens/daily_attendance_screen.dart';
import 'screens/role_test_screen.dart';
import 'screens/semester_selection_screen.dart'; // Import new screen
import 'screens/department_selection_screen.dart'; // Import new screen
import 'screens/selection_screen.dart'; // Centralized Dept/Sem selection
import 'services/theme_service.dart'; // Theme service for dark mode

const String kBuildVersion = '1.0.0'; // bump when deploying new web build

// Global theme service instance
final ThemeService themeService = ThemeService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  await themeService.initialize();

  // Initialize Firebase only for mobile platforms
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  } else {
    debugPrint('Skipping Firebase initialization for web platform');
  }

  // Remove Firebase initialization as it's causing errors
  // try {
  //   await Firebase.initializeApp();
  //   debugPrint('Firebase initialized successfully');
  //
  //   // Initialize notification service
  //   // await NotificationService().initialize(); // Remove this line
  //   // debugPrint('Notification service initialized successfully'); // Remove this line
  // } catch (e) {
  //   debugPrint('Firebase initialization error: $e');
  // }

  // Supabase config via --dart-define for web builds, fallback to hardcoded (avoid committing secrets)
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hgzhfqvjsyszwtdeaifx.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnemhmcXZqc3lzend0ZGVhaWZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2MzYyMzcsImV4cCI6MjA1NzIxMjIzN30.wdt6RGZFO4uz5P39UEHmfQtOW1OR7q4utyUGJ8qvxhk',
  );
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const MyApp());
}

/// Call this after user login/registration, passing the Supabase user id.
Future<void> setupPushNotifications(String userId) async {
  if (!kIsWeb) {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      String? token = await messaging.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Push notification setup error: $e');
    }
  }
}

void setupNotificationListeners() {
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          // You can show a dialog/snackbar/local notification here
          debugPrint('Notification Title: ${message.notification!.title}');
          debugPrint('Notification Body: ${message.notification!.body}');
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle notification tap when app is in background
      });
    } catch (e) {
      debugPrint('Notification listeners setup error: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    setupNotificationListeners();
    return MaterialApp(
      title: 'Campus Sync App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.flutterThemeMode,
      // Start with the AuthScreen
      home: const AuthScreen(),
      // Define routes for navigation
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/sem': (context) => const SemScreen(userName: ''),
        '/selection': (context) => const SelectionScreen(),
        '/home':
            (context) => const HomeScreen(
              userName: '',
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/profile': (context) => const ProfileSettingsScreen(),
        '/timetable':
            (context) => const TimetableScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/resources':
            (context) => const ResourceHubScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/announcements': (context) => const AnnouncementsScreen(),
        '/library': (context) => const LibraryScreen(),
        '/attendance':
            (context) => const AttendanceScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/exams':
            (context) => const ExamsScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/role_test': (context) => const RoleTestScreen(),
        '/semester_selection':
            (context) => const SemesterSelectionScreen(), // New route
        '/department_selection':
            (context) => const DepartmentSelectionScreen(), // New route
        // '/daily_attendance': (context) => const DailyAttendanceScreen(),
      },
    );
  }
}
