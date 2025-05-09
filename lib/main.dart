// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Sync App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: 'Clash Grotesk'),
        useMaterial3: true,
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
      },
    );
  }
}
