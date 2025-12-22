-- Fix student users who incorrectly have is_admin = true
-- This script sets is_admin = false for all users with role = 'student'

-- First, let's see which students have is_admin = true
SELECT id, email, name, role, is_admin 
FROM public.users 
WHERE role = 'student' AND is_admin = true;

-- Fix all students to have is_admin = false
UPDATE public.users 
SET is_admin = false 
WHERE role = 'student' AND is_admin = true;

-- Verify the fix
SELECT id, email, name, role, is_admin 
FROM public.users 
WHERE role = 'student';

-- Also check if there's a trigger that creates user records on auth.users insert
-- This ensures new registrations create users with correct defaults
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, is_admin)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'student', -- Default role
    false      -- Default is_admin
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
