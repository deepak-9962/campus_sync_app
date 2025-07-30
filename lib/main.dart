// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://hgzhfqvjsyszwtdeaifx.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnemhmcXZqc3lzend0ZGVhaWZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2MzYyMzcsImV4cCI6MjA1NzIxMjIzN30.wdt6RGZFO4uz5P39UEHmfQtOW1OR7q4utyUGJ8qvxhk',
    );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    setupNotificationListeners();
    return MaterialApp(
      title: 'Campus Sync App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Clash Grotesk', // Apply default font family
        // Color Scheme
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1976D2), // Blue 700 (Accent)
          secondary: const Color(
            0xFF1976D2,
          ), // Can be same as primary or different
          surface: Colors.white, // Card and dialog backgrounds
          background: const Color(0xFFF5F5F5), // Main background
          error: Colors.red.shade700,
          onPrimary: Colors.white, // Text/icons on primary color
          onSecondary: Colors.white, // Text/icons on secondary color
          onSurface: const Color(0xFF212121), // Primary text on surface
          onBackground: const Color(0xFF212121), // Primary text on background
          onError: Colors.white,
        ),

        // Scaffold Background Color
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // AppBar background
          foregroundColor: const Color(0xFF212121), // Title and icons on AppBar
          elevation: 0.5,
          iconTheme: IconThemeData(color: const Color(0xFF424242)),
          titleTextStyle: TextStyle(
            fontFamily: 'Clash Grotesk',
            color: const Color(0xFF212121),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Card Theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1.0, // Subtle elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 0,
          ), // Default card margin
        ),

        // Text Theme
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          displayMedium: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          displaySmall: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          headlineMedium: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          headlineSmall: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          titleLarge: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: const Color(0xFF212121),
            fontFamily: 'Clash Grotesk',
          ),
          bodyMedium: TextStyle(
            color: const Color(0xFF757575),
            fontFamily: 'Clash Grotesk',
          ), // Secondary text
          labelLarge: TextStyle(
            color: Colors.white,
            fontFamily: 'Clash Grotesk',
            fontWeight: FontWeight.bold,
          ), // For buttons
        ),

        // ElevatedButton Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2), // Accent color
            foregroundColor: Colors.white, // Text on button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontFamily: 'Clash Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),

        // InputDecoration Theme (for TextFields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100], // Light fill for text fields
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Clash Grotesk',
          ),
          labelStyle: TextStyle(
            color: const Color(0xFF757575),
            fontFamily: 'Clash Grotesk',
          ), // Medium grey for labels
          border: OutlineInputBorder(
            // Default border for all states if others not specified
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            // Border when the input field is enabled and not focused
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: const Color(0xFF1976D2), // Accent color on focus
              width: 2.0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Icon Theme
        iconTheme: IconThemeData(
          color: const Color(0xFF424242), // Darker grey for general icons
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),

        // Dialog Theme
        dialogBackgroundColor: Colors.white,
      ),
      // Start with the AuthScreen
      home: const AuthScreen(),
      // Define routes for navigation
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/sem': (context) => const SemScreen(userName: ''),
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
        // '/daily_attendance': (context) => const DailyAttendanceScreen(),
      },
    );
  }
}
