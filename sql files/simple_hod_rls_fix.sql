-- Simple HOD RLS Policy Fix - Just adds the policy without user creation
-- Run this after ensuring your HOD user exists in the users table

-- Step 1: Check current RLS policies on daily_attendance
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- Step 2: Add the HOD policy for daily_attendance table
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

-- Step 3: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.daily_attendance TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.users TO authenticated;

-- Step 4: Verify the policy was created
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'daily_attendance' 
    AND policyname = 'HOD can view department daily attendance';

-- Step 5: Check if you have HOD users (should show at least one)
SELECT 
    email, 
    role, 
    assigned_department, 
    name 
FROM public.users 
WHERE role = 'hod';

-- Step 6: Test the policy (run this after logging in as HOD)
-- This query should return attendance data if the policy works
SELECT 
    COUNT(*) as accessible_records,
    'Policy working if count > 0' as status
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE;

-- NEXT STEPS:
-- 1. If Step 5 shows no HOD users, update an existing user:
--    UPDATE public.users SET role = 'hod', assigned_department = 'Computer Science and Engineering' 
--    WHERE email = 'your-email@domain.com';
--
-- 2. Test the HOD dashboard after running this script
-- 3. Check browser console for detailed logs
