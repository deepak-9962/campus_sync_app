-- Quick test to insert a few students and verify
-- Run this in Supabase SQL Editor

-- First check if table exists and is empty
SELECT COUNT(*) as total_students FROM students;

-- Insert a few test students
INSERT INTO students (registration_no, user_id, year_of_joining, current_year_of_study, current_semester, section, department, batch, status) VALUES
('CS21001', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21002', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21003', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21006', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21007', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active');

-- Verify the data was inserted
SELECT * FROM students ORDER BY registration_no;
