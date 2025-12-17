import 'package:supabase_flutter/supabase_flutter.dart';

class TimetableService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get complete timetable for a department, semester, and section
  Future<Map<String, List<Map<String, dynamic>>>> getTimetable({
    required String department,
    required int semester,
    String section = 'A',
  }) async {
    try {
      print(
        'Fetching timetable for: $department, Semester: $semester, Section: $section',
      );

      final response = await _supabase
          .from('class_schedule')
          .select('''
            id,
            day_of_week,
            period_number,
            start_time,
            end_time,
            subject_code,
            subjects(subject_name),
            room,
            faculty_name,
            batch
          ''')
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', section)
          .order('day_of_week')
          .order('period_number');

      print('Database response: $response');

      // Group by day of week
      Map<String, List<Map<String, dynamic>>> timetableByDay = {};

      for (var item in response) {
        String dayOfWeek = item['day_of_week'];
        if (timetableByDay[dayOfWeek] == null) {
          timetableByDay[dayOfWeek] = [];
        }
        timetableByDay[dayOfWeek]!.add(item);
      }

      return timetableByDay;
    } catch (e) {
      print('Error fetching timetable: $e');
      return {};
    }
  }

  // Get subjects for a specific department and semester
  Future<List<Map<String, dynamic>>> getSubjects({
    required String department,
    required int semester,
  }) async {
    try {
      final response = await _supabase
          .from('subjects')
          .select('*')
          .eq('department', department)
          .eq('semester', semester);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  // Get today's schedule
  Future<List<Map<String, dynamic>>> getTodaysSchedule({
    required String department,
    required int semester,
    String section = 'A',
  }) async {
    try {
      final now = DateTime.now();
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final today = dayNames[now.weekday - 1];

      final response = await _supabase
          .from('class_schedule')
          .select('''
            period_number,
            start_time,
            end_time,
            subject_code,
            subjects(subject_name),
            room,
            faculty_name,
            batch
          ''')
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', section)
          .eq('day_of_week', today)
          .order('period_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching today\'s schedule: $e');
      return [];
    }
  }

  // Helper method to format time
  String formatTime(String time) {
    try {
      // Handle time formats like "13:30:00" or "13:30"
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0'); // Ensure 2 digits

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      print('Error formatting time: $time, error: $e');
      return time; // Return original if parsing fails
    }
  }

  // Helper method to get time range string
  String getTimeRange(String startTime, String endTime) {
    print('Formatting time range: $startTime - $endTime');
    final formattedStart = formatTime(startTime);
    final formattedEnd = formatTime(endTime);
    final result = '$formattedStart - $formattedEnd';
    print('Formatted result: $result');
    return result;
  }
}
