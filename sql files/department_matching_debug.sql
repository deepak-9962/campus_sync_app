-- DEPARTMENT NAME MATCHING DEBUG
-- This script helps identify department name mismatches

-- ================================================================
-- Check HOD's assigned department
-- ================================================================
SELECT 'HOD assigned department:' as info;
SELECT 
    email,
    assigned_department,
    department as old_dept_column
FROM public.users 
WHERE email = 'csehod@kingsedu.ac.in';

-- ================================================================
-- Check all unique department names in students table
-- ================================================================
SELECT 'All department names in students table:' as info;
SELECT 
    department,
    COUNT(*) as student_count
FROM public.students
GROUP BY department
ORDER BY department;

-- ================================================================
-- Test different pattern matching approaches
-- ================================================================
SELECT 'Pattern matching tests:' as info;

-- Test 1: Exact match with HOD's assigned_department
SELECT 'Test 1 - Exact match:' as test;
SELECT COUNT(*) as matching_students
FROM public.students s
JOIN public.users u ON u.assigned_department = s.department
WHERE u.email = 'csehod@kingsedu.ac.in';

-- Test 2: App's current pattern (computer science + engineering)
SELECT 'Test 2 - App pattern (%computer science%engineering%):' as test;
SELECT COUNT(*) as matching_students
FROM public.students s
WHERE s.department ILIKE '%computer science%engineering%';

-- Test 3: Simpler computer science pattern
SELECT 'Test 3 - Simple pattern (%computer science%):' as test;
SELECT COUNT(*) as matching_students
FROM public.students s
WHERE s.department ILIKE '%computer science%';

-- Test 4: CSE pattern
SELECT 'Test 4 - CSE pattern (%cse%):' as test;
SELECT COUNT(*) as matching_students
FROM public.students s
WHERE s.department ILIKE '%cse%';

-- ================================================================
-- Show actual department names that contain "computer"
-- ================================================================
SELECT 'Departments containing "computer":' as info;
SELECT 
    department,
    COUNT(*) as student_count
FROM public.students
WHERE department ILIKE '%computer%'
GROUP BY department
ORDER BY department;

-- ================================================================
-- Recommended fix based on results
-- ================================================================
SELECT 'RECOMMENDATIONS:' as title;
SELECT '1. Check if HOD assigned_department exactly matches students department' as rec1;
SELECT '2. If no exact match, update either HOD assigned_department or fix pattern matching' as rec2;
SELECT '3. Most common fixes:' as rec3;
SELECT '   - Update HOD: UPDATE users SET assigned_department = ''[exact department name]'' WHERE email = ''csehod@kingsedu.ac.in'';' as fix1;
SELECT '   - Or fix app pattern matching to match your actual department names' as fix2;
