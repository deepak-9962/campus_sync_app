-- Get all details for user: c2560e45-8d01-41ed-b953-a6abe1d83b77

-- User's main record in users table
SELECT 
    id,
    email,
    name,
    role,
    is_admin,
    assigned_department,
    created_at,
    updated_at
FROM public.users 
WHERE id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';

-- Check if user has student record
SELECT 
    registration_no,
    student_name,
    user_id,
    department,
    semester,
    section,
    email,
    phone,
    gender,
    batch,
    regulation,
    date_of_birth,
    created_at
FROM public.students 
WHERE user_id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';

-- Check if user has staff/faculty record
SELECT 
    id,
    user_id,
    name,
    email,
    department,
    designation,
    is_hod,
    created_at
FROM public.staff 
WHERE user_id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';

-- Check auth.users metadata
SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE id = 'c2560e45-8d01-41ed-b953-a6abe1d83b77';
