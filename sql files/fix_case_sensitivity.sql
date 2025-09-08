-- CASE SENSITIVITY FIX - The root cause of the dashboard issue
-- Problem: Department names have case mismatches causing RLS policy failures

-- ================================================================
-- STEP 1: Identify the case mismatch
-- ================================================================
SELECT 'Current case mismatch analysis:' as analysis;

-- HOD's assigned department (Title Case)
SELECT 
    'HOD assigned_department:' as source,
    assigned_department as department_name
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Students table department (lowercase)
SELECT 
    'Students table department:' as source,
    department as department_name
FROM public.students 
WHERE department ILIKE '%computer science%'
LIMIT 1;

-- ================================================================
-- STEP 2: Fix HOD's assigned_department to match students table
-- ================================================================
UPDATE public.users 
SET assigned_department = 'computer science and engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- STEP 3: Update RLS policies to be case-insensitive
-- ================================================================

-- Fix students table RLS policy (make case-insensitive)
DROP POLICY IF EXISTS "HOD can view department students" ON public.students;

CREATE POLICY "HOD can view department students" ON public.students
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid() 
        AND u.role = 'hod'
        AND LOWER(u.assigned_department) = LOWER(students.department)
    )
);

-- Fix daily_attendance RLS policy (make case-insensitive)
DROP POLICY IF EXISTS "HOD can view department daily attendance" ON public.daily_attendance;

CREATE POLICY "HOD can view department daily attendance" ON public.daily_attendance
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users u
        JOIN public.students s ON s.registration_no = daily_attendance.registration_no
        WHERE u.id = auth.uid() 
        AND u.role = 'hod'
        AND LOWER(u.assigned_department) = LOWER(s.department)
    )
);

-- ================================================================
-- STEP 4: Verification
-- ================================================================

-- Verify HOD update
SELECT 'HOD department after fix:' as verification;
SELECT 
    email,
    assigned_department,
    'should now match students table exactly' as note
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Test case-insensitive matching
SELECT 'Case-insensitive matching test:' as verification;
SELECT COUNT(*) as matching_students
FROM public.students s
JOIN public.users u ON LOWER(u.assigned_department) = LOWER(s.department)
WHERE u.email = 'csehod@kingsedu.ac.in';

-- Test attendance access with fixed policies
SELECT 'Attendance access test (run as HOD user):' as verification;
SELECT 'After login as HOD, this should return attendance records:' as instruction;
-- The following query should work when logged in as HOD:
-- SELECT COUNT(*) FROM public.daily_attendance da 
-- JOIN public.students s ON da.registration_no = s.registration_no 
-- WHERE da.date = '2025-09-08' AND LOWER(s.department) LIKE '%computer science%';

SELECT 'Case sensitivity fix complete!' as status;
SELECT 'Restart your app - dashboard should now show correct data!' as next_step;
