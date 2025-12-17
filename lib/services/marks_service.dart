import 'package:supabase_flutter/supabase_flutter.dart';

class MarksService {
  final _supabase = Supabase.instance.client;

  /// Get marks for a specific student
  Future<List<Map<String, dynamic>>> getStudentMarks(
    String registrationNo,
  ) async {
    try {
      final response = await _supabase
          .from('marks')
          .select('*')
          .eq('registration_no', registrationNo)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching student marks: $error');
      return [];
    }
  }

  /// Get marks for an exam
  Future<List<Map<String, dynamic>>> getExamMarks(String examId) async {
    try {
      final response = await _supabase
          .from('marks')
          .select('''
            *,
            students!marks_registration_no_fkey(registration_no, department, current_semester, section)
          ''')
          .eq('exam_id', examId)
          .order('registration_no', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching exam marks: $error');
      return [];
    }
  }

  /// Get marks for exam by subject
  Future<List<Map<String, dynamic>>> getExamMarksBySubject({
    required String examId,
    required String subject,
  }) async {
    try {
      final response = await _supabase
          .from('marks')
          .select('''
            *,
            students!marks_registration_no_fkey(registration_no, department, current_semester, section)
          ''')
          .eq('exam_id', examId)
          .eq('subject', subject)
          .order('mark', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching marks by subject: $error');
      return [];
    }
  }

  /// Add or update mark
  Future<bool> addOrUpdateMark({
    required String registrationNo,
    required String examId,
    required String subject,
    required int mark,
    required int outOf,
  }) async {
    try {
      await _supabase.from('marks').upsert({
        'registration_no': registrationNo,
        'exam_id': examId,
        'subject': subject,
        'mark': mark,
        'out_of': outOf,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      print('Error adding/updating mark: $error');
      return false;
    }
  }

  /// Bulk insert marks for multiple students
  Future<bool> bulkInsertMarks(List<Map<String, dynamic>> marksList) async {
    try {
      await _supabase.from('marks').upsert(marksList);

      return true;
    } catch (error) {
      print('Error bulk inserting marks: $error');
      return false;
    }
  }

  /// Delete mark
  Future<bool> deleteMark(String markId) async {
    try {
      await _supabase.from('marks').delete().eq('id', markId);

      return true;
    } catch (error) {
      print('Error deleting mark: $error');
      return false;
    }
  }

  /// Get Database Management System marks for all students
  Future<List<Map<String, dynamic>>> getDBMSMarks() async {
    try {
      final response = await _supabase
          .from('marks')
          .select('*')
          .eq('subject', 'Database Management System')
          .order('registration_no', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching DBMS marks: $error');
      return [];
    }
  }

  /// Get marks for a specific subject
  Future<List<Map<String, dynamic>>> getMarksBySubject(String subject) async {
    try {
      final response = await _supabase
          .from('marks')
          .select('*')
          .eq('subject', subject)
          .order('registration_no', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching marks for subject $subject: $error');
      return [];
    }
  }

  /// Get marks statistics for a subject
  Future<Map<String, dynamic>> getSubjectStatistics(String subject) async {
    try {
      final marks = await getMarksBySubject(subject);

      if (marks.isEmpty) {
        return {
          'totalStudents': 0,
          'studentsWithMarks': 0,
          'absentStudents': 0,
          'averageMark': 0.0,
          'highestMark': 0,
          'lowestMark': 0,
          'passCount': 0,
          'failCount': 0,
        };
      }

      int totalStudents = marks.length;
      int studentsWithMarks = 0;
      int absentStudents = 0;
      int passCount = 0;
      int failCount = 0;
      double totalMarks = 0;
      int highestMark = 0;
      int lowestMark = 100;

      for (var markData in marks) {
        final mark = markData['mark'];
        if (mark != null && mark != -1) {
          studentsWithMarks++;
          totalMarks += mark;

          if (mark >= 50)
            passCount++;
          else
            failCount++;

          if (mark > highestMark) highestMark = mark;
          if (mark < lowestMark) lowestMark = mark;
        } else {
          absentStudents++;
        }
      }

      double averageMark =
          studentsWithMarks > 0 ? totalMarks / studentsWithMarks : 0.0;

      return {
        'subject': subject,
        'totalStudents': totalStudents,
        'studentsWithMarks': studentsWithMarks,
        'absentStudents': absentStudents,
        'averageMark': averageMark,
        'highestMark': highestMark,
        'lowestMark': studentsWithMarks > 0 ? lowestMark : 0,
        'passCount': passCount,
        'failCount': failCount,
        'passPercentage':
            studentsWithMarks > 0 ? (passCount / studentsWithMarks) * 100 : 0.0,
      };
    } catch (error) {
      print('Error calculating statistics for subject $subject: $error');
      return {};
    }
  }

  /// Get student performance summary
  Future<Map<String, dynamic>> getStudentPerformanceSummary(
    String registrationNo,
  ) async {
    try {
      final marks = await getStudentMarks(registrationNo);

      if (marks.isEmpty) {
        return {
          'totalExams': 0,
          'averagePercentage': 0.0,
          'totalSubjects': 0,
          'highestMark': 0,
          'lowestMark': 0,
        };
      }

      double totalPercentage = 0;
      int highestMark = 0;
      int lowestMark = 100;
      Set<String> subjects = {};

      for (var mark in marks) {
        if (mark['mark'] != null) {
          double percentage = (mark['mark'] / mark['out_of']) * 100;
          totalPercentage += percentage;

          if (mark['mark'] > highestMark) highestMark = mark['mark'];
          if (mark['mark'] < lowestMark) lowestMark = mark['mark'];

          subjects.add(mark['subject']);
        }
      }

      return {
        'totalExams': marks.length,
        'averagePercentage':
            marks.isNotEmpty ? totalPercentage / marks.length : 0.0,
        'totalSubjects': subjects.length,
        'highestMark': highestMark,
        'lowestMark': lowestMark,
      };
    } catch (error) {
      print('Error calculating performance summary: $error');
      return {};
    }
  }
}
