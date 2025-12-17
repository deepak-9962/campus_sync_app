-- Update existing user to HOD role
-- Replace 'your-email@domain.com' with the actual email of the user you want to make HOD

-- Step 1: Check what users exist
SELECT 
    id,
    email, 
    role, 
    assigned_department, 
    name,
    department  -- Original department column if it exists
FROM public.users 
ORDER BY email;

-- Step 2: Update a specific user to be HOD
-- REPLACE 'your-email@domain.com' with the actual email
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',  -- Match your department name exactly
    name = 'HOD Computer Science'  -- Optional: update name
WHERE email = 'your-email@domain.com';  -- CHANGE THIS EMAIL

-- Step 3: Verify the update
SELECT 
    email, 
    role, 
    assigned_department, 
    name 
FROM public.users 
WHERE role = 'hod';

-- Step 4: Check what department names exist in students table (to ensure exact match)
SELECT DISTINCT department 
FROM public.students 
ORDER BY department;

-- IMPORTANT NOTES:
-- 1. The assigned_department MUST exactly match the department name in students table
-- 2. Common department names might be:
--    - 'Computer Science and Engineering'
--    - 'Computer Science'  
--    - 'CSE'
-- 3. After running this, test the HOD dashboard
-- 4. Check that the email you're updating actually exists in the users table

-- ALTERNATIVE: If you need to see all auth users (from Supabase Auth)
-- SELECT id, email FROM auth.users ORDER BY email;
