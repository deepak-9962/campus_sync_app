-- Simple script to check attendance data and table structures

-- 1. Check what tables exist and their columns
SELECT 'Tables related to attendance:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('attendance', 'daily_attendance', 'overall_attendance_summary', 'students')
  AND table_type = 'BASE TABLE';

-- 2. Check recent attendance data
SELECT 'Recent attendance data (last 7 days):' as info;
SELECT 
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

-- 3. Check what's currently in overall_attendance_summary
SELECT 'Current overall_attendance_summary data:' as info;
SELECT department, semester, COUNT(*) as students, ROUND(AVG(overall_percentage), 2) as avg_attendance
FROM overall_attendance_summary
WHERE department ILIKE '%computer science%engineering%'
GROUP BY department, semester
ORDER BY semester;

-- 4. Check what's in daily_attendance for today
SELECT 'Today daily_attendance data:' as info;
SELECT DATE(date) as date, COUNT(*) as records
FROM daily_attendance
WHERE DATE(date) = CURRENT_DATE
GROUP BY DATE(date);

-- 5. Check if there's attendance data for semester 3 today
SELECT 'Semester 3 attendance today:' as info;
SELECT 
  a.registration_no,
  s.current_semester,
  s.department,
  COUNT(*) as periods_today,
  COUNT(CASE WHEN a.is_present THEN 1 END) as attended_today
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE DATE(a.date) = CURRENT_DATE
  AND s.current_semester = 3
  AND s.department ILIKE '%computer science%engineering%'
GROUP BY a.registration_no, s.current_semester, s.department
ORDER BY a.registration_no
LIMIT 10;
