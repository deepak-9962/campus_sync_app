-- Check what data exists for semester 3
SELECT 'overall_attendance_summary' as table_name, department, semester, count(*) as count
FROM overall_attendance_summary 
WHERE semester = 3
GROUP BY department, semester

UNION ALL

SELECT 'daily_attendance' as table_name, department, semester, count(*) as count
FROM daily_attendance 
WHERE semester = 3 AND date = CURRENT_DATE
GROUP BY department, semester

UNION ALL

SELECT 'students' as table_name, department, current_semester as semester, count(*) as count
FROM students 
WHERE current_semester = 3
GROUP BY department, current_semester

ORDER BY table_name, department;
