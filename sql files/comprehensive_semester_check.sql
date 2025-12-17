-- First, let's see exactly what department names exist in students table
SELECT DISTINCT department, COUNT(*) as total_students 
FROM students 
GROUP BY department 
ORDER BY department;

-- Then check which semesters have students for each department
SELECT department, semester, COUNT(*) as student_count
FROM students 
WHERE department ILIKE '%computer%science%'
GROUP BY department, semester
ORDER BY department, semester;

-- Check if semester 3 students exist in the overall_attendance_summary table
SELECT 'Overall Summary Table:' as table_name, semester, COUNT(*) as count
FROM overall_attendance_summary 
WHERE department ILIKE '%computer%science%'
GROUP BY semester
UNION ALL
SELECT 'Students Table:' as table_name, semester, COUNT(*) as count
FROM students 
WHERE department ILIKE '%computer%science%'
GROUP BY semester
ORDER BY table_name, semester;

-- Check if there's any attendance data for semester 3 students
SELECT s.semester, COUNT(DISTINCT s.registration_no) as students_with_data
FROM students s
JOIN overall_attendance_summary oas ON s.registration_no = oas.registration_no
WHERE s.department ILIKE '%computer%science%'
GROUP BY s.semester
ORDER BY s.semester;
