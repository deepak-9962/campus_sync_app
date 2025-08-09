-- Update existing subjects to have correct department name
-- This will fix the mismatch between subject department and what the app expects

-- First, let's see what we have currently
SELECT subject_code, subject_name, department, semester 
FROM subjects 
WHERE semester = 5 
ORDER BY subject_code;

-- Update the department name for all semester 5 subjects
UPDATE subjects 
SET department = 'Computer Science and Engineering'
WHERE department = 'Computer Science' 
  AND semester = 5;

-- Verify the update
SELECT subject_code, subject_name, department, semester 
FROM subjects 
WHERE semester = 5 
ORDER BY subject_code;

-- Optional: If you want to update ALL Computer Science subjects (not just semester 5)
-- Uncomment the following lines:

-- UPDATE subjects 
-- SET department = 'Computer Science and Engineering'
-- WHERE department = 'Computer Science';

-- Final verification - show all subjects with the corrected department
SELECT 
    subject_code,
    subject_name, 
    department,
    semester,
    faculty_name
FROM subjects 
WHERE department = 'Computer Science and Engineering'
  AND semester = 5
ORDER BY subject_code;
