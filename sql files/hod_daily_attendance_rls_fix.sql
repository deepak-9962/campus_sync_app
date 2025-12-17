-- HOD Dashboard Data Flow Fix - Complete Solution
-- This script addresses the critical data flow issue where HOD dashboard
-- shows old/zero data despite fresh data existing in daily_attendance table

-- ISSUE IDENTIFIED: No RLS policy exists for HOD role to access daily_attendance table
-- Current policies only allow admin, staff, and students (own records)
-- HOD role cannot read any daily_attendance records due to RLS restrictions

-- SOLUTION 1: Add RLS policy for HOD to access daily_attendance for their department

-- First, check current policies on daily_attendance table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance';

-- Add HOD policy for daily_attendance table
DROP POLICY IF EXISTS "HOD can view department daily attendance" ON public.daily_attendance;

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

-- SOLUTION 2: Verify users table has proper HOD entries
-- Check if current user has HOD role with department
SELECT u.email, u.role, u.assigned_department, u.name
FROM public.users u
WHERE u.role = 'hod'
ORDER BY u.assigned_department;

-- SOLUTION 3: Test the policy by checking what daily_attendance records are visible
-- Run this as the HOD user to verify policy works
SELECT da.date, da.registration_no, s.student_name as student_name, s.department, da.is_present
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE
ORDER BY s.department, s.student_name
LIMIT 10;

-- SOLUTION 4: Check if HOD user exists, if not provide instructions
-- First check if we have any HOD users
SELECT COUNT(*) as hod_users_count FROM public.users WHERE role = 'hod';

-- If no HOD users exist, you need to update an existing user to HOD role
-- Example: Update a specific user to be HOD (replace with actual user email/id)
-- 
-- Method 1: If you know the user's email
-- UPDATE public.users 
-- SET role = 'hod', assigned_department = 'Computer Science and Engineering'
-- WHERE email = 'your-hod-email@example.com';
--
-- Method 2: If you know the user's auth ID
-- UPDATE public.users 
-- SET role = 'hod', assigned_department = 'Computer Science and Engineering'  
-- WHERE id = 'your-auth-user-id-here';
--
-- Method 3: Create a test HOD user manually in Supabase Auth first, then update:
-- After creating user in Supabase Auth Dashboard, run:
-- UPDATE public.users 
-- SET role = 'hod', assigned_department = 'Computer Science and Engineering'
-- WHERE email = 'new-hod-email@example.com';

-- SOLUTION 5: Grant necessary permissions to public schema for RLS
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.daily_attendance TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.users TO authenticated;

-- VERIFICATION QUERIES:
-- 1. Check if RLS is enabled on daily_attendance
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'daily_attendance';

-- 2. Verify all policies on daily_attendance
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- 3. Test department filtering works correctly
SELECT DISTINCT s.department, COUNT(da.id) as attendance_records
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE
GROUP BY s.department;

-- IMPORTANT NOTES:
-- 1. Run this script in Supabase SQL Editor as admin user
-- 2. Make sure HOD user exists in user_roles table with correct department
-- 3. Test the dashboard after running this script
-- 4. Check browser console for any remaining errors
