// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/profile_settings_screen.dart'; // Import the ProfileScreen
import 'screens/home_screen.dart'; // Import the HomeScreen
import 'screens/auth_screen.dart'; // Import the AuthScreen
import 'screens/sem_screen.dart'; // Import the SemScreen
import 'screens/timetable_screen.dart';
import 'screens/resource_hub_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/library_screen.dart';
import 'screens/exams_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hgzhfqvjsyszwtdeaifx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnemhmcXZqc3lzend0ZGVhaWZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2MzYyMzcsImV4cCI6MjA1NzIxMjIzN30.wdt6RGZFO4uz5P39UEHmfQtOW1OR7q4utyUGJ8qvxhk',
  );

  // Initialize notifications
  await NotificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Sync App',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: 'Clash Grotesk'),
        useMaterial3: true,
      ),
      // Remove the home property and use initialRoute instead
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/sem': (context) => const SemScreen(userName: ''),
        '/home': (context) => const HomeScreen(
              userName: '',
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/profile': (context) => const ProfileSettingsScreen(),
        '/timetable': (context) => const TimetableScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/resources': (context) => const ResourceHubScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
        '/announcements': (context) => AnnouncementsScreen(),
        '/library': (context) => const LibraryScreen(),
        '/exams': (context) => const ExamsScreen(
              department: 'Computer Science Engineering',
              semester: 4,
            ),
      },
    );
  }
}
