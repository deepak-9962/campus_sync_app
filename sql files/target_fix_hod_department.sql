-- TARGET FIX: Update HOD user to match the correct department name

-- First, let's see what department names exist in students table
SELECT 'Current department names in students table:' as info;
SELECT DISTINCT department, COUNT(*) as student_count
FROM students 
GROUP BY department
ORDER BY department;

-- Check if there's attendance data for today
SELECT 'Attendance data for today:' as info;
SELECT COUNT(*) as total_attendance_records
FROM attendance 
WHERE DATE(date) = CURRENT_DATE;

-- Update HOD user to match the students' department name
-- (This assumes students have "Computer Science and Engineering")
UPDATE users 
SET department = 'Computer Science and Engineering',
    assigned_department = 'Computer Science and Engineering'
WHERE role = 'hod' 
  AND (department = 'computer science engineering' 
       OR assigned_department = 'computer science engineering');

-- Verify the update
SELECT 'Updated HOD user:' as info;
SELECT id, name, role, department, assigned_department
FROM users 
WHERE role = 'hod';

-- Now rebuild the summary table with the correct department matching
DELETE FROM overall_attendance_summary 
WHERE department ILIKE '%computer science%engineering%';

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

-- Show final results
SELECT 'Final summary by semester:' as info;
SELECT department, semester, COUNT(*) as students, ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, semester
ORDER BY semester;
