-- Test script for student account linking functionality
-- Run this after running add_student_user_link.sql

-- 0. First, let's check what columns exist in the students table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'students'
ORDER BY ordinal_position;

-- 0.1. Check if user_id column was added successfully
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'students'
AND column_name = 'user_id';

-- 0.2. Check if the linking functions exist
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('link_student_with_user', 'link_my_student_account');

-- 1. Check if we have any students in the database (using correct column names)
SELECT 
    registration_no, 
    department, 
    current_semester,
    section,
    batch,
    status,
    user_id,
    CASE 
        WHEN user_id IS NULL THEN 'Not Linked'
        ELSE 'Linked'
    END as link_status
FROM public.students
ORDER BY registration_no;

-- 2. Check current users (if any)
SELECT 
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at;

-- 3. Example: Link a student manually (replace with actual values)
-- SELECT link_student_with_user('CSE001', 'student1@example.com');

-- 4. Check if the link was successful
SELECT 
    s.registration_no,
    s.department,
    u.email,
    s.user_id
FROM public.students s
LEFT JOIN auth.users u ON s.user_id = u.id
WHERE s.registration_no = 'CSE001';

-- 5. Test the self-linking function (this would be called from the app)
-- SELECT link_my_student_account('CSE002');

-- 6. Add some test students if none exist (using correct column structure)
INSERT INTO public.students (registration_no, year_of_joining, current_year_of_study, current_semester, section, department, batch, status)
VALUES 
    ('TEST001', 2024, 1, 1, 'A', 'Computer Science and Engineering', '2024-2028', 'active'),
    ('TEST002', 2024, 1, 1, 'A', 'Computer Science and Engineering', '2024-2028', 'active'),
    ('TEST003', 2024, 1, 2, 'B', 'Computer Science and Engineering', '2024-2028', 'active')
ON CONFLICT (registration_no) DO NOTHING;

-- 7. Check the newly added students
SELECT 
    registration_no, 
    department, 
    current_semester,
    section,
    batch,
    status,
    user_id,
    CASE 
        WHEN user_id IS NULL THEN 'Not Linked'
        ELSE 'Linked'
    END as link_status
FROM public.students
WHERE registration_no LIKE 'TEST%'
ORDER BY registration_no;

-- 8. Quick test: Try to link a test student account
-- First, let's see if we have any users to link with
SELECT 
    id,
    email,
    created_at
FROM auth.users
LIMIT 5;

-- 9. Test linking function (uncomment when you have a user email)
-- Replace 'your-email@example.com' with an actual user email from step 8
-- SELECT link_student_with_user('TEST001', 'your-email@example.com');

-- 9.1. Test self-linking function (this is what the app will call)
-- SELECT link_my_student_account('TEST001');

-- 9.2. Test getting student info (what the app uses)
-- SELECT * FROM get_my_student_info();

-- 10. After linking, check if it worked
-- SELECT 
--     registration_no,
--     department,
--     current_semester,
--     user_id,
--     CASE 
--         WHEN user_id IS NULL THEN 'Not Linked'
--         ELSE 'Linked'
--     END as link_status
-- FROM public.students
-- WHERE registration_no = 'TEST001';

-- 11. Quick test to verify functions exist
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('link_student_with_user', 'link_my_student_account', 'get_my_student_info')
ORDER BY routine_name;
