-- Check distinct department names in students table
SELECT DISTINCT department FROM students ORDER BY department;

-- Check semester distribution by exact department name
SELECT department, semester, COUNT(*) as count
FROM students 
GROUP BY department, semester
ORDER BY department, semester;
