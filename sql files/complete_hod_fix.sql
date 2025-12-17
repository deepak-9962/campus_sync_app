-- Complete HOD Dashboard Fix - Run these in order
-- This combines the RLS policy fix + user role update

-- PART 1: Add RLS Policy for HOD access to daily_attendance
-- ========================================================

-- Check current policies
SELECT policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'daily_attendance'
ORDER BY policyname;

-- Add the HOD policy
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

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.daily_attendance TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.users TO authenticated;

-- PART 2: Fix the user role
-- =========================

-- Update csehod@kingsedu.ac.in to HOD role
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',
    name = 'HOD Computer Science and Engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- PART 3: Verification
-- ====================

-- Verify the policy was created
SELECT policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'daily_attendance' 
    AND policyname = 'HOD can view department daily attendance';

-- Verify the user role was updated
SELECT 
    email, 
    role, 
    assigned_department, 
    name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Check if HOD can now access attendance data
SELECT 
    COUNT(*) as accessible_records,
    'HOD policy working if count > 0' as status
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE;

-- SUCCESS INDICATORS:
-- 1. Policy created successfully
-- 2. User role = 'hod' 
-- 3. User assigned_department = 'Computer Science and Engineering'
-- 4. accessible_records > 0 (if attendance data exists for today)

SELECT 'HOD Dashboard Fix Complete - Test the dashboard now!' as final_message;
