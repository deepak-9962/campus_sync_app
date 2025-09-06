-- Check all students by semester in the students table
SELECT semester, COUNT(*) as student_count, department
FROM students 
WHERE department ILIKE '%computer%science%'
GROUP BY semester, department
ORDER BY semester;

-- Check if semester 3 students have any attendance records at all
SELECT 'Students in semester 3:' as info;
SELECT COUNT(*) FROM students WHERE semester = 3 AND department ILIKE '%computer%science%';

SELECT 'Attendance records for semester 3 students:' as info;
SELECT COUNT(DISTINCT a.registration_no) as students_with_attendance
FROM students s
JOIN attendance a ON s.registration_no = a.registration_no
WHERE s.semester = 3 AND s.department ILIKE '%computer%science%';

-- Let's see which semesters actually have attendance taken
SELECT 'Attendance by semester:' as info;
SELECT s.semester, COUNT(DISTINCT a.registration_no) as students_with_attendance, COUNT(a.id) as total_attendance_records
FROM students s
JOIN attendance a ON s.registration_no = a.registration_no
WHERE s.department ILIKE '%computer%science%'
GROUP BY s.semester
ORDER BY s.semester;
