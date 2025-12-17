-- Fix both Summary tab and missing Semester 3 data

-- First, check if Semester 3 students have attendance data
SELECT 'Check Semester 3 attendance data:' as info;
SELECT 
    s.current_semester,
    COUNT(DISTINCT s.registration_no) as total_students,
    COUNT(DISTINCT a.registration_no) as students_with_attendance,
    COUNT(*) as attendance_records
FROM students s
LEFT JOIN attendance a ON s.registration_no = a.registration_no
WHERE s.department = 'Computer Science and Engineering'
  AND s.current_semester = 3
GROUP BY s.current_semester;

-- Check what attendance dates exist for Semester 3
SELECT 'Semester 3 attendance dates:' as info;
SELECT 
    DATE(a.date) as attendance_date,
    COUNT(DISTINCT a.registration_no) as students,
    COUNT(*) as records
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE s.department = 'Computer Science and Engineering'
  AND s.current_semester = 3
GROUP BY DATE(a.date)
ORDER BY attendance_date DESC;

-- Rebuild overall_attendance_summary for ALL semesters (including 3)
DELETE FROM overall_attendance_summary 
WHERE department = 'Computer Science and Engineering';

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
WHERE s.department = 'Computer Science and Engineering'
GROUP BY a.registration_no, s.department, s.current_semester, s.section;

-- Also ensure daily_attendance has today's data
DELETE FROM daily_attendance 
WHERE DATE(date) = CURRENT_DATE;

INSERT INTO daily_attendance (
    date, registration_no, is_present
)
SELECT 
    DATE(a.date) as date,
    a.registration_no,
    (COUNT(CASE WHEN a.is_present THEN 1 END) > 0) as is_present
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department = 'Computer Science and Engineering'
GROUP BY DATE(a.date), a.registration_no;

-- Show results by semester
SELECT 'Updated summary by semester:' as info;
SELECT 
    department, 
    semester, 
    COUNT(*) as students, 
    ROUND(AVG(overall_percentage), 2) as avg_attendance,
    MIN(overall_percentage) as min_attendance,
    MAX(overall_percentage) as max_attendance
FROM overall_attendance_summary
WHERE department = 'Computer Science and Engineering'
GROUP BY department, semester
ORDER BY semester;

-- Show today's attendance summary for the dashboard
SELECT 'Today attendance summary for dashboard:' as info;
SELECT 
    COUNT(DISTINCT s.registration_no) as total_students,
    COUNT(DISTINCT da.registration_no) as students_marked_today,
    COUNT(CASE WHEN da.is_present THEN 1 END) as present_today,
    COUNT(CASE WHEN NOT da.is_present THEN 1 END) as absent_today
FROM students s
LEFT JOIN daily_attendance da ON s.registration_no = da.registration_no 
    AND DATE(da.date) = CURRENT_DATE
WHERE s.department = 'Computer Science and Engineering';

-- Show overall department statistics
SELECT 'Overall department statistics:' as info;
SELECT 
    COUNT(DISTINCT s.registration_no) as total_students_in_dept,
    COUNT(DISTINCT oas.registration_no) as students_with_attendance_records,
    ROUND(AVG(oas.overall_percentage), 2) as dept_avg_attendance,
    COUNT(CASE WHEN oas.overall_percentage < 75 THEN 1 END) as low_attendance_students
FROM students s
LEFT JOIN overall_attendance_summary oas ON s.registration_no = oas.registration_no
WHERE s.department = 'Computer Science and Engineering';
