-- First, let's just check what's in the summary table without truncating
SELECT 'Current summary table data:' as info;
SELECT semester, department, COUNT(*) as student_count, AVG(overall_percentage) as avg_attendance
FROM overall_attendance_summary 
GROUP BY semester, department
ORDER BY department, semester;

-- Check if semester 3 students exist in students table
SELECT 'Students table semester 3:' as info;
SELECT COUNT(*) as semester_3_students, department
FROM students 
WHERE semester = 3
GROUP BY department;

-- Check if there's any attendance taken for semester 3 students
SELECT 'Attendance records for semester 3:' as info;
SELECT s.department, COUNT(DISTINCT a.registration_no) as students_with_attendance
FROM students s
JOIN attendance a ON s.registration_no = a.registration_no
WHERE s.semester = 3
GROUP BY s.department;
