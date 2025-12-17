-- Refresh summary tables to include recent attendance data

-- First, check table structures
SELECT 'daily_attendance table structure:' as info;
\d daily_attendance;

SELECT 'overall_attendance_summary table structure:' as info;
\d overall_attendance_summary;

-- Check what's in the raw attendance table for today
SELECT 'Recent attendance data:' as info, 
       DATE(a.date) as attendance_date,
       s.department,
       s.current_semester as semester,
       COUNT(DISTINCT a.registration_no) as students_with_attendance,
       COUNT(*) as total_attendance_records
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE a.date >= CURRENT_DATE - INTERVAL '7 days'
  AND s.department ILIKE '%computer science%engineering%'
GROUP BY DATE(a.date), s.department, s.current_semester
ORDER BY attendance_date DESC, semester;

-- Refresh daily_attendance summary for today
INSERT INTO daily_attendance (
  date, registration_no, 
  total_periods, attended_periods, attendance_percentage, is_present, last_updated
)
SELECT 
  DATE(a.date) as date,
  a.registration_no,
  COUNT(*) as total_periods,
  COUNT(CASE WHEN a.is_present THEN 1 END) as attended_periods,
  ROUND(
    (COUNT(CASE WHEN a.is_present THEN 1 END) * 100.0 / COUNT(*)), 2
  ) as attendance_percentage,
  (COUNT(CASE WHEN a.is_present THEN 1 END) > 0) as is_present,
  NOW() as last_updated
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.department ILIKE '%computer science%engineering%'
GROUP BY DATE(a.date), a.registration_no
ON CONFLICT (date, registration_no) 
DO UPDATE SET
  total_periods = EXCLUDED.total_periods,
  attended_periods = EXCLUDED.attended_periods,
  attendance_percentage = EXCLUDED.attendance_percentage,
  is_present = EXCLUDED.is_present,
  last_updated = EXCLUDED.last_updated;

-- Refresh overall_attendance_summary
INSERT INTO overall_attendance_summary (
  registration_no, department, semester, section,
  total_periods, attended_periods, overall_percentage, last_updated
)
SELECT 
  a.registration_no,
  COALESCE(s.department, 'computer science and engineering') as department,
  s.current_semester as semester,
  s.section,
  COUNT(*) as total_periods,
  COUNT(CASE WHEN a.is_present THEN 1 END) as attended_periods,
  ROUND(
    (COUNT(CASE WHEN a.is_present THEN 1 END) * 100.0 / COUNT(*)), 2
  ) as overall_percentage,
  NOW() as last_updated
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE s.department ILIKE '%computer science%engineering%'
GROUP BY a.registration_no, s.department, s.current_semester, s.section
ON CONFLICT (registration_no) 
DO UPDATE SET
  total_periods = EXCLUDED.total_periods,
  attended_periods = EXCLUDED.attended_periods,
  overall_percentage = EXCLUDED.overall_percentage,
  department = EXCLUDED.department,
  semester = EXCLUDED.semester,
  section = EXCLUDED.section,
  last_updated = EXCLUDED.last_updated;

-- Show updated summary
SELECT 'Updated summary:' as info,
       department,
       semester,
       COUNT(*) as students,
       ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, semester
ORDER BY semester;
