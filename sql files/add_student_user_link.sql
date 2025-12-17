-- Add user_id column to students table to link with authenticated users
-- Run this SQL script in your Supabase SQL editor

-- 1. Add user_id column to students table
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 2. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_students_user_id ON public.students(user_id);

-- 3. Update RLS policies to allow students to see their own data
DROP POLICY IF EXISTS "Students can view their own data" ON public.students;
CREATE POLICY "Students can view their own data" ON public.students
    FOR SELECT TO authenticated 
    USING (user_id = auth.uid() OR true); -- Keep allowing all reads for now

-- 4. Add policy for updating user_id (admin/faculty only)
DROP POLICY IF EXISTS "Faculty can update student user_id" ON public.students;
CREATE POLICY "Faculty can update student user_id" ON public.students
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid() AND (users.role = 'faculty' OR users.is_admin = true)
        )
    );

-- 5. Create function to link student with user account
CREATE OR REPLACE FUNCTION link_student_with_user(
    student_registration_no TEXT,
    user_email TEXT
) RETURNS boolean AS $$
DECLARE
    user_record UUID;
BEGIN
    -- Find user by email
    SELECT id INTO user_record 
    FROM auth.users 
    WHERE email = user_email;
    
    IF user_record IS NULL THEN
        RAISE EXCEPTION 'User with email % not found', user_email;
    END IF;
    
    -- Check if student exists by registration number
    IF NOT EXISTS (
        SELECT 1 FROM public.students 
        WHERE registration_no = student_registration_no
    ) THEN
        RAISE EXCEPTION 'Student with registration number % not found', student_registration_no;
    END IF;
    
    -- Update student record with user_id
    UPDATE public.students 
    SET user_id = user_record 
    WHERE registration_no = student_registration_no;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION link_student_with_user(TEXT, TEXT) TO authenticated;

-- 7. Create function for students to link their own account
CREATE OR REPLACE FUNCTION link_my_student_account(
    student_registration_no TEXT
) RETURNS boolean AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get current user ID
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Check if student exists by registration number
    IF NOT EXISTS (
        SELECT 1 FROM public.students 
        WHERE registration_no = student_registration_no
    ) THEN
        RAISE EXCEPTION 'Student with registration number % not found', student_registration_no;
    END IF;
    
    -- Check if this student is already linked to another user
    IF EXISTS (
        SELECT 1 FROM public.students 
        WHERE registration_no = student_registration_no 
        AND user_id IS NOT NULL 
        AND user_id != current_user_id
    ) THEN
        RAISE EXCEPTION 'This student account is already linked to another user';
    END IF;
    
    -- Check if current user is already linked to another student
    IF EXISTS (
        SELECT 1 FROM public.students 
        WHERE user_id = current_user_id 
        AND registration_no != student_registration_no
    ) THEN
        RAISE EXCEPTION 'Your account is already linked to another student record';
    END IF;
    
    -- Update student record with current user_id
    UPDATE public.students 
    SET user_id = current_user_id 
    WHERE registration_no = student_registration_no;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION link_my_student_account(TEXT) TO authenticated;

-- 9. Create function to get student info by user_id (for Flutter app)
CREATE OR REPLACE FUNCTION get_my_student_info() 
RETURNS TABLE (
    registration_no TEXT,
    department TEXT,
    current_semester INTEGER,
    section TEXT,
    batch TEXT,
    status TEXT,
    year_of_joining INTEGER,
    current_year_of_study INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.registration_no,
        s.department,
        s.current_semester,
        s.section,
        s.batch,
        s.status,
        s.year_of_joining,
        s.current_year_of_study
    FROM public.students s
    WHERE s.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Grant execute permission for the new function
GRANT EXECUTE ON FUNCTION get_my_student_info() TO authenticated;

-- Example usage:
-- To link a student account manually (admin/faculty):
-- SELECT link_student_with_user('CSE001', 'student@example.com');

-- For students to link their own account:
-- SELECT link_my_student_account('CSE001');
