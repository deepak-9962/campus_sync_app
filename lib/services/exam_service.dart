import 'package:supabase_flutter/supabase_flutter.dart';

class ExamService {
  final _supabase = Supabase.instance.client;

  /// Get all exams
  Future<List<Map<String, dynamic>>> getAllExams() async {
    try {
      final response = await _supabase
          .from('exams')
          .select('*')
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching exams: $error');
      return [];
    }
  }

  /// Get exams by department and semester
  Future<List<Map<String, dynamic>>> getExamsByDepartmentAndSemester({
    required String department,
    required int semester,
  }) async {
    try {
      final response = await _supabase
          .from('exams')
          .select('*')
          .ilike('department', department)
          .eq('semester', semester)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error fetching exams: $error');
      return [];
    }
  }

  /// Create new exam
  Future<Map<String, dynamic>?> createExam({
    required String name,
    required String department,
    required int semester,
    DateTime? date,
  }) async {
    try {
      final response =
          await _supabase
              .from('exams')
              .insert({
                'name': name,
                'department': department,
                'semester': semester,
                'date':
                    date?.toIso8601String().split(
                      'T',
                    )[0], // Format as YYYY-MM-DD
              })
              .select('id, name, department, semester, date, created_at')
              .single();

      return response;
    } catch (error) {
      print('Error creating exam: $error');
      return null;
    }
  }

  /// Update exam
  Future<bool> updateExam({
    required String examId,
    required String name,
    DateTime? date,
  }) async {
    try {
      await _supabase
          .from('exams')
          .update({
            'name': name,
            'date': date?.toIso8601String().split('T')[0],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', examId);

      return true;
    } catch (error) {
      print('Error updating exam: $error');
      return false;
    }
  }

  /// Delete exam
  Future<bool> deleteExam(String examId) async {
    try {
      await _supabase.from('exams').delete().eq('id', examId);

      return true;
    } catch (error) {
      print('Error deleting exam: $error');
      return false;
    }
  }
}
