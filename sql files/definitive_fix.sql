-- DEFINITIVE FIX: Align HOD department with students table

-- Step 1: Update HOD user to match students table exactly
UPDATE users 
SET department = 'Computer Science and Engineering',
    assigned_department = 'Computer Science and Engineering'
WHERE role = 'hod';

-- Step 2: Verify HOD update
SELECT 'Updated HOD user:' as info;
SELECT name, role, department, assigned_department
FROM users 
WHERE role = 'hod';

-- Step 3: Clear and rebuild overall_attendance_summary with exact department match
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

-- Step 4: Check results
SELECT 'Summary by semester:' as info;
SELECT department, semester, COUNT(*) as students, ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department = 'Computer Science and Engineering'
GROUP BY department, semester
ORDER BY semester;

-- Step 5: Check today's attendance specifically
SELECT 'Today attendance for CS Engineering:' as info;
SELECT 
    s.current_semester as semester,
    COUNT(DISTINCT a.registration_no) as students_with_attendance,
    COUNT(CASE WHEN a.is_present THEN 1 END) as present_periods,
    COUNT(CASE WHEN NOT a.is_present THEN 1 END) as absent_periods
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department = 'Computer Science and Engineering'
GROUP BY s.current_semester
ORDER BY s.current_semester;
