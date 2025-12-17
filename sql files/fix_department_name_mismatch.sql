-- Fix department name mismatch between HOD user and summary tables
-- The HOD user has "computer science engineering" but data is stored as "computer science and engineering"

-- Option 1: Update the HOD user's department to match the data
UPDATE users 
SET department = 'computer science and engineering'
WHERE role = 'hod' AND department = 'computer science engineering';

-- Option 2: Alternative - Update all data to use "computer science engineering" (without "and")
-- Uncomment these if you prefer to change the data instead:

-- UPDATE students 
-- SET department = 'computer science engineering'
-- WHERE department = 'computer science and engineering';

-- UPDATE overall_attendance_summary 
-- SET department = 'computer science engineering'
-- WHERE department = 'computer science and engineering';

-- UPDATE daily_attendance 
-- SET department = 'computer science engineering'
-- WHERE department = 'computer science and engineering';

-- UPDATE attendance 
-- SET department = 'computer science engineering'
-- WHERE department = 'computer science and engineering';

-- Check the results
SELECT 'HOD user department:' as check_type, department, count(*) 
FROM users 
WHERE role = 'hod' 
GROUP BY department

UNION ALL

SELECT 'Summary table departments:' as check_type, department, count(*) 
FROM overall_attendance_summary 
GROUP BY department

UNION ALL

SELECT 'Daily attendance departments:' as check_type, department, count(*) 
FROM daily_attendance 
GROUP BY department;
