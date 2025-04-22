import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    // Set up real-time subscription for announcements
    _supabase.from('announcements').stream(primaryKey: ['id']).listen((data) {
      // Handle new announcements
      if (data.isNotEmpty) {
        final announcement = data.first;
        _showLocalNotification(
          title: announcement['title'],
          body: announcement['content'],
          isEmergency: announcement['is_emergency'] ?? false,
        );
      }
    });
  }

  static void _showLocalNotification({
    required String title,
    required String body,
    required bool isEmergency,
  }) {
    // Show a snackbar for notifications
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(title),
          backgroundColor: isEmergency ? Colors.red : Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    bool isEmergency = false,
  }) async {
    // This is a placeholder for future implementation
    // You can implement this using Supabase Edge Functions or other services
    print('Notification sent: $title');
  }
}
