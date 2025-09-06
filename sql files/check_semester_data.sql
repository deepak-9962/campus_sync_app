-- Check what semester data exists in the database
SELECT DISTINCT semester, department, COUNT(*) as student_count
FROM overall_attendance_summary 
WHERE department ILIKE '%computer science%' 
GROUP BY semester, department
ORDER BY semester;

-- Check if we have any semester 3 students
SELECT * FROM overall_attendance_summary 
WHERE semester = 3 AND department ILIKE '%computer science%'
LIMIT 5;

-- Check what departments we have in the students table
SELECT DISTINCT department, semester, COUNT(*) as count
FROM students 
GROUP BY department, semester
ORDER BY department, semester;
