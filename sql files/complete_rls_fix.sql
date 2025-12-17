-- COMPLETE RLS FIX for HOD Dashboard Data Access
-- This addresses all permission issues for HOD role

-- ================================================================
-- PART 1: Fix Users Table RLS (Remove Recursion)
-- ================================================================

-- First, fix the infinite recursion in users table
DROP POLICY IF EXISTS "Admins can manage users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;

-- Create simple, non-recursive policy for users table
CREATE POLICY "Allow read access to users" ON public.users
FOR SELECT USING (true);

-- ================================================================
-- PART 2: RLS Policy for daily_attendance Table
-- ================================================================

-- Check current policies on daily_attendance
SELECT 'Current daily_attendance policies:' as info;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- Drop existing HOD policy if it exists
DROP POLICY IF EXISTS "HOD can view department daily attendance" ON public.daily_attendance;

-- Create HOD policy for daily_attendance
CREATE POLICY "HOD can view department daily attendance" ON public.daily_attendance
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users u
        JOIN public.students s ON s.registration_no = daily_attendance.registration_no
        WHERE u.id = auth.uid() 
        AND u.role = 'hod'
        AND u.assigned_department = s.department
    )
);

-- ================================================================
-- PART 3: RLS Policy for students Table  
-- ================================================================

-- Check current policies on students table
SELECT 'Current students policies:' as info;
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'students'
ORDER BY policyname;

-- Drop existing HOD policy if it exists
DROP POLICY IF EXISTS "HOD can view department students" ON public.students;

-- Create HOD policy for students table (CRITICAL for JOIN to work)
CREATE POLICY "HOD can view department students" ON public.students
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() 
        AND u.role = 'hod'
        AND u.assigned_department = students.department
    )
);

-- ================================================================
-- PART 4: Grant Required Permissions
-- ================================================================

-- Grant schema and table permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.daily_attendance TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.users TO authenticated;

-- Note: Skipping RPC function grant since get_department_attendance_summary doesn't exist
-- Your app uses direct table queries instead of RPC functions

-- ================================================================
-- PART 5: Update User Role
-- ================================================================

-- Update csehod@kingsedu.ac.in to HOD role
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',
    name = 'HOD Computer Science and Engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- PART 6: Verification Tests
-- ================================================================

-- Test 1: Verify policies are created
SELECT 'Verification - RLS Policies Created:' as test;
SELECT tablename, policyname, permissive, roles 
FROM pg_policies 
WHERE tablename IN ('daily_attendance', 'students', 'users')
    AND policyname LIKE '%HOD%'
ORDER BY tablename, policyname;

-- Test 2: Verify user role update
SELECT 'Verification - HOD User Updated:' as test;
SELECT email, role, assigned_department, name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Test 3: Test direct table access (since RPC function doesn't exist)
SELECT 'Verification - Test Direct Table Access:' as test;
SELECT 'Manual test query - run after logging in as HOD:' as instruction;

-- This simulates what your app actually does
WITH hod_department AS (
    SELECT assigned_department 
    FROM public.users 
    WHERE id = auth.uid() AND role = 'hod'
),
department_students AS (
    SELECT s.registration_no, s.student_name, s.department
    FROM public.students s, hod_department hd
    WHERE s.department = hd.assigned_department
),
today_attendance AS (
    SELECT da.registration_no, da.is_present
    FROM public.daily_attendance da
    WHERE da.date = '2025-09-08'
)
SELECT 
    COUNT(ds.registration_no) as total_students,
    COUNT(ta.registration_no) as students_with_attendance,
    SUM(CASE WHEN ta.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN ta.is_present = false THEN 1 ELSE 0 END) as absent_count
FROM department_students ds
LEFT JOIN today_attendance ta ON ds.registration_no = ta.registration_no;

-- Test 4: Verify department name consistency
SELECT 'Verification - Department Names:' as test;
SELECT DISTINCT department as student_departments 
FROM public.students 
WHERE department ILIKE '%computer science%' OR department ILIKE '%cse%'
ORDER BY department;

SELECT 'RLS Fix Complete - Restart your app and test!' as final_status;
