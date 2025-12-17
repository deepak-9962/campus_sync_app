-- TARGETED DEBUG: 112 students found but 0 attendance records
-- This will identify why attendance records aren't matching with students

-- ================================================================
-- STEP 1: Verify the 112 students the app found
-- ================================================================
SELECT 'STEP 1: Students found by app logic (should be 112)' as step;

SELECT COUNT(*) as students_found
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%';

-- Show sample of these students
SELECT 'Sample of 112 students:' as info;
SELECT 
    registration_no, 
    student_name, 
    department,
    current_semester
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%'
ORDER BY registration_no
LIMIT 10;

-- ================================================================
-- STEP 2: Check if ANY attendance exists for 2025-09-08
-- ================================================================
SELECT 'STEP 2: Total attendance records for 2025-09-08' as step;

SELECT COUNT(*) as total_attendance_records
FROM public.daily_attendance
WHERE date = '2025-09-08';

-- Show sample attendance records for today
SELECT 'Sample attendance records for 2025-09-08:' as info;
SELECT 
    registration_no,
    is_present,
    'exists in daily_attendance' as status
FROM public.daily_attendance
WHERE date = '2025-09-08'
ORDER BY registration_no
LIMIT 10;

-- ================================================================
-- STEP 3: Check registration number overlap
-- ================================================================
SELECT 'STEP 3: Registration number matching analysis' as step;

-- Check if any of the 112 students have attendance records
SELECT 'Students with attendance on 2025-09-08:' as analysis;
SELECT COUNT(*) as students_with_attendance
FROM public.students s
JOIN public.daily_attendance da ON s.registration_no = da.registration_no
WHERE s.department ILIKE '%computer science%engineering%'
    AND da.date = '2025-09-08';

-- Show students vs attendance registration number samples
SELECT 'Registration number comparison:' as comparison;

-- Sample student registration numbers
SELECT 'Student registration numbers (sample):' as source;
SELECT registration_no, 'from students table' as source
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%'
ORDER BY registration_no
LIMIT 5;

-- Sample attendance registration numbers  
SELECT 'Attendance registration numbers (sample):' as source;
SELECT registration_no, 'from daily_attendance table' as source
FROM public.daily_attendance
WHERE date = '2025-09-08'
ORDER BY registration_no
LIMIT 5;

-- ================================================================
-- STEP 4: Department-specific attendance check
-- ================================================================
SELECT 'STEP 4: Attendance by department for 2025-09-08' as step;

SELECT 
    s.department,
    COUNT(DISTINCT s.registration_no) as total_students,
    COUNT(da.registration_no) as attendance_records,
    SUM(CASE WHEN da.is_present = true THEN 1 ELSE 0 END) as present_count,
    SUM(CASE WHEN da.is_present = false THEN 1 ELSE 0 END) as absent_count
FROM public.students s
LEFT JOIN public.daily_attendance da ON s.registration_no = da.registration_no 
    AND da.date = '2025-09-08'
WHERE s.department ILIKE '%computer science%'
GROUP BY s.department
ORDER BY s.department;

-- ================================================================
-- STEP 5: Find the exact mismatch
-- ================================================================
SELECT 'STEP 5: Find mismatched registration numbers' as step;

-- Students without attendance records
SELECT 'Students WITHOUT attendance on 2025-09-08 (first 10):' as missing;
SELECT 
    s.registration_no,
    s.student_name,
    s.department
FROM public.students s
LEFT JOIN public.daily_attendance da ON s.registration_no = da.registration_no 
    AND da.date = '2025-09-08'
WHERE s.department ILIKE '%computer science%engineering%'
    AND da.registration_no IS NULL
ORDER BY s.registration_no
LIMIT 10;

-- Attendance records not matching any student
SELECT 'Attendance records NOT matching any student (first 10):' as orphaned;
SELECT 
    da.registration_no,
    da.is_present,
    'no matching student' as status
FROM public.daily_attendance da
LEFT JOIN public.students s ON da.registration_no = s.registration_no
WHERE da.date = '2025-09-08'
    AND s.registration_no IS NULL
ORDER BY da.registration_no
LIMIT 10;

-- ================================================================
-- DIAGNOSIS SUMMARY
-- ================================================================
SELECT 'DIAGNOSIS RESULTS:' as summary;
SELECT 'If Step 1 shows 112 students and Step 3 shows 0 matches, then:' as result1;
SELECT '1. Either no attendance was taken for Computer Science students on 2025-09-08' as cause1;
SELECT '2. Or registration numbers don''t match between tables' as cause2;
SELECT '3. Or attendance was taken for different department name' as cause3;

SELECT 'Check Step 4 to see which departments actually have attendance data' as next_step;
