-- Step-by-step debugging to find why HOD dashboard shows zeros

-- 1. Check if attendance data exists for today
SELECT 'Step 1: Check attendance data for today' as debug_step;
SELECT 
    DATE(date) as attendance_date,
    COUNT(*) as total_records,
    COUNT(DISTINCT registration_no) as unique_students,
    COUNT(CASE WHEN is_present THEN 1 END) as present_records,
    COUNT(CASE WHEN NOT is_present THEN 1 END) as absent_records
FROM attendance 
WHERE DATE(date) = CURRENT_DATE
GROUP BY DATE(date);

-- 2. Check students table for computer science department
SELECT 'Step 2: Check students in computer science department' as debug_step;
SELECT 
    department,
    current_semester,
    COUNT(*) as student_count
FROM students 
WHERE department ILIKE '%computer science%'
GROUP BY department, current_semester
ORDER BY current_semester;

-- 3. Check if attendance records are linked to computer science students
SELECT 'Step 3: Check attendance linked to CS students today' as debug_step;
SELECT 
    s.department,
    s.current_semester,
    COUNT(DISTINCT a.registration_no) as students_with_attendance,
    COUNT(*) as total_attendance_records
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department ILIKE '%computer science%'
GROUP BY s.department, s.current_semester
ORDER BY s.current_semester;

-- 4. Check what's in overall_attendance_summary now
SELECT 'Step 4: Check overall_attendance_summary table' as debug_step;
SELECT 
    department,
    semester,
    COUNT(*) as students_in_summary,
    ROUND(AVG(overall_percentage), 2) as avg_percentage
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%'
GROUP BY department, semester
ORDER BY semester;

-- 5. Check the exact department names to find mismatch
SELECT 'Step 5: Check exact department names' as debug_step;
SELECT DISTINCT department, COUNT(*) as count
FROM students 
GROUP BY department
ORDER BY department;

-- 6. Check HOD user department
SELECT 'Step 6: Check HOD user department' as debug_step;
SELECT id, name, role, department, assigned_department
FROM users 
WHERE role = 'hod';
