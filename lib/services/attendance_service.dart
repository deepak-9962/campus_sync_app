import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;

  // Complete data from the attendance table
  final List<Map<String, dynamic>> _attendanceData = [
    // Sample data for testing role-based attendance
    {
      'serial_no': 1,
      'registration_no': '210823104001',
      'student_name': 'AATHI BALA KUMAR B (H)',
      'total_working_days': 37,
      'days_absent': 0,
      'days_present': 37,
      'attendance_percentage': 100.00,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'A',
    },
    {
      'serial_no': 2,
      'registration_no': '210823104002',
      'student_name': 'ABEL C JOY',
      'total_working_days': 37,
      'days_absent': 2,
      'days_present': 35,
      'attendance_percentage': 94.59,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'A',
    },
    {
      'serial_no': 3,
      'registration_no': '210823104003',
      'student_name': 'ABINAYA T',
      'total_working_days': 37,
      'days_absent': 2,
      'days_present': 35,
      'attendance_percentage': 94.59,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'A',
    },
    {
      'serial_no': 4,
      'registration_no': '210823104004',
      'student_name': 'ABISHA JEBAMANI K',
      'total_working_days': 37,
      'days_absent': 1,
      'days_present': 36,
      'attendance_percentage': 97.30,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'A',
    },
    {
      'serial_no': 5,
      'registration_no': '210823104005',
      'student_name': 'ABISHEK PAULSON S',
      'total_working_days': 37,
      'days_absent': 6,
      'days_present': 31,
      'attendance_percentage': 83.78,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'A',
    },
    {
      'serial_no': 6,
      'registration_no': '210823104031',
      'student_name': 'DHEEKSHA B',
      'total_working_days': 37,
      'days_absent': 3,
      'days_present': 34,
      'attendance_percentage': 91.89,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'B',
    },
    {
      'serial_no': 7,
      'registration_no': '210823104032',
      'student_name': 'DHIVIYESH J (H)',
      'total_working_days': 37,
      'days_absent': 2,
      'days_present': 35,
      'attendance_percentage': 94.59,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'B',
    },
    {
      'serial_no': 8,
      'registration_no': '210823104033',
      'student_name': 'DON SINTO SAJI',
      'total_working_days': 37,
      'days_absent': 0,
      'days_present': 37,
      'attendance_percentage': 100.00,
      'department': 'Computer Science Engineering',
      'semester': 4,
      'section': 'B',
    },
  ];

  Future<Map<String, dynamic>?> getAttendanceByRegistrationNo(
    String registrationNo,
  ) async {
    try {
      // Clean up input - remove whitespace and # symbol if present
      final cleanedRegNo = registrationNo.trim().replaceAll('#', '');

      print('Searching for registration number: $cleanedRegNo');

      // Direct query with exact match from local data
      final exactMatch =
          _attendanceData
              .where((record) => record['registration_no'] == cleanedRegNo)
              .toList();

      if (exactMatch.isNotEmpty) {
        print('Found exact match for registration number: $cleanedRegNo');
        return exactMatch[0];
      }

      // No exact match found - try checking if this contains a valid registration number or name
      print('No exact match found. Trying alternative search...');

      // Try partial registration number match
      for (var record in _attendanceData) {
        if (record['registration_no'].toString().contains(cleanedRegNo) ||
            cleanedRegNo.contains(record['registration_no'].toString())) {
          print(
            'Found partial registration match: ${record['registration_no']}',
          );
          return record;
        }
      }

      // Then try name match (case insensitive)
      final lowerCaseInput = cleanedRegNo.toLowerCase();
      for (var record in _attendanceData) {
        final studentName = record['student_name'].toString().toLowerCase();
        if (studentName.contains(lowerCaseInput) ||
            lowerCaseInput.contains(studentName)) {
          print('Found student name match: ${record['student_name']}');
          return record;
        }
      }

      print('No record found with registration number: $cleanedRegNo');
      return null;
    } catch (error) {
      print('Error fetching attendance: $error');
      return null;
    }
  }

  // Get a list of all registration numbers for reference
  Future<List<Map<String, dynamic>>> getAllRegistrationNumbers() async {
    try {
      // Return registration numbers, names, department, semester, and section from local data
      return _attendanceData
          .map(
            (record) => {
              'registration_no': record['registration_no'],
              'student_name': record['student_name'],
              'department': record['department'],
              'semester': record['semester'],
              'section': record['section'],
            },
          )
          .toList();
    } catch (error) {
      print('Error fetching registration numbers: $error');
      return [];
    }
  }
}
