-- QUICK FIX: Find why 112 students have 0 attendance records
-- Based on console: "112 students, 0 present, attendance_taken: false"

-- The app found 112 students but 0 attendance records for 2025-09-08
-- Let's find out why:

-- 1. Confirm the 112 students exist (this should match your app)
SELECT '1. Students found by app pattern:' as test;
SELECT COUNT(*) as student_count
FROM public.students 
WHERE department ILIKE '%computer science%engineering%';

-- 2. Check if these students have ANY attendance records ever
SELECT '2. Any attendance records for these students (any date):' as test;
SELECT COUNT(DISTINCT da.registration_no) as students_with_any_attendance
FROM public.students s
JOIN public.daily_attendance da ON s.registration_no = da.registration_no
WHERE s.department ILIKE '%computer science%engineering%';

-- 3. Check attendance specifically for 2025-09-08
SELECT '3. Attendance for these students on 2025-09-08:' as test;
SELECT COUNT(*) as attendance_records_today
FROM public.students s
JOIN public.daily_attendance da ON s.registration_no = da.registration_no
WHERE s.department ILIKE '%computer science%engineering%'
    AND da.date = '2025-09-08';

-- 4. Check what attendance actually exists for 2025-09-08
SELECT '4. All attendance by department for 2025-09-08:' as test;
SELECT 
    s.department,
    COUNT(*) as attendance_count
FROM public.daily_attendance da
JOIN public.students s ON da.registration_no = s.registration_no
WHERE da.date = '2025-09-08'
GROUP BY s.department
ORDER BY attendance_count DESC;

-- 5. Check if attendance exists but under different department name
SELECT '5. Sample attendance records for 2025-09-08:' as test;
SELECT 
    da.registration_no,
    s.student_name,
    s.department,
    da.is_present
FROM public.daily_attendance da
JOIN public.students s ON da.registration_no = s.registration_no
WHERE da.date = '2025-09-08'
LIMIT 10;

-- EXPECTED RESULTS:
-- Test 1: Should show 112 (matches your app)
-- Test 2: Should show if these students have attendance records at all
-- Test 3: Should show 0 (matches your app) - this is the problem
-- Test 4: Will show which departments DO have attendance for 2025-09-08
-- Test 5: Will show what attendance records actually exist

-- LIKELY CAUSES:
-- A) No attendance taken for Computer Science students on 2025-09-08
-- B) Attendance taken but for different department name (exact match issue)
-- C) Registration number mismatch between tables
