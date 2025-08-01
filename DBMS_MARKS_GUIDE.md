# Database Management System Marks Integration

This guide explains how to insert and view the Database Management System exam marks for all students in the Campus Sync app.

## Files Created

### 1. SQL Script: `insert_dbms_marks.sql`
- **Purpose**: Direct database insertion script for Supabase
- **Location**: Root directory of the project
- **Usage**: Run this in your Supabase SQL Editor

### 2. Flutter Screen: `lib/screens/dbms_marks_screen.dart`
- **Purpose**: Display DBMS marks with statistics and search functionality
- **Features**:
  - Class statistics (average, pass rate, etc.)
  - Search by student name or registration number
  - Color-coded grades and performance indicators
  - Absent students marked as "AB"

### 3. Data Insertion Utility: `lib/utils/dbms_data_inserter.dart`
- **Purpose**: Programmatically insert DBMS marks through Flutter app
- **Features**:
  - Complete student name and registration number mapping
  - Bulk insertion of marks data
  - Automatic handling of absent students (AB → null)
  - Progress tracking and error handling

### 4. Enhanced Marks Service: `lib/services/marks_service.dart`
- **Added Methods**:
  - `getDBMSMarks()`: Get all DBMS marks
  - `getMarksBySubject()`: Get marks for any subject
  - `getSubjectStatistics()`: Calculate comprehensive statistics

## Student Data Overview

- **Total Students**: 61
- **Registration Numbers**: 210823104001 to 210823104063 (missing 045 and 056)
- **Subject**: Database Management System
- **Marks Range**: 0-100 (with some students absent)
- **Absent Students**: Marked as "AB" in original data, stored as NULL in database

## How to Use

### Option 1: Direct Database Insertion (Recommended)

1. Open your Supabase project dashboard
2. Go to SQL Editor
3. Copy and paste the content from `insert_dbms_marks.sql`
4. Run the script
5. Verify the insertion with the provided query at the end

### Option 2: Flutter App Insertion

1. Add the DBMS Data Insertion screen to your app navigation
2. Use the `DBMSDataInserter` class:

```dart
import 'utils/dbms_data_inserter.dart';

// In your widget
final inserter = DBMSDataInserter();
final success = await inserter.insertDBMSData();

if (success) {
  await inserter.printSummary();
}
```

### Option 3: Viewing the Results

Add the DBMS Marks screen to your navigation:

```dart
import 'screens/dbms_marks_screen.dart';

// Navigate to the screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DBMSMarksScreen(),
  ),
);
```

## Data Structure

### Student Marks Mapping
```
Registration No → Student Name → Mark
210823104001 → AATHI BALA KUMAR B → 54
210823104002 → ABEL C JOY → 66
...
210823104010 → ANNESHARON A S → AB (NULL)
```

### Database Schema
```sql
marks table:
- id (UUID, Primary Key)
- registration_no (TEXT, Foreign Key to students)
- exam_id (UUID, Foreign Key to exams)
- subject (TEXT) = 'Database Management System'
- mark (INTEGER, NULL for absent)
- out_of (INTEGER) = 100
- created_at, updated_at (TIMESTAMP)
```

## Features in DBMS Marks Screen

### Statistics Panel
- Total number of students
- Average mark calculation
- Pass rate percentage (≥40 marks)
- Number of absent students

### Grade System
- **A+**: 90-100 (Green)
- **A**: 80-89 (Green)
- **B+**: 70-79 (Blue)
- **B**: 60-69 (Blue)
- **C+**: 50-59 (Orange)
- **C**: 40-49 (Orange)
- **F**: 0-39 (Red)
- **AB**: Absent (Grey)

### Search & Filter
- Search by student name
- Search by registration number
- Real-time filtering of results

## Error Handling

The system handles:
- Duplicate insertion prevention
- Missing student records
- Database connection errors
- Invalid mark values
- Null/absent mark handling

## Statistics Available

- Total students: 61
- Students with marks: 55
- Absent students: 6
- Average mark: Calculated dynamically
- Highest/lowest marks
- Pass/fail counts and percentages

## Integration with Existing System

This integrates seamlessly with your existing:
- Student management system
- Attendance tracking
- Marks and examination module
- Role-based access control

## Verification Queries

After insertion, verify with:

```sql
-- Check total records
SELECT COUNT(*) FROM marks 
WHERE subject = 'Database Management System';

-- View all marks
SELECT m.registration_no, s.name, 
       COALESCE(m.mark::text, 'AB') as mark
FROM marks m
JOIN students s ON m.registration_no = s.registration_no
WHERE m.subject = 'Database Management System'
ORDER BY m.registration_no;

-- Get statistics
SELECT 
  COUNT(*) as total,
  COUNT(mark) as with_marks,
  AVG(mark) as average,
  MIN(mark) as minimum,
  MAX(mark) as maximum
FROM marks 
WHERE subject = 'Database Management System';
```

This implementation provides a complete solution for managing and viewing Database Management System exam marks in your Campus Sync application.
