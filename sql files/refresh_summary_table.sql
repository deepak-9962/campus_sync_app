-- Check if we need to refresh the overall_attendance_summary table
-- This will rebuild the summary data for all students

TRUNCATE TABLE overall_attendance_summary;

INSERT INTO overall_attendance_summary (
    registration_no,
    department,
    semester,
    section,
    total_periods,
    attended_periods,
    overall_percentage,
    last_updated
)
SELECT 
    s.registration_no,
    s.department,
    s.semester,
    s.section,
    COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) + 
             SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0) as total_periods,
    COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END), 0) as attended_periods,
    CASE 
        WHEN COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) + 
                     SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0) = 0 
        THEN 0.0
        ELSE ROUND(
            (COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END), 0) * 100.0) / 
            NULLIF(COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) + 
                           SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0), 0), 2
        )
    END as overall_percentage,
    NOW() as last_updated
FROM students s
LEFT JOIN attendance a ON s.registration_no = a.registration_no
GROUP BY s.registration_no, s.department, s.semester, s.section
ORDER BY s.department, s.semester, s.registration_no;

-- Now check the results
SELECT 'After refresh - semester distribution:' as info;
SELECT semester, COUNT(*) as student_count, AVG(overall_percentage) as avg_attendance
FROM overall_attendance_summary 
WHERE department ILIKE '%computer%science%'
GROUP BY semester
ORDER BY semester;
