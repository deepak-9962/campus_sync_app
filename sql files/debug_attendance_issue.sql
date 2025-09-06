-- Check the current state of attendance data after subjects migration

-- 1. Check if there's any attendance data for today
SELECT 'Today attendance records:' as info;
SELECT 
    DATE(a.date) as date,
    a.subject_code,
    a.subject_id,
    COUNT(*) as records,
    COUNT(CASE WHEN a.is_present THEN 1 END) as present_count,
    COUNT(CASE WHEN NOT a.is_present THEN 1 END) as absent_count
FROM attendance a
WHERE DATE(a.date) = CURRENT_DATE
GROUP BY DATE(a.date), a.subject_code, a.subject_id
ORDER BY a.subject_code;

-- 2. Check students and their departments/semesters
SELECT 'Students in computer science department:' as info;
SELECT 
    department,
    current_semester,
    COUNT(*) as student_count
FROM students 
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, current_semester
ORDER BY current_semester;

-- 3. Check if attendance records have proper student links
SELECT 'Attendance records with student info:' as info;
SELECT 
    a.registration_no,
    s.department,
    s.current_semester,
    DATE(a.date) as date,
    a.subject_code,
    a.is_present
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department ILIKE '%computer science%engineering%'
  AND s.current_semester IN (3, 5)
ORDER BY s.current_semester, a.registration_no
LIMIT 10;

-- 4. Check what's in the summary tables
SELECT 'Overall attendance summary:' as info;
SELECT 
    department,
    semester,
    COUNT(*) as students,
    ROUND(AVG(overall_percentage), 2) as avg_percentage
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
  AND semester IN (3, 5)
GROUP BY department, semester
ORDER BY semester;

-- 5. Check daily attendance table
SELECT 'Daily attendance summary for today:' as info;
SELECT 
    DATE(date) as date,
    COUNT(*) as records,
    COUNT(CASE WHEN is_present THEN 1 END) as present_today,
    COUNT(CASE WHEN NOT is_present THEN 1 END) as absent_today
FROM daily_attendance
WHERE DATE(date) = CURRENT_DATE
GROUP BY DATE(date);
