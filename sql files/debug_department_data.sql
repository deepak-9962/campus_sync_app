-- Check the department names in all relevant tables to understand the mismatch

-- Check HOD user's department
SELECT 'HOD User' as source, department, count(*) as count 
FROM users 
WHERE role = 'hod' 
GROUP BY department;

-- Check departments in students table
SELECT 'Students' as source, department, count(*) as count 
FROM students 
GROUP BY department 
ORDER BY count DESC;

-- Check departments in overall_attendance_summary
SELECT 'Overall Summary' as source, department, count(*) as count 
FROM overall_attendance_summary 
GROUP BY department 
ORDER BY count DESC;

-- Check departments in daily_attendance
SELECT 'Daily Attendance' as source, department, count(*) as count 
FROM daily_attendance 
GROUP BY department 
ORDER BY count DESC;

-- Check if there's any data for today in daily_attendance
SELECT 'Today Daily Attendance' as source, date, department, 
       sum(present_count) as total_present, 
       sum(absent_count) as total_absent
FROM daily_attendance 
WHERE date = CURRENT_DATE
GROUP BY date, department;

-- Check recent dates in daily_attendance
SELECT DISTINCT date, department, 
       sum(present_count) as total_present, 
       sum(absent_count) as total_absent
FROM daily_attendance 
GROUP BY date, department 
ORDER BY date DESC 
LIMIT 10;
