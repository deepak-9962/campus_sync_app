-- Check if 3rd semester attendance exists in raw attendance table
SELECT 'Raw attendance table' as source, 
       department, 
       COUNT(DISTINCT registration_no) as students,
       COUNT(*) as total_records,
       DATE(date) as date
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE s.current_semester = 3
  AND (s.department ILIKE '%computer science%engineering%' 
       OR a.department ILIKE '%computer science%engineering%')
GROUP BY department, DATE(date)
ORDER BY date DESC
LIMIT 10;

-- Also check what's in overall_attendance_summary for comparison
SELECT 'Summary table' as source,
       department,
       semester,
       COUNT(*) as students
FROM overall_attendance_summary
WHERE semester = 3
  AND department ILIKE '%computer science%engineering%'
GROUP BY department, semester;
