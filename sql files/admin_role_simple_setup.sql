-- ================================================================
-- SIMPLIFIED ADMIN ROLE SETUP - ALTERNATIVE APPROACH
-- ================================================================
-- Use this if the main script has issues with enum creation

-- ================================================================
-- OPTION 1: Manual approach if enum doesn't exist
-- ================================================================

-- Create the user_role enum type manually
CREATE TYPE user_role AS ENUM ('student', 'staff', 'faculty', 'teacher', 'hod', 'admin');

-- ================================================================
-- OPTION 2: If users table doesn't exist, create it
-- ================================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    role user_role DEFAULT 'student',
    assigned_department TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- OPTION 3: Simple admin user creation
-- ================================================================

-- Insert admin user
INSERT INTO public.users (email, role, assigned_department) 
VALUES ('admin@kingsedu.ac.in', 'admin', 'All Departments')
ON CONFLICT (email) DO UPDATE SET 
    role = 'admin',
    assigned_department = 'All Departments';

-- ================================================================
-- OPTION 4: Basic RLS policies for admin
-- ================================================================

-- Users table policy
DROP POLICY IF EXISTS "admin_users_policy" ON public.users;
CREATE POLICY "admin_users_policy" ON public.users
FOR ALL USING (
    id = auth.uid() OR 
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Students table policy (if exists)
DROP POLICY IF EXISTS "admin_students_policy" ON public.students;
CREATE POLICY "admin_students_policy" ON public.students
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'hod') OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('staff', 'faculty'))
);

-- Daily attendance policy (if exists)
DROP POLICY IF EXISTS "admin_attendance_policy" ON public.daily_attendance;
CREATE POLICY "admin_attendance_policy" ON public.daily_attendance
FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'hod') OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('staff', 'faculty'))
);

-- ================================================================
-- VERIFICATION
-- ================================================================

-- Check if everything was created
SELECT 'Checking setup...' as status;

-- Check enum
SELECT typname, enumlabel 
FROM pg_enum pe 
JOIN pg_type pt ON pe.enumtypid = pt.oid 
WHERE pt.typname = 'user_role'
ORDER BY pe.enumsortorder;

-- Check admin user
SELECT 'Admin user check:' as test, email, role, assigned_department 
FROM public.users 
WHERE email = 'admin@kingsedu.ac.in';

-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'students', 'daily_attendance');

SELECT 'Simplified admin setup complete!' as completion_status;
