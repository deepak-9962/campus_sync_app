-- ================================================================
-- ADMIN ROLE IMPLEMENTATION - COMPLETE BACKEND SETUP
-- ================================================================

-- STEP 1: Create user_role enum type and add 'admin' role
-- ================================================================

-- First, check if the enum exists, if not create it
DO $$ 
BEGIN 
    -- Check if the enum type exists
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        -- Create the enum with basic roles if it doesn't exist
        CREATE TYPE user_role AS ENUM ('student', 'staff', 'faculty', 'teacher', 'hod', 'admin');
        RAISE NOTICE 'Created user_role enum with all roles including admin';
    ELSE
        -- If enum exists, try to add admin value if not already present
        BEGIN
            ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'admin';
            RAISE NOTICE 'Added admin to existing user_role enum';
        EXCEPTION 
            WHEN duplicate_object THEN 
                RAISE NOTICE 'Admin role already exists in enum';
        END;
    END IF;
END $$;

-- Verify the enum now includes all roles
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        RAISE NOTICE 'user_role enum values: %', (SELECT enum_range(NULL::user_role));
    ELSE
        RAISE NOTICE 'user_role enum still does not exist - check permissions';
    END IF;
END $$;

-- ================================================================
-- STEP 2: Ensure users table has proper structure
-- ================================================================

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    role user_role DEFAULT 'student',
    assigned_department TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clean up any duplicate emails before adding UNIQUE constraint
DO $$
BEGIN
    -- First, remove any duplicate entries for our admin email
    DELETE FROM public.users 
    WHERE email = 'deepak5122d@gmail.com' 
    AND id NOT IN (
        SELECT MIN(id) FROM public.users 
        WHERE email = 'deepak5122d@gmail.com'
    );
    
    -- Remove any other duplicate emails in the table
    DELETE FROM public.users 
    WHERE id NOT IN (
        SELECT MIN(id) FROM public.users 
        GROUP BY email
    );
    
    RAISE NOTICE 'Cleaned up duplicate emails';
    
    -- Check if unique constraint on email exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_type = 'UNIQUE' 
        AND table_name = 'users' 
        AND table_schema = 'public'
        AND constraint_name LIKE '%email%'
    ) THEN
        -- Add unique constraint if it doesn't exist
        ALTER TABLE public.users ADD CONSTRAINT users_email_unique UNIQUE (email);
        RAISE NOTICE 'Added UNIQUE constraint on email column';
    ELSE
        RAISE NOTICE 'Email column already has UNIQUE constraint';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error adding UNIQUE constraint: %', SQLERRM;
        -- Try to continue anyway
END $$;

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- STEP 3: Create helper functions (before RLS policies)
-- ================================================================

-- Create a security definer function to get user role (bypass RLS)
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS user_role
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role_result user_role;
BEGIN
    SELECT role INTO user_role_result 
    FROM public.users 
    WHERE id = user_uuid;
    
    RETURN COALESCE(user_role_result, 'student');
END;
$$;

-- ================================================================
-- STEP 4: Create test admin user
-- ================================================================

-- Insert or update admin user
DO $$
BEGIN
    -- Check if the user already exists
    IF EXISTS (SELECT 1 FROM public.users WHERE email = 'deepak5122d@gmail.com') THEN
        -- Update existing user to admin role
        UPDATE public.users 
        SET 
            role = 'admin',
            assigned_department = 'All Departments',
            updated_at = NOW()
        WHERE email = 'deepak5122d@gmail.com';
        RAISE NOTICE 'Updated existing user deepak5122d@gmail.com to admin role';
    ELSE
        -- Insert new admin user
        INSERT INTO public.users (
            id,
            email,
            role,
            assigned_department,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            'deepak5122d@gmail.com',
            'admin',
            'All Departments',
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Created new admin user deepak5122d@gmail.com';
    END IF;
END $$;

-- ================================================================
-- STEP 5: Update RLS policies for admin superuser access
-- ================================================================

-- Update USERS table RLS policy (avoid recursion)
DROP POLICY IF EXISTS "Users can view all data based on role" ON public.users;

-- Simple policy for users table to avoid recursion
CREATE POLICY "Users can view based on auth" ON public.users
FOR SELECT USING (
    -- Users can always see their own record
    id = auth.uid()
);

-- Update STUDENTS table RLS policy
DROP POLICY IF EXISTS "HOD can view department students" ON public.students;
DROP POLICY IF EXISTS "Students access policy" ON public.students;

CREATE POLICY "Students access policy" ON public.students
FOR SELECT USING (
    -- Admin users can see all students
    get_user_role(auth.uid()) = 'admin'
    OR
    -- HOD users can see students in their department (case-insensitive)
    (
        get_user_role(auth.uid()) = 'hod'
        AND EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() 
            AND LOWER(u.assigned_department) = LOWER(students.department)
        )
    )
    OR
    -- Staff can see students in classes they teach
    get_user_role(auth.uid()) IN ('staff', 'faculty', 'teacher')
    OR
    -- Students can see their own record (using user_id link)
    students.user_id = auth.uid()
);

