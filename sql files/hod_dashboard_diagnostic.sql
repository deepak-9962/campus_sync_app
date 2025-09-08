-- HOD Dashboard Data Flow Diagnostic Script
-- Run this script to diagnose the complete data flow issue

-- Step 1: Check if daily_attendance table has RLS enabled
SELECT 
    schemaname, 
    tablename, 
    rowsecurity,
    CASE 
        WHEN rowsecurity = true THEN 'RLS ENABLED - Policies Required'
        ELSE 'RLS DISABLED - Full Access'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'daily_attendance';

-- Step 2: List all RLS policies on daily_attendance table
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd,
    qual,
    CASE 
        WHEN qual LIKE '%hod%' THEN 'HOD POLICY FOUND'
        WHEN qual LIKE '%admin%' THEN 'ADMIN POLICY'
        WHEN qual LIKE '%staff%' THEN 'STAFF POLICY'
        WHEN qual LIKE '%student%' THEN 'STUDENT POLICY'
        ELSE 'OTHER POLICY'
    END as policy_type
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- Step 3: Check if any HOD users exist
SELECT 
    email, 
    role, 
    assigned_department, 
    name,
    created_at
FROM public.users 
WHERE role = 'hod'
ORDER BY assigned_department;

-- Step 4: Check sample daily_attendance data for today
SELECT 
    da.date,
    da.registration_no,
    da.is_present,
    s.student_name,
    s.department,
    s.current_semester
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE
ORDER BY s.department, s.student_name
LIMIT 20;

-- Step 5: Count attendance records by department for today
SELECT 
    s.department,
    COUNT(da.id) as total_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE
GROUP BY s.department
ORDER BY s.department;

-- Step 6: Check students count by department
SELECT 
    department,
    COUNT(*) as total_students,
    COUNT(DISTINCT current_semester) as semesters
FROM public.students
GROUP BY department
ORDER BY department;

-- Step 7: Test HOD access permissions (run this after logging in as HOD)
-- This query simulates what the HOD service is trying to do
WITH department_students AS (
    SELECT registration_no, student_name, department
    FROM public.students 
    WHERE department ILIKE '%Computer Science%'
    LIMIT 5
)
SELECT 
    ds.registration_no,
    ds.student_name,
    ds.department,
    da.is_present,
    da.date
FROM department_students ds
LEFT JOIN public.daily_attendance da ON da.registration_no = ds.registration_no 
    AND da.date = CURRENT_DATE;

-- Step 8: Check authentication state
SELECT 
    auth.uid() as current_user_id,
    auth.email() as current_user_email;

-- Step 9: Verify permissions on all tables
SELECT 
    schemaname,
    tablename,
    tableowner,
    rowsecurity,
    CASE WHEN rowsecurity THEN 'Protected by RLS' ELSE 'Open Access' END as access_level
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('daily_attendance', 'students', 'users')
ORDER BY tablename;

-- Step 10: Check if there are any conflicting policies
SELECT 
    tablename,
    COUNT(*) as policy_count,
    STRING_AGG(policyname, ', ') as policy_names
FROM pg_policies 
WHERE tablename IN ('daily_attendance', 'students', 'users')
GROUP BY tablename;

-- SOLUTION RECOMMENDATIONS:
-- If Step 2 shows no HOD policies for daily_attendance:
--   → RUN: hod_daily_attendance_rls_fix.sql
-- 
-- If Step 3 shows no HOD users:
--   → CREATE HOD user with proper department
--
-- If Step 4 shows no data:
--   → Faculty hasn't taken attendance yet
--
-- If Step 7 fails with permission error:
--   → RLS policy issue - apply the fix
--
-- If Step 8 returns null:
--   → Authentication issue - user not logged in

-- IMMEDIATE FIX for testing (TEMPORARY - removes RLS):
-- ALTER TABLE public.daily_attendance DISABLE ROW LEVEL SECURITY;
-- 
-- PROPER FIX (apply RLS policy):
-- See hod_daily_attendance_rls_fix.sql
