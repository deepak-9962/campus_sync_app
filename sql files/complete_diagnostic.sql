-- COMPLETE DIAGNOSTIC AND TEST SCRIPT
-- Run this step by step to identify and fix the issue

-- ================================================================
-- STEP 1: Basic Data Verification
-- ================================================================
SELECT 'STEP 1: Checking if attendance data exists for 2025-09-08' as step;

-- Check raw attendance data for today
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.daily_attendance 
WHERE date = '2025-09-08';

-- ================================================================
-- STEP 2: Check Department-Specific Data
-- ================================================================
SELECT 'STEP 2: Checking CSE/Computer Science attendance for 2025-09-08' as step;

SELECT 
    s.department,
    COUNT(*) as attendance_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
    AND (s.department ILIKE '%CSE%' OR s.department ILIKE '%Computer Science%')
GROUP BY s.department;

-- ================================================================
-- STEP 3: Test RPC Function (if it exists)
-- ================================================================
SELECT 'STEP 3: Testing RPC function' as step;

-- Check if function exists
SELECT 
    proname as function_name,
    oidvectortypes(proargtypes) as argument_types
FROM pg_proc 
WHERE proname = 'get_department_attendance_summary';

-- Test the function with both possible department names
SELECT 'Testing RPC with CSE:' as test;
-- SELECT * FROM get_department_attendance_summary('CSE', '2025-09-08'::date);

SELECT 'Testing RPC with full name:' as test;
-- SELECT * FROM get_department_attendance_summary('Computer Science and Engineering', '2025-09-08'::date);

-- ================================================================
-- STEP 4: Check RLS Policies
-- ================================================================
SELECT 'STEP 4: Checking RLS policies' as step;

-- Check policies on daily_attendance
SELECT 'daily_attendance policies:' as table_name;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- Check policies on students
SELECT 'students policies:' as table_name;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'students'
ORDER BY policyname;

-- Check policies on users
SELECT 'users policies:' as table_name;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- ================================================================
-- STEP 5: Check HOD User Configuration
-- ================================================================
SELECT 'STEP 5: Checking HOD user configuration' as step;

SELECT 
    email, 
    role, 
    assigned_department, 
    department,  -- old column if it exists
    name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- STEP 6: Manual JOIN Test (What the app is trying to do)
-- ================================================================
SELECT 'STEP 6: Manual JOIN test - simulating app logic' as step;

-- This simulates what your app should be doing
WITH department_students AS (
    SELECT registration_no, student_name, department, current_semester
    FROM public.students 
    WHERE department ILIKE '%Computer Science%' OR department ILIKE '%CSE%'
),
today_attendance AS (
    SELECT registration_no, is_present
    FROM public.daily_attendance
    WHERE date = '2025-09-08'
)
SELECT 
    COUNT(ds.registration_no) as total_students,
    COUNT(ta.registration_no) as students_with_attendance,
    SUM(CASE WHEN ta.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN ta.is_present = false THEN 1 ELSE 0 END) as absent_count,
    ROUND(
        (SUM(CASE WHEN ta.is_present = true THEN 1 ELSE 0 END)::numeric / 
         NULLIF(COUNT(ds.registration_no), 0)) * 100, 2
    ) as attendance_percentage
FROM department_students ds
LEFT JOIN today_attendance ta ON ds.registration_no = ta.registration_no;

-- ================================================================
-- EXPECTED RESULTS:
-- ================================================================
-- Step 1: Should show > 0 total_records if any attendance exists
-- Step 2: Should show attendance records for CSE/Computer Science department
-- Step 3: Should show if RPC function exists and works
-- Step 4: Should show RLS policies for all tables
-- Step 5: Should show csehod@kingsedu.ac.in with role='hod'
-- Step 6: Should show the same counts that the app should display

SELECT 'Diagnostic complete - check each step result' as final_message;