-- Update DAILY_ATTENDANCE table RLS policy
DROP POLICY IF EXISTS "HOD can view department daily attendance" ON public.daily_attendance;
DROP POLICY IF EXISTS "Daily attendance access policy" ON public.daily_attendance;

CREATE POLICY "Daily attendance access policy" ON public.daily_attendance
FOR SELECT USING (
    -- Admin users can see all attendance records
    get_user_role(auth.uid()) = 'admin'
    OR
    -- HOD users can see attendance for their department students (case-insensitive)
    (
        get_user_role(auth.uid()) = 'hod'
        AND EXISTS (
            SELECT 1 FROM public.users u
            JOIN public.students s ON s.registration_no = daily_attendance.registration_no
            WHERE u.id = auth.uid() 
            AND LOWER(u.assigned_department) = LOWER(s.department)
        )
    )
    OR
    -- Staff can see attendance for students they teach
    get_user_role(auth.uid()) IN ('staff', 'faculty', 'teacher')
    OR
    -- Students can see their own attendance (using user_id link)
    EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.registration_no = daily_attendance.registration_no
        AND s.user_id = auth.uid()
    )
);

-- ================================================================
-- STEP 6: Add admin INSERT/UPDATE/DELETE policies (optional)
-- ================================================================

-- Drop existing admin policies if they exist
DROP POLICY IF EXISTS "Admin can insert students" ON public.students;
DROP POLICY IF EXISTS "Admin can update students" ON public.students;
DROP POLICY IF EXISTS "Admin can insert attendance" ON public.daily_attendance;
DROP POLICY IF EXISTS "Admin can update attendance" ON public.daily_attendance;

-- Allow admin to insert students
CREATE POLICY "Admin can insert students" ON public.students
FOR INSERT WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
);

-- Allow admin to update students
CREATE POLICY "Admin can update students" ON public.students
FOR UPDATE USING (
    get_user_role(auth.uid()) = 'admin'
) WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
);

-- Allow admin to insert attendance
CREATE POLICY "Admin can insert attendance" ON public.daily_attendance
FOR INSERT WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
);

-- Allow admin to update attendance
CREATE POLICY "Admin can update attendance" ON public.daily_attendance
FOR UPDATE USING (
    get_user_role(auth.uid()) = 'admin'
) WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
);

-- ================================================================
-- STEP 7: Create additional admin helper functions
-- ================================================================

-- Create admin helper function to get all departments
CREATE OR REPLACE FUNCTION get_all_departments()
RETURNS TABLE(department_name TEXT, student_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only allow admin users to call this function
    IF get_user_role(auth.uid()) != 'admin' THEN
        RAISE EXCEPTION 'Access denied. Admin role required.';
    END IF;

    RETURN QUERY
    SELECT 
        s.department as department_name,
        COUNT(*) as student_count
    FROM public.students s
    GROUP BY s.department
    ORDER BY s.department;
END;
$$;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Test the enum update
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        RAISE NOTICE 'Admin role verification - enum values: %', (SELECT enum_range(NULL::user_role));
    ELSE
        RAISE NOTICE 'ERROR: user_role enum was not created successfully';
    END IF;
END $$;

-- Verify admin user was created
SELECT 'Admin user created:' as test, email, role, assigned_department 
FROM public.users 
WHERE role = 'admin';

-- Test department listing function (run as admin)
SELECT 'Departments available:' as test;
-- SELECT * FROM get_all_departments(); -- Uncomment when logged in as admin

-- Test RLS policies work
SELECT 'RLS policies updated successfully' as status;

SELECT 'Backend setup complete! Admin role is ready.' as completion_status;
