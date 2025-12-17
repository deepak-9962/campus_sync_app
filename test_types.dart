// Test file to verify type definitions work correctly
import 'lib/types/types.dart';

void main() {
  // Test Student type creation and JSON serialization
  final student = Student(
    registrationNo: 'TEST001',
    studentName: 'Test Student',
    department: 'Computer Science',
    semester: 3,
    currentSemester: 3,
    section: 'A',
    batch: '2021-25',
    userId: 'user-123',
    createdAt: DateTime.now(),
  );

  print('Student created: ${student.studentName}');

  // Test JSON serialization
  final studentJson = student.toJson();
  print('Student JSON: $studentJson');

  // Test JSON deserialization
  final studentFromJson = Student.fromJson(studentJson);
  print('Student from JSON: ${studentFromJson.studentName}');

  // Test AttendanceStatus enum
  final status = AttendanceStatusExtension.fromPercentage(85.0);
  print('Attendance status for 85%: ${status.displayName}');

  // Test AttendanceResponse
  final response = AttendanceResponse(
    registrationNo: 'TEST001',
    studentName: 'Test Student',
    department: 'Computer Science',
    semester: 3,
    section: 'A',
    percentage: 85.0,
    totalClasses: 100,
    attendedClasses: 85,
    status: 'Good',
    isPresent: true,
    todayPercentage: 100.0,
  );

  print(
    'Attendance response: ${response.studentName} - ${response.percentage}%',
  );

  // Test constants
  print('Students table: ${DatabaseTables.students}');
  print('Analytics view: ${DatabaseViews.attendanceAnalytics}');

  print('✅ All type definitions working correctly!');
}
