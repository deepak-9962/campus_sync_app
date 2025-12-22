-- Fix user c2560e45-8d01-41ed-b953-a6abe1d83b77
-- This user should be a student with is_admin = false

-- Check current state
SELECT id, email, name, role, is_admin, assigned_department
FROM public.users 
WHERE id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';

-- Fix: Set role to 'student' and is_admin to false for this user
UPDATE public.users 
SET role = 'student',
    is_admin = false,
    updated_at = now()
WHERE id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';

-- Verify the fix
SELECT id, email, name, role, is_admin, assigned_department
FROM public.users 
WHERE id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';
