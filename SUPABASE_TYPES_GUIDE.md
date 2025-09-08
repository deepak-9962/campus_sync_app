# Supabase Type Definitions for Campus Sync App

This document explains how to use the manually created type definitions in `lib/types/supabase_types.dart` for better AI code assistance and type safety.

## Overview

Since the automatic Supabase type generator (`supabase_gen`) had connection issues, we've manually created comprehensive type definitions based on the database schema. These types provide:

- **Complete database schema awareness** for AI assistance
- **Type safety** for all database operations
- **IntelliSense support** in your IDE
- **Documentation** of all table structures and relationships

## Available Types

### Core Database Tables

1. **`Student`** - Students table structure
   - `registrationNo` (String) - Primary key
   - `studentName`, `department`, `semester`, `section`, etc.
   - Includes `fromJson()` and `toJson()` methods

2. **`Subject`** - Subjects table structure
   - `subjectCode` (String) - Primary key
   - `subjectName`, `department`, `semester`, `facultyName`, etc.

3. **`Attendance`** - Period-wise attendance records
   - `registrationNo`, `subjectCode`, `date`, `periodNumber`
   - `isPresent` (bool) - Attendance status

4. **`DailyAttendance`** - Daily attendance summary
   - `registrationNo`, `date`, `isPresent`
   - Used for the daily attendance synchronization feature

5. **`AttendanceSummary`** - Subject-wise attendance summaries
   - Automatically calculated by database triggers
   - `totalPeriods`, `attendedPeriods`, `attendancePercentage`

6. **`OverallAttendanceSummary`** - Overall student attendance
   - Department and semester-wise summaries
   - Used for dashboard analytics

### View Types

1. **`AttendanceAnalytics`** - Main analytics view
   - Student details with attendance statistics
   - Includes `attendanceStatus` categorization

2. **`SubjectAttendanceReport`** - Subject-wise reports
   - Detailed subject performance data

### Response Types

1. **`AttendanceResponse`** - Standard API response format
   - Used throughout the app for consistent data structure
   - Includes all necessary student and attendance information

2. **`DepartmentSummaryResponse`** - HOD dashboard data
   - Department-wide statistics and student lists

### Utility Types

1. **`AttendanceFilter`** - Type-safe filtering options
   - `department`, `semester`, `section`, date ranges, etc.

2. **`PaginationOptions`** - Pagination parameters
   - `page`, `limit`, `orderBy`, `ascending`

### Enums

1. **`AttendanceStatus`** - Attendance categorization
   - `excellent`, `good`, `average`, `belowAverage`, `poor`
   - Includes `fromPercentage()` helper method

2. **`UserRole`** - User role types
   - `student`, `staff`, `hod`, `admin`

### Constants

1. **`DatabaseTables`** - Table name constants
2. **`DatabaseViews`** - View name constants
3. **`QueryPatterns`** - Common SQL patterns

## Usage Examples

### 1. Type-Safe Database Queries

```dart
// Instead of using raw Map<String, dynamic>
Future<List<Map<String, dynamic>>> getStudents() async {
  // Raw approach (no type safety)
  final response = await supabase.from('students').select();
  return response as List<Map<String, dynamic>>;
}

// Better: Use type definitions for clarity
Future<List<Student>> getStudentsTyped() async {
  final response = await supabase
      .from(DatabaseTables.students)
      .select();
  
  return response
      .map((json) => Student.fromJson(json))
      .toList();
}
```

### 2. Using Filters

```dart
// Type-safe filtering
final filter = AttendanceFilter(
  department: 'Computer Science',
  semester: 3,
  minPercentage: 75.0,
);

// Apply filters to your queries
var query = supabase.from(DatabaseTables.overallAttendanceSummary).select();
if (filter.department != null) {
  query = query.eq('department', filter.department!);
}
if (filter.semester != null) {
  query = query.eq('semester', filter.semester!);
}
```

### 3. Handling Attendance Status

```dart
// Type-safe status handling
double percentage = 82.5;
AttendanceStatus status = AttendanceStatusExtension.fromPercentage(percentage);
print('Status: ${status.displayName}'); // Output: "Good"

// Use in your UI logic
Color getStatusColor(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.excellent:
      return Colors.green;
    case AttendanceStatus.good:
      return Colors.blue;
    case AttendanceStatus.average:
      return Colors.orange;
    case AttendanceStatus.belowAverage:
      return Colors.red.shade300;
    case AttendanceStatus.poor:
      return Colors.red;
  }
}
```

### 4. Working with Responses

```dart
// Convert raw database response to typed response
List<Map<String, dynamic>> rawAttendance = await getAttendanceData();

List<AttendanceResponse> typedResponses = rawAttendance
    .map((data) => AttendanceResponse.fromJson(data))
    .toList();

// Now you have full type safety and IntelliSense
for (AttendanceResponse response in typedResponses) {
  print('${response.studentName}: ${response.percentage}%');
  if (response.isPresent == true) {
    print('Present today with ${response.todayPercentage}%');
  }
}
```

## Benefits for AI Assistance

With these type definitions imported in your service files, AI assistants can:

1. **Understand Database Schema**: AI knows all table structures, relationships, and field types
2. **Suggest Accurate Code**: Better code completion and suggestions
3. **Detect Type Errors**: Catch type mismatches before runtime
4. **Generate Consistent Code**: Follow established patterns and naming conventions
5. **Understand Business Logic**: AI can better assist with attendance-specific logic

## Integration with Existing Code

The types are designed to be compatible with your existing `AttendanceService` class. You can gradually migrate from `Map<String, dynamic>` to typed objects:

1. **Import the types**: Already done in `attendance_service.dart`
2. **Use constants**: Replace hardcoded table names with `DatabaseTables.*`
3. **Add type annotations**: Gradually convert methods to return typed objects
4. **Leverage enums**: Use `AttendanceStatus` and `UserRole` for better type safety

## Example Migration

```dart
// Before (current code)
Future<List<Map<String, dynamic>>> getAllStudentsAttendance({
  String? department,
  int? semester,
}) async {
  var query = _supabase.from('overall_attendance_summary').select();
  // ... existing implementation
}

// After (with types)
Future<List<AttendanceResponse>> getAllStudentsAttendanceTyped({
  String? department,
  int? semester,
}) async {
  var query = _supabase
      .from(DatabaseTables.overallAttendanceSummary)
      .select();
  
  final response = await query;
  return response
      .map((data) => AttendanceResponse.fromJson(data))
      .toList();
}
```

## Notes

- The `// ignore: unused_import` comment prevents lint warnings until types are actively used
- Types include comprehensive JSON serialization methods
- All nullable fields are properly marked with `?`
- DateTime fields are automatically parsed from ISO strings
- Enums include helper methods for common operations

This type system provides a solid foundation for maintaining and extending the Campus Sync app with better code quality and AI assistance.
