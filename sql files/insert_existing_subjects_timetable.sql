-- Insert timetable for existing subjects in the database
-- Using the correct department name "Computer Science" to match existing subjects

-- Clear existing timetable data for Semester 5 CSE
DELETE FROM class_schedule 
WHERE department IN ('Computer Science and Engineering', 'Computer Science') 
  AND semester = 5;

-- Insert complete weekly timetable for Section A
-- Using "Computer Science and Engineering" as department for consistency with app
INSERT INTO class_schedule (
    day_of_week, period_number, start_time, end_time, 
    subject_code, room, faculty_name, batch, 
    department, semester, section
) VALUES

-- MONDAY - Section A
('monday', 1, '9:15 AM', '10:15 AM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('monday', 2, '10:15 AM', '11:15 AM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('monday', 3, '11:30 AM', '12:30 PM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('monday', 4, '12:30 PM', '1:30 PM', 'CS3551', 'C11', 'Mrs.Jasmine Margret J', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
-- Lunch break 1:30-2:15
('monday', 5, '2:15 PM', '3:15 PM', 'CCS341', 'C11', 'Mr.S.Thumilvannan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('monday', 6, '3:15 PM', '4:15 PM', 'CCS335', 'C11', 'Mr.E.Munuswamy', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- TUESDAY - Section A
('tuesday', 1, '9:15 AM', '10:15 AM', 'CCS335', 'C11', 'Mr.E.Munuswamy', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('tuesday', 2, '10:15 AM', '11:15 AM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('tuesday', 3, '11:30 AM', '12:30 PM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('tuesday', 4, '12:30 PM', '1:30 PM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
-- Lunch break 1:30-2:15
('tuesday', 5, '2:15 PM', '3:15 PM', 'CS3551', 'C11', 'Mrs.Jasmine Margret J', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('tuesday', 6, '3:15 PM', '4:15 PM', 'CCS341', 'C11', 'Mr.S.Thumilvannan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- WEDNESDAY - Section A
('wednesday', 1, '9:15 AM', '10:15 AM', 'CS3551', 'C11', 'Mrs.Jasmine Margret J', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('wednesday', 2, '10:15 AM', '11:15 AM', 'CCS341', 'C11', 'Mr.S.Thumilvannan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('wednesday', 3, '11:30 AM', '12:30 PM', 'CCS335', 'C11', 'Mr.E.Munuswamy', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('wednesday', 4, '12:30 PM', '1:30 PM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
-- Lunch break 1:30-2:15
('wednesday', 5, '2:15 PM', '3:15 PM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('wednesday', 6, '3:15 PM', '4:15 PM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- THURSDAY - Section A
('thursday', 1, '9:15 AM', '10:15 AM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('thursday', 2, '10:15 AM', '11:15 AM', 'CS3551', 'C11', 'Mrs.Jasmine Margret J', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('thursday', 3, '11:30 AM', '12:30 PM', 'CCS341', 'C11', 'Mr.S.Thumilvannan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('thursday', 4, '12:30 PM', '1:30 PM', 'CCS335', 'C11', 'Mr.E.Munuswamy', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
-- Lunch break 1:30-2:15
('thursday', 5, '2:15 PM', '3:15 PM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('thursday', 6, '3:15 PM', '4:15 PM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- FRIDAY - Section A
('friday', 1, '9:15 AM', '10:15 AM', 'CCS341', 'C11', 'Mr.S.Thumilvannan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('friday', 2, '10:15 AM', '11:15 AM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('friday', 3, '11:30 AM', '12:30 PM', 'CS3551', 'C11', 'Mrs.Jasmine Margret J', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('friday', 4, '12:30 PM', '1:30 PM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
-- Lunch break 1:30-2:15
('friday', 5, '2:15 PM', '3:15 PM', 'CCS335', 'C11', 'Mr.E.Munuswamy', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('friday', 6, '3:15 PM', '4:15 PM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- SATURDAY - Section A (Limited classes)
('saturday', 1, '9:15 AM', '10:15 AM', 'CS3591', 'C11', 'Mr.S.Kumaresan', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('saturday', 2, '10:15 AM', '11:15 AM', 'CS3501', 'C11', 'Mrs.V.Balammal', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),
('saturday', 3, '11:30 AM', '12:30 PM', 'CB3491', 'C11', 'Mrs.S Ramyadevi', 'CSE-A', 'Computer Science and Engineering', 5, 'A'),

-- Insert timetable for Section B (using room C12)
-- MONDAY - Section B
('monday', 1, '9:15 AM', '10:15 AM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('monday', 2, '10:15 AM', '11:15 AM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('monday', 3, '11:30 AM', '12:30 PM', 'CS3551', 'C12', 'Mrs.Jasmine Margret J', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('monday', 4, '12:30 PM', '1:30 PM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
-- Lunch break 1:30-2:15
('monday', 5, '2:15 PM', '3:15 PM', 'CCS335', 'C12', 'Mr.E.Munuswamy', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('monday', 6, '3:15 PM', '4:15 PM', 'CCS341', 'C12', 'Mr.S.Thumilvannan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),

-- TUESDAY - Section B
('tuesday', 1, '9:15 AM', '10:15 AM', 'CCS341', 'C12', 'Mr.S.Thumilvannan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('tuesday', 2, '10:15 AM', '11:15 AM', 'CCS335', 'C12', 'Mr.E.Munuswamy', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('tuesday', 3, '11:30 AM', '12:30 PM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('tuesday', 4, '12:30 PM', '1:30 PM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
-- Lunch break 1:30-2:15
('tuesday', 5, '2:15 PM', '3:15 PM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('tuesday', 6, '3:15 PM', '4:15 PM', 'CS3551', 'C12', 'Mrs.Jasmine Margret J', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),

-- WEDNESDAY - Section B
('wednesday', 1, '9:15 AM', '10:15 AM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('wednesday', 2, '10:15 AM', '11:15 AM', 'CS3551', 'C12', 'Mrs.Jasmine Margret J', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('wednesday', 3, '11:30 AM', '12:30 PM', 'CCS341', 'C12', 'Mr.S.Thumilvannan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('wednesday', 4, '12:30 PM', '1:30 PM', 'CCS335', 'C12', 'Mr.E.Munuswamy', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
-- Lunch break 1:30-2:15
('wednesday', 5, '2:15 PM', '3:15 PM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('wednesday', 6, '3:15 PM', '4:15 PM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),

-- THURSDAY - Section B
('thursday', 1, '9:15 AM', '10:15 AM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('thursday', 2, '10:15 AM', '11:15 AM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('thursday', 3, '11:30 AM', '12:30 PM', 'CS3551', 'C12', 'Mrs.Jasmine Margret J', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('thursday', 4, '12:30 PM', '1:30 PM', 'CCS341', 'C12', 'Mr.S.Thumilvannan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
-- Lunch break 1:30-2:15
('thursday', 5, '2:15 PM', '3:15 PM', 'CCS335', 'C12', 'Mr.E.Munuswamy', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('thursday', 6, '3:15 PM', '4:15 PM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),

-- FRIDAY - Section B
('friday', 1, '9:15 AM', '10:15 AM', 'CS3551', 'C12', 'Mrs.Jasmine Margret J', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('friday', 2, '10:15 AM', '11:15 AM', 'CCS341', 'C12', 'Mr.S.Thumilvannan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('friday', 3, '11:30 AM', '12:30 PM', 'CCS335', 'C12', 'Mr.E.Munuswamy', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('friday', 4, '12:30 PM', '1:30 PM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
-- Lunch break 1:30-2:15
('friday', 5, '2:15 PM', '3:15 PM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('friday', 6, '3:15 PM', '4:15 PM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),

-- SATURDAY - Section B (Limited classes)
('saturday', 1, '9:15 AM', '10:15 AM', 'CS3501', 'C12', 'Mrs.V.Balammal', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('saturday', 2, '10:15 AM', '11:15 AM', 'CS3591', 'C12', 'Mr.S.Kumaresan', 'CSE-B', 'Computer Science and Engineering', 5, 'B'),
('saturday', 3, '11:30 AM', '12:30 PM', 'CB3491', 'C12', 'Mrs.S Ramyadevi', 'CSE-B', 'Computer Science and Engineering', 5, 'B');

-- Verify the insertion
SELECT 
    day_of_week, 
    COUNT(*) as periods_count,
    section
FROM class_schedule 
WHERE department = 'Computer Science and Engineering' 
  AND semester = 5
GROUP BY day_of_week, section
ORDER BY 
    CASE day_of_week 
        WHEN 'monday' THEN 1 
        WHEN 'tuesday' THEN 2 
        WHEN 'wednesday' THEN 3 
        WHEN 'thursday' THEN 4 
        WHEN 'friday' THEN 5 
        WHEN 'saturday' THEN 6 
    END,
    section;

-- Show subjects being used in timetable
SELECT DISTINCT 
    cs.subject_code,
    cs.faculty_name,
    COUNT(*) as periods_per_week
FROM class_schedule cs
WHERE cs.department = 'Computer Science and Engineering' 
  AND cs.semester = 5
  AND cs.section = 'A'
GROUP BY cs.subject_code, cs.faculty_name
ORDER BY cs.subject_code;
