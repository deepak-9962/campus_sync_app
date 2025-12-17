-- Insert semester 5 subjects for Computer Science and Engineering
-- This script adds all the subjects you specified

INSERT INTO subjects (subject_code, subject_name, department, semester, credits, faculty_name) VALUES
('CS3591', 'Computer Networks', 'Computer Science and Engineering', 5, 3, 'Mr.S.Kumaresan'),
('CS3501', 'Compiler Design', 'Computer Science and Engineering', 5, 3, 'Mrs.V.Balammal'),
('CB3491', 'Cryptography and Cyber Security', 'Computer Science and Engineering', 5, 3, 'Mrs.S Ramyadevi'),
('CS3551', 'Distributed Computing', 'Computer Science and Engineering', 5, 3, 'Mrs.Jasmine Margret J'),
('CCS341', 'Data Warehousing', 'Computer Science and Engineering', 5, 3, 'Mr.S.Thumilvannan'),
('CCS335', 'Cloud Computing', 'Computer Science and Engineering', 5, 3, 'Mr.E.Munuswamy')
ON CONFLICT (subject_code, department, semester) 
DO UPDATE SET 
    subject_name = EXCLUDED.subject_name,
    faculty_name = EXCLUDED.faculty_name;

-- Also insert the faculty information into a faculty table if it exists
-- Note: Adjust this based on your actual faculty table structure
-- INSERT INTO faculty (name, department) VALUES
-- ('Mr.S.Kumaresan', 'Computer Science and Engineering'),
-- ('Mrs.V.Balammal', 'Computer Science and Engineering'),
-- ('Mrs.S Ramyadevi', 'Computer Science and Engineering'),
-- ('Mrs.Jasmine Margret J', 'Computer Science and Engineering'),
-- ('Mr.S.Thumilvannan', 'Computer Science and Engineering'),
-- ('Mr.E.Munuswamy', 'Computer Science and Engineering')
-- ON CONFLICT (name) DO NOTHING;
