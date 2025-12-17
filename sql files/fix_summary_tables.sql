-- QUICK FIX: Refresh summary tables for HOD dashboard

-- First, clear and rebuild overall_attendance_summary for computer science dept
DELETE FROM overall_attendance_summary 
WHERE department ILIKE '%computer science%engineering%';

-- Rebuild overall_attendance_summary with current data
INSERT INTO overall_attendance_summary (
    registration_no, department, semester, section,
    total_periods, attended_periods, overall_percentage, last_updated
)
SELECT 
    a.registration_no,
    s.department,
    s.current_semester as semester,
    s.section,
    COUNT(*) as total_periods,
    COUNT(CASE WHEN a.is_present THEN 1 END) as attended_periods,
    ROUND(
        (COUNT(CASE WHEN a.is_present THEN 1 END) * 100.0 / COUNT(*)), 2
    ) as overall_percentage,
    NOW() as last_updated
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE s.department ILIKE '%computer science%engineering%'
GROUP BY a.registration_no, s.department, s.current_semester, s.section;

-- Clear and rebuild daily_attendance for today
DELETE FROM daily_attendance 
WHERE DATE(date) = CURRENT_DATE;

-- Rebuild daily_attendance for today (using only existing columns)
INSERT INTO daily_attendance (
    date, registration_no, is_present, last_updated
)
SELECT 
    DATE(a.date) as date,
    a.registration_no,
    (COUNT(CASE WHEN a.is_present THEN 1 END) > 0) as is_present,
    NOW() as last_updated
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department ILIKE '%computer science%engineering%'
GROUP BY DATE(a.date), a.registration_no;

-- Verify the results
SELECT 'Updated overall summary:' as info;
SELECT department, semester, COUNT(*) as students, ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, semester
ORDER BY semester;

SELECT 'Updated daily summary for today:' as info;
SELECT 
    DATE(date) as date,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_present THEN 1 END) as present_today,
    COUNT(CASE WHEN NOT is_present THEN 1 END) as absent_today
FROM daily_attendance
WHERE DATE(date) = CURRENT_DATE
GROUP BY DATE(date);
