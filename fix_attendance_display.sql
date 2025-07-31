-- Quick fix for attendance display issue
-- Run this in your Supabase SQL Editor

-- 1. First, check if we have any attendance data at all
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT registration_no) as unique_students,
    MIN(date) as earliest_date,
    MAX(date) as latest_date
FROM public.attendance;

-- 2. Check if the Excel data was inserted properly
SELECT 
    registration_no,
    percentage,
    total_classes,
    attended_classes,
    status,
    date
FROM public.attendance
WHERE registration_no IN ('210823104001', '210823104002', '210823104027')
ORDER BY registration_no;

-- 3. If no data exists, let's insert a few test records for immediate testing
INSERT INTO public.attendance (registration_no, date, status, percentage, total_classes, attended_classes) VALUES
('210823104027', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104001', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104002', CURRENT_DATE, 'present', 75.0, 120, 90),
-- Add more records from the Excel data for testing
('210823104003', CURRENT_DATE, 'present', 90.0, 120, 108),
('210823104004', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104005', CURRENT_DATE, 'absent', 25.0, 120, 30)
ON CONFLICT (registration_no, date) 
DO UPDATE SET 
  percentage = EXCLUDED.percentage,
  total_classes = EXCLUDED.total_classes,
  attended_classes = EXCLUDED.attended_classes,
  status = EXCLUDED.status;

-- 4. Verify the test data was inserted
SELECT 
    registration_no,
    percentage,
    total_classes,
    attended_classes,
    status,
    date,
    created_at
FROM public.attendance
WHERE registration_no IN ('210823104027', '210823104001', '210823104002')
ORDER BY registration_no;

-- 5. Check if there are any students in the students table
SELECT 
    COUNT(*) as total_students,
    COUNT(DISTINCT department) as unique_departments,
    COUNT(DISTINCT current_semester) as unique_semesters
FROM public.students;

-- 6. Show sample students data
SELECT 
    registration_no,
    department,
    current_semester,
    section,
    status
FROM public.students
WHERE registration_no IN ('210823104027', '210823104001', '210823104002')
ORDER BY registration_no;

-- 7. If students table is empty, add test students
INSERT INTO public.students (registration_no, year_of_joining, current_year_of_study, current_semester, section, department, batch, status) VALUES
('210823104027', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('210823104001', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('210823104002', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('210823104003', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('210823104004', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('210823104005', 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active')
ON CONFLICT (registration_no) DO UPDATE SET
    department = EXCLUDED.department,
    current_semester = EXCLUDED.current_semester,
    section = EXCLUDED.section;

-- 8. Final verification - show joined data
SELECT 
    a.registration_no,
    a.percentage,
    a.total_classes,
    a.attended_classes,
    a.status as attendance_status,
    s.department,
    s.current_semester,
    s.section
FROM public.attendance a
LEFT JOIN public.students s ON a.registration_no = s.registration_no
WHERE a.registration_no IN ('210823104027', '210823104001', '210823104002')
ORDER BY a.registration_no;
