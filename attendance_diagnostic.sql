-- Diagnostic script to check attendance data and fix duplicates
-- Run this in your Supabase SQL Editor

-- 1. Check if attendance table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'attendance'
ORDER BY ordinal_position;

-- 2. Count total attendance records
SELECT COUNT(*) as total_attendance_records FROM public.attendance;

-- 3. Check for duplicate registration_no + date combinations
SELECT 
    registration_no,
    date,
    COUNT(*) as duplicate_count
FROM public.attendance
GROUP BY registration_no, date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, registration_no;

-- 4. Show sample attendance data
SELECT 
    registration_no,
    date,
    percentage,
    total_classes,
    attended_classes,
    status,
    created_at
FROM public.attendance
ORDER BY registration_no
LIMIT 10;

-- 5. Check which registration numbers have attendance data
SELECT DISTINCT registration_no 
FROM public.attendance 
ORDER BY registration_no;

-- 6. Check if there are any attendance records for today
SELECT 
    registration_no,
    percentage,
    total_classes,
    attended_classes,
    status
FROM public.attendance
WHERE date = CURRENT_DATE
ORDER BY registration_no
LIMIT 20;

-- 7. Check if there are any attendance records at all
SELECT 
    COUNT(*) as total_records,
    MIN(date) as earliest_date,
    MAX(date) as latest_date,
    COUNT(DISTINCT registration_no) as unique_students
FROM public.attendance;

-- 8. Clean up duplicates if they exist (REMOVE OLDER DUPLICATES)
-- This will keep the latest record for each registration_no + date combination
DELETE FROM public.attendance 
WHERE id NOT IN (
    SELECT DISTINCT ON (registration_no, date) id
    FROM public.attendance
    ORDER BY registration_no, date, created_at DESC
);

-- 9. Verify duplicates are gone
SELECT 
    registration_no,
    date,
    COUNT(*) as duplicate_count
FROM public.attendance
GROUP BY registration_no, date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, registration_no;

-- 10. Final count after cleanup
SELECT COUNT(*) as total_attendance_records_after_cleanup FROM public.attendance;
