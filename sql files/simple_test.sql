-- Simple test query to check connection
SELECT 'Connected to database' as status;

-- Check if semester 3 students exist
SELECT COUNT(*) as semester_3_students
FROM students 
WHERE department = 'Computer Science and Engineering' 
  AND current_semester = 3;

-- Check if semester 3 attendance exists
SELECT COUNT(*) as semester_3_attendance_records
FROM attendance a
JOIN students s ON a.registration_no = s.registration_no
WHERE s.department = 'Computer Science and Engineering'
  AND s.current_semester = 3;
