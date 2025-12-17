-- Insert test student data for Campus Sync App
-- Run this in your Supabase SQL Editor
-- Updated to handle foreign key constraint properly

-- First, let's check what users exist (optional - for debugging)
-- SELECT id, email FROM auth.users LIMIT 5;

-- Option 1: Insert students with NULL user_id (since it's nullable)
-- This avoids foreign key constraint issues for testing
INSERT INTO students (registration_no, user_id, year_of_joining, current_year_of_study, current_semester, section, department, batch, status) VALUES
('CS21001', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21002', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21003', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21004', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21005', NULL, 2021, 3, 5, 'A', 'Computer Science and Engineering', '2021-2025', 'active'),

('CS21006', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21007', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21008', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21009', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),
('CS21010', NULL, 2021, 3, 5, 'B', 'Computer Science and Engineering', '2021-2025', 'active'),

-- Add some students from different semesters and departments for testing
('CS20001', NULL, 2020, 4, 7, 'A', 'Computer Science and Engineering', '2020-2024', 'active'),
('CS20002', NULL, 2020, 4, 7, 'A', 'Computer Science and Engineering', '2020-2024', 'active'),

('EC21001', NULL, 2021, 3, 5, 'A', 'Electronics and Communication Engineering', '2021-2025', 'active'),
('EC21002', NULL, 2021, 3, 5, 'A', 'Electronics and Communication Engineering', '2021-2025', 'active'),

('ME21001', NULL, 2021, 3, 5, 'A', 'Mechanical Engineering', '2021-2025', 'active'),
('ME21002', NULL, 2021, 3, 5, 'A', 'Mechanical Engineering', '2021-2025', 'active');

-- Alternative Option 2: If you want to link students to existing users
-- First check what users exist and get their IDs:
-- SELECT id, email FROM auth.users;
-- 
-- Then you can update specific students to link them to real users:
-- UPDATE students SET user_id = 'your-actual-user-id-here' WHERE registration_no = 'CS21001';

-- Verify the data was inserted
SELECT 
    registration_no, 
    year_of_joining,
    current_year_of_study,
    current_semester, 
    section,
    department, 
    batch, 
    status 
FROM students 
ORDER BY department, current_semester, section, registration_no;
