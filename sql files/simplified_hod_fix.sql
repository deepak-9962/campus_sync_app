-- SIMPLIFIED HOD DASHBOARD FIX
-- Focuses only on essential RLS policies and user role fix

-- ================================================================
-- STEP 1: Fix Users Table RLS (Remove Recursion)
-- ================================================================
DROP POLICY IF EXISTS "Admins can manage users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Allow public read access to users" ON public.users;

-- Create simple, non-recursive policy
CREATE POLICY "Allow read access to users" ON public.users
FOR SELECT USING (true);

-- ================================================================
-- STEP 2: Fix User Role
-- ================================================================
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',
    name = 'HOD Computer Science and Engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- STEP 3: RLS Policy for students Table (CRITICAL)
-- ================================================================
DROP POLICY IF EXISTS "HOD can view department students" ON public.students;

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
-- STEP 4: RLS Policy for daily_attendance Table  
-- ================================================================
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

-- ================================================================
-- STEP 5: Grant Permissions
-- ================================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.daily_attendance TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.users TO authenticated;

-- ================================================================
-- VERIFICATION
-- ================================================================

-- Check user role update
SELECT 'User Role Check:' as test;
SELECT email, role, assigned_department, name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Check department names in students table
SELECT 'Department Names:' as test;
SELECT DISTINCT department 
FROM public.students 
WHERE department ILIKE '%computer science%' OR department ILIKE '%cse%'
ORDER BY department;

-- Check if attendance data exists for today
SELECT 'Attendance Data Check:' as test;
SELECT 
    s.department,
    COUNT(*) as attendance_records
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
    AND (s.department ILIKE '%Computer Science%' OR s.department ILIKE '%CSE%')
GROUP BY s.department;

SELECT 'Fix complete - restart your app!' as status;
