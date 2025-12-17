-- Check all semester data in overall_attendance_summary
SELECT semester, COUNT(*) as student_count, department
FROM overall_attendance_summary 
WHERE department ILIKE '%computer science%engineering%'
GROUP BY semester, department
ORDER BY semester;

-- Check what actual data exists for semester 3
SELECT registration_no, department, semester, section, total_periods, attended_periods, overall_percentage
FROM overall_attendance_summary 
WHERE semester = 3 AND department ILIKE '%computer science%'
LIMIT 10;

-- Check students table for semester distribution
SELECT semester, COUNT(*) as student_count, department
FROM students 
WHERE department ILIKE '%computer science%'
GROUP BY semester, department
ORDER BY semester;
