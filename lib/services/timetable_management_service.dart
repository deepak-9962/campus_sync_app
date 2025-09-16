import 'package:supabase_flutter/supabase_flutter.dart';

class TimetableManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add or update a class period
  Future<bool> addOrUpdateClassPeriod({
    required String department,
    required int semester,
    required String section,
    required String dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required String subjectCode,
    String? room,
    String? facultyName,
    String? batch,
  }) async {
    try {
      print('DEBUG: Adding class period with data:');
      print('Department: $department');
      print('Semester: $semester');
      print('Section: $section');
      print('Day: $dayOfWeek');
      print('Period: $periodNumber');
      print('Subject: $subjectCode');
      print('Faculty: $facultyName');

      // First, get the subject_id from the subject_code
      String? subjectId;
      try {
        final subjectResponse =
            await _supabase
                .from('subjects')
                .select('id')
                .eq('subject_code', subjectCode)
                .eq('department', department)
                .eq('semester', semester)
                .maybeSingle();

        if (subjectResponse != null) {
          subjectId = subjectResponse['id'];
          print(
            'DEBUG: Found subject_id: $subjectId for subject_code: $subjectCode',
          );
        } else {
          print(
            'DEBUG: No subject found for subject_code: $subjectCode, department: $department, semester: $semester',
          );

          // Create the subject if it doesn't exist
          final newSubjectResponse =
              await _supabase
                  .from('subjects')
                  .insert({
                    'subject_code': subjectCode,
                    'subject_name':
                        subjectCode, // Use subject_code as default name
                    'department': department,
                    'semester': semester,
                    'credits': 3, // Default credits
                    'faculty_name': facultyName ?? 'Faculty',
                  })
                  .select('id')
                  .single();

          subjectId = newSubjectResponse['id'];
          print('DEBUG: Created new subject with id: $subjectId');
        }
      } catch (subjectError) {
        print('ERROR: Failed to get/create subject: $subjectError');
        return false;
      }

      if (subjectId == null) {
        print('ERROR: Could not get subject_id for subject_code: $subjectCode');
        return false;
      }

      // Check if record exists - handle case where multiple records might exist
      final existingRecords = await _supabase
          .from('class_schedule')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', section)
          .eq('day_of_week', dayOfWeek.toLowerCase())
          .eq('period_number', periodNumber);

      // If multiple records exist, we'll update the first one and delete the rest
      Map<String, dynamic>? existingRecord;
      if (existingRecords.isNotEmpty) {
        existingRecord = existingRecords.first;

        // If there are duplicates, delete them
        if (existingRecords.length > 1) {
          print(
            'DEBUG: Found ${existingRecords.length} duplicate records, cleaning up...',
          );
          for (int i = 1; i < existingRecords.length; i++) {
            await _supabase
                .from('class_schedule')
                .delete()
                .eq('id', existingRecords[i]['id']);
          }
          print(
            'DEBUG: Cleaned up ${existingRecords.length - 1} duplicate records',
          );
        }
      }

      final insertData = {
        'department': department,
        'semester': semester,
        'section': section,
        'day_of_week': dayOfWeek.toLowerCase(),
        'period_number': periodNumber,
        'start_time': startTime,
        'end_time': endTime,
        'subject_code': subjectCode,
        'subject_id': subjectId, // Add the required subject_id
        'room': room ?? '',
        'faculty_name': facultyName ?? '',
        'batch': batch ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      final updateData = {
        'department': department,
        'semester': semester,
        'section': section,
        'day_of_week': dayOfWeek.toLowerCase(),
        'period_number': periodNumber,
        'start_time': startTime,
        'end_time': endTime,
        'subject_code': subjectCode,
        'subject_id': subjectId, // Add the required subject_id
        'room': room ?? '',
        'faculty_name': facultyName ?? '',
        'batch': batch ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print(
        'DEBUG: Data to insert/update: ${existingRecord != null ? updateData : insertData}',
      );

      if (existingRecord != null) {
        // Update existing record
        print(
          'DEBUG: Updating existing record with ID: ${existingRecord['id']}',
        );
        await _supabase
            .from('class_schedule')
            .update(updateData)
            .eq('id', existingRecord['id']);
        print('DEBUG: Update successful');
      } else {
        // Insert new record
        print('DEBUG: Inserting new record');
        await _supabase.from('class_schedule').insert(insertData);
        print('DEBUG: Insert successful');
      }

      return true;
    } catch (e) {
      print('Error adding/updating class period: $e');
      return false;
    }
  }

  // Delete a class period
  Future<bool> deleteClassPeriod({
    required String department,
    required int semester,
    required String section,
    required String dayOfWeek,
    required int periodNumber,
  }) async {
    try {
      await _supabase
          .from('class_schedule')
          .delete()
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', section)
          .eq('day_of_week', dayOfWeek.toLowerCase())
          .eq('period_number', periodNumber);

      return true;
    } catch (e) {
      print('Error deleting class period: $e');
      return false;
    }
  }

  // Get all subjects for dropdown
  Future<List<Map<String, dynamic>>> getSubjectsForDepartmentSemester({
    required String department,
    required int semester,
  }) async {
    try {
      final response = await _supabase
          .from('subjects')
          .select('subject_code, subject_name, faculty_name')
          .eq('department', department)
          .eq('semester', semester)
          .order('subject_name');

      final subjects = List<Map<String, dynamic>>.from(response);

      // If no subjects found in database, provide default semester 5 CSE subjects
      if (subjects.isEmpty &&
          (department == 'Computer Science and Engineering' ||
              department == 'Computer Science') &&
          semester == 5) {
        return [
          {
            'subject_code': 'CB3491',
            'subject_name': 'cryptography and cyber security',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CCS335',
            'subject_name': 'cloud computing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CCS341',
            'subject_name': 'data Warehousing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3501',
            'subject_name': 'compiler design',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3551',
            'subject_name': 'distributed computing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3591',
            'subject_name': 'computer networks',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'LIB',
            'subject_name': 'Library',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'SBTJP',
            'subject_name': 'Java Programming',
            'faculty_name': 'Faculty',
          },
        ];
      }

      return subjects;
    } catch (e) {
      print('Error fetching subjects: $e');
      // Return default subjects as fallback for CSE semester 5
      if ((department == 'Computer Science and Engineering' ||
              department == 'Computer Science') &&
          semester == 5) {
        return [
          {
            'subject_code': 'CB3491',
            'subject_name': 'cryptography and cyber security',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CCS335',
            'subject_name': 'cloud computing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CCS341',
            'subject_name': 'data Warehousing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3501',
            'subject_name': 'compiler design',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3551',
            'subject_name': 'distributed computing',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'CS3591',
            'subject_name': 'computer networks',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'LIB',
            'subject_name': 'Library',
            'faculty_name': 'Faculty',
          },
          {
            'subject_code': 'SBTJP',
            'subject_name': 'Java Programming',
            'faculty_name': 'Faculty',
          },
        ];
      }
      return [];
    }
  }

  // Get faculty list
  Future<List<String>> getFacultyList() async {
    try {
      final response = await _supabase
          .from('class_schedule')
          .select('faculty_name')
          .not('faculty_name', 'eq', '')
          .not('faculty_name', 'is', null);

      final facultySet = <String>{};
      for (var record in response) {
        if (record['faculty_name'] != null &&
            record['faculty_name'].toString().trim().isNotEmpty) {
          facultySet.add(record['faculty_name']);
        }
      }

      final facultyList = facultySet.toList()..sort();
      return facultyList;
    } catch (e) {
      print('Error fetching faculty list: $e');
      return [];
    }
  }

  // Get room list
  Future<List<String>> getRoomList() async {
    try {
      final response = await _supabase
          .from('class_schedule')
          .select('room')
          .not('room', 'eq', '')
          .not('room', 'is', null);

      final roomSet = <String>{};
      for (var record in response) {
        if (record['room'] != null &&
            record['room'].toString().trim().isNotEmpty) {
          roomSet.add(record['room']);
        }
      }

      final roomList = roomSet.toList()..sort();
      return roomList;
    } catch (e) {
      print('Error fetching room list: $e');
      return [];
    }
  }

  // Validate time conflict
  Future<bool> hasTimeConflict({
    required String department,
    required int semester,
    required String section,
    required String dayOfWeek,
    required int periodNumber,
    String? room,
    String? facultyName,
    String? excludeRecordId, // Exclude current record when editing
  }) async {
    try {
      // Check for room conflict
      if (room != null && room.isNotEmpty) {
        var roomQuery = _supabase
            .from('class_schedule')
            .select()
            .eq('day_of_week', dayOfWeek.toLowerCase())
            .eq('period_number', periodNumber)
            .eq('room', room);

        // Exclude current record if editing
        if (excludeRecordId != null) {
          roomQuery = roomQuery.neq('id', excludeRecordId);
        }

        final roomConflicts = await roomQuery;
        if (roomConflicts.isNotEmpty) {
          return true; // Room is already booked
        }
      }

      // Check for faculty conflict
      if (facultyName != null && facultyName.isNotEmpty) {
        var facultyQuery = _supabase
            .from('class_schedule')
            .select()
            .eq('day_of_week', dayOfWeek.toLowerCase())
            .eq('period_number', periodNumber)
            .eq('faculty_name', facultyName);

        // Exclude current record if editing
        if (excludeRecordId != null) {
          facultyQuery = facultyQuery.neq('id', excludeRecordId);
        }

        final facultyConflicts = await facultyQuery;
        if (facultyConflicts.isNotEmpty) {
          return true; // Faculty is already assigned
        }
      }

      return false;
    } catch (e) {
      print('Error checking time conflict: $e');
      return false;
    }
  }

  // Copy timetable from one section to another
  Future<bool> copyTimetableToSection({
    required String department,
    required int semester,
    required String fromSection,
    required String toSection,
  }) async {
    try {
      // Get source timetable
      final sourceTimetable = await _supabase
          .from('class_schedule')
          .select()
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', fromSection);

      // Delete existing timetable for target section
      await _supabase
          .from('class_schedule')
          .delete()
          .eq('department', department)
          .eq('semester', semester)
          .eq('section', toSection);

      // Insert copied timetable
      for (var record in sourceTimetable) {
        final newRecord = Map<String, dynamic>.from(record);
        newRecord.remove('id'); // Remove ID to create new record
        newRecord['section'] = toSection;
        newRecord['created_at'] = DateTime.now().toIso8601String();

        await _supabase.from('class_schedule').insert(newRecord);
      }

      return true;
    } catch (e) {
      print('Error copying timetable: $e');
      return false;
    }
  }

  // Get timetable template with standard periods
  Map<String, List<Map<String, dynamic>>> getStandardTimetableTemplate() {
    return {
      'Monday': _getStandardPeriods(),
      'Tuesday': _getStandardPeriods(),
      'Wednesday': _getStandardPeriods(),
      'Thursday': _getStandardPeriods(),
      'Friday': _getStandardPeriods(),
      'Saturday': _getStandardPeriods(),
    };
  }

  List<Map<String, dynamic>> _getStandardPeriods() {
    return [
      {'period': 1, 'start_time': '08:45', 'end_time': '09:30'},
      {'period': 2, 'start_time': '09:30', 'end_time': '10:15'},
      {'period': 'Break', 'start_time': '10:15', 'end_time': '10:30'},
      {'period': 3, 'start_time': '10:30', 'end_time': '11:15'},
      {'period': 4, 'start_time': '11:15', 'end_time': '12:00'},
      {'period': 'Lunch', 'start_time': '12:00', 'end_time': '12:45'},
      {'period': 5, 'start_time': '12:45', 'end_time': '13:30'},
      {'period': 6, 'start_time': '13:30', 'end_time': '14:15'},
    ];
  }
}
