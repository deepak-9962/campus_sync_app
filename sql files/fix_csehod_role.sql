-- Fix: Update csehod@kingsedu.ac.in to HOD role
-- This script specifically updates the user shown in the screenshot

-- Step 1: Check current status of the HOD user
SELECT 
    id,
    email, 
    role, 
    assigned_department, 
    name,
    department
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Step 2: Update csehod@kingsedu.ac.in to HOD role
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',
    name = 'HOD Computer Science and Engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- Step 3: Verify the update worked
SELECT 
    email, 
    role, 
    assigned_department, 
    name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Step 4: Check that we now have an HOD user
SELECT COUNT(*) as hod_users_count 
FROM public.users 
WHERE role = 'hod';

-- Step 5: Verify department name matches what's in students table
SELECT DISTINCT department 
FROM public.students 
WHERE department ILIKE '%computer science%'
ORDER BY department;

-- Expected Result:
-- The user csehod@kingsedu.ac.in should now show:
-- - role: 'hod'
-- - assigned_department: 'Computer Science and Engineering'
-- - name: 'HOD Computer Science and Engineering'

-- NEXT: After running this script, test the HOD dashboard
-- The user should now be able to access HOD features instead of student features
