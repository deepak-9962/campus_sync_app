-- HOD DASHBOARD DATA DEBUGGING - Step by Step
-- Run each section to identify exactly where the data flow is breaking

-- ================================================================
-- SECTION 1: Verify HOD User Setup
-- ================================================================
SELECT 'SECTION 1: HOD User Verification' as section;

SELECT 
    email, 
    role, 
    assigned_department, 
    department as old_department_column,
    name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- SECTION 2: Check Department Names (Critical for Matching)
-- ================================================================
SELECT 'SECTION 2: Department Name Analysis' as section;

-- Check what department names exist in students table
SELECT 'Students table department names:' as source;
SELECT DISTINCT department, COUNT(*) as student_count
FROM public.students
GROUP BY department
ORDER BY department;

-- Check what the HOD's assigned_department is set to
SELECT 'HOD assigned department:' as source;
SELECT assigned_department 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- SECTION 3: Test Direct Department Matching
-- ================================================================
SELECT 'SECTION 3: Department Matching Test' as section;

-- Test exact match
SELECT 'Exact match test:' as test_type;
SELECT COUNT(*) as matching_students
FROM public.students s
JOIN public.users u ON u.assigned_department = s.department
WHERE u.email = 'csehod@kingsedu.ac.in';

-- Test pattern matching (what your app uses)
SELECT 'Pattern matching test (Computer Science):' as test_type;
SELECT COUNT(*) as matching_students
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%';

-- Test simpler pattern
SELECT 'Simple pattern test (Computer Science):' as test_type;
SELECT COUNT(*) as matching_students
FROM public.students s
WHERE s.department ILIKE '%computer science%';

-- ================================================================
-- SECTION 4: Test Attendance Data for Today
-- ================================================================
SELECT 'SECTION 4: Attendance Data for 2025-09-08' as section;

-- Check total attendance records for today
SELECT 'Total attendance records today:' as info;
SELECT COUNT(*) as total_records
FROM public.daily_attendance
WHERE date = '2025-09-08';

-- Check attendance by department for today
SELECT 'Attendance by department today:' as info;
SELECT 
    s.department,
    COUNT(*) as attendance_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
GROUP BY s.department
ORDER BY s.department;

-- ================================================================
-- SECTION 5: Simulate App Logic Step by Step
-- ================================================================
SELECT 'SECTION 5: Simulating App Logic' as section;

-- Step 1: Get students for HOD's department (using app's pattern matching)
SELECT 'Step 1: Students query (app logic):' as step;
WITH hod_dept AS (
    SELECT assigned_department 
    FROM public.users 
    WHERE email = 'csehod@kingsedu.ac.in'
)
SELECT 
    COUNT(*) as total_students,
    'Students found using pattern matching' as note
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%';

-- Step 2: Get attendance for those students on 2025-09-08
SELECT 'Step 2: Attendance for department students:' as step;
WITH department_students AS (
    SELECT s.registration_no, s.student_name, s.department
    FROM public.students s
    WHERE s.department ILIKE '%computer science%engineering%'
)
SELECT 
    COUNT(ds.registration_no) as total_department_students,
    COUNT(da.registration_no) as students_with_attendance_today,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present_today,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent_today
FROM department_students ds
LEFT JOIN public.daily_attendance da ON ds.registration_no = da.registration_no 
    AND da.date = '2025-09-08';

-- ================================================================
-- SECTION 6: Test RLS Policies (Login as HOD required)
-- ================================================================
SELECT 'SECTION 6: RLS Policy Test (login as HOD to see results)' as section;

SELECT 'Test 1: Can HOD access students table?' as test;
-- This should return students if RLS policy works
SELECT COUNT(*) as accessible_students
FROM public.students
WHERE department ILIKE '%computer science%';

SELECT 'Test 2: Can HOD access daily_attendance table?' as test;
-- This should return attendance records if RLS policy works  
SELECT COUNT(*) as accessible_attendance_records
FROM public.daily_attendance
WHERE date = '2025-09-08';

SELECT 'Test 3: Can HOD access joined data?' as test;
-- This simulates the JOIN that the app does
SELECT COUNT(*) as accessible_joined_records
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
    AND s.department ILIKE '%computer science%';

-- ================================================================
-- EXPECTED RESULTS:
-- ================================================================
-- Section 1: Should show role='hod', assigned_department set
-- Section 2: Should show department names and verify matching
-- Section 3: Should show > 0 students found with pattern matching
-- Section 4: Should show attendance records exist for 2025-09-08
-- Section 5: Should show the exact counts the app should display
-- Section 6: Should work only when logged in as HOD user

SELECT 'Diagnostic complete - check each section for issues!' as final_message;
