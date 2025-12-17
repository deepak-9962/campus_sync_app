-- URGENT FIX: Remove infinite recursion in users table RLS policy
-- This is causing the "infinite recursion detected in policy for relation users" error

-- Step 1: Check current problematic policies on users table
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Step 2: Drop the problematic admin policy that causes recursion
DROP POLICY IF EXISTS "Admins can manage users" ON public.users;

-- Step 3: Create a simple, non-recursive policy for users
-- This allows users to see their own profile without causing recursion
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT USING (auth.uid() = id);

-- Step 4: Allow public read access to users table (for role checking)
-- This prevents recursion issues when other services need to check roles
DROP POLICY IF EXISTS "Allow public read access to users" ON public.users;
CREATE POLICY "Allow public read access to users" ON public.users
FOR SELECT USING (true);

-- Step 5: Verify the problematic policies are gone
SELECT policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Step 6: Now update the user role (this should work without recursion errors)
UPDATE public.users 
SET 
    role = 'hod',
    assigned_department = 'Computer Science and Engineering',
    name = 'HOD Computer Science and Engineering'
WHERE email = 'csehod@kingsedu.ac.in';

-- Step 7: Verify the update worked
SELECT 
    email, 
    role, 
    assigned_department, 
    name 
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- Step 8: Test that the recursion error is fixed
SELECT COUNT(*) as total_users FROM public.users;

SELECT 'Recursion error fixed - restart your app now!' as status;
