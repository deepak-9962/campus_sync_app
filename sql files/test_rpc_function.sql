-- Test the get_department_attendance_summary RPC function directly
-- Run this in Supabase SQL Editor to isolate the issue

-- Step 1: Test the function with your exact parameters
SELECT * FROM get_department_attendance_summary('CSE', '2025-09-08');

-- Step 2: Alternative test with full department name (if CSE doesn't work)
SELECT * FROM get_department_attendance_summary('Computer Science and Engineering', '2025-09-08');

-- Step 3: Check if the function exists at all
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname = 'get_department_attendance_summary';

-- Step 4: Test the underlying tables directly (without RLS context)
-- Check attendance data exists
SELECT 
    da.date,
    da.registration_no,
    da.is_present,
    s.student_name,
    s.department
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
    AND s.department ILIKE '%CSE%' OR s.department ILIKE '%Computer Science%'
LIMIT 10;

-- Step 5: Count total records by department
SELECT 
    s.department,
    COUNT(*) as total_attendance_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = '2025-09-08'
GROUP BY s.department
ORDER BY s.department;

-- Expected Results:
-- - Function should return attendance summary with proper counts
-- - If it returns zeros, the issue is in RLS policies or function logic
-- - If the direct table query works but function doesn't, it's an RLS issue
