-- TEMPORARY FIX for immediate testing
-- This script temporarily disables RLS to test if that's the root cause
-- DO NOT USE IN PRODUCTION - This is for diagnostic purposes only

-- Step 1: Check current RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'daily_attendance';

-- Step 2: Temporarily disable RLS for testing
-- CAUTION: This removes all security restrictions
ALTER TABLE public.daily_attendance DISABLE ROW LEVEL SECURITY;

-- Step 3: Test query that HOD service is trying to run
SELECT 
    COUNT(*) as total_attendance_records,
    SUM(CASE WHEN is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.daily_attendance 
WHERE date = CURRENT_DATE;

-- Step 4: Test department-specific query
SELECT 
    s.department,
    COUNT(da.id) as attendance_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent
FROM public.daily_attendance da
JOIN public.students s ON s.registration_no = da.registration_no
WHERE da.date = CURRENT_DATE
    AND s.department ILIKE '%Computer Science%'
GROUP BY s.department;

-- IMPORTANT: Re-enable RLS after testing
-- ALTER TABLE public.daily_attendance ENABLE ROW LEVEL SECURITY;

-- If the above queries return data, then RLS is the issue
-- Apply the proper fix from hod_daily_attendance_rls_fix.sql
