-- SIMPLE FIX: Just refresh the summary tables with basic data

-- First, let's just focus on overall_attendance_summary
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

-- Show results
SELECT 'Updated overall summary:' as info;
SELECT department, semester, COUNT(*) as students, ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, semester
ORDER BY semester;

-- Check what attendance data exists for today
SELECT 'Today attendance summary:' as info;
SELECT 
    s.department,
    s.current_semester,
    COUNT(DISTINCT a.registration_no) as students_marked,
    COUNT(*) as total_periods,
    COUNT(CASE WHEN a.is_present THEN 1 END) as present_periods,
    COUNT(CASE WHEN NOT a.is_present THEN 1 END) as absent_periods
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department ILIKE '%computer science%engineering%'
GROUP BY s.department, s.current_semester
ORDER BY s.current_semester;
