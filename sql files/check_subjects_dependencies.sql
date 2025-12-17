-- SAFE VERSION: Check dependencies before modifying subjects table

-- Step 1: Check current table structure
SELECT 'Current subjects table structure:' as info;
\d subjects;

-- Step 2: Check what tables reference subjects.subject_code
SELECT 'Tables that reference subjects:' as info;
SELECT 
    tc.table_name AS referencing_table, 
    kcu.column_name AS referencing_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
      AND ccu.table_name = 'subjects'
      AND ccu.column_name = 'subject_code';

-- Step 3: Check if any other tables have subject_code columns
SELECT 'Tables with subject_code columns:' as info;
SELECT table_name, column_name, data_type
FROM information_schema.columns 
WHERE column_name = 'subject_code'
  AND table_name != 'subjects';

-- Step 4: Show current subjects data
SELECT 'Current subjects data (first 10 rows):' as info;
SELECT subject_code, subject_name, department, semester, credits, created_at
FROM subjects 
ORDER BY subject_code 
LIMIT 10;

-- STOP HERE AND REVIEW THE RESULTS BEFORE PROCEEDING
-- Run the above queries first, then proceed with the modification script below only if safe

/*
-- MODIFICATION SCRIPT (run only after reviewing dependencies above)

-- Step 5: Add UUID column
ALTER TABLE subjects ADD COLUMN id UUID DEFAULT gen_random_uuid() NOT NULL;

-- Step 6: Update foreign key tables if they exist
-- Example for attendance table (modify based on actual dependencies found above):
-- ALTER TABLE attendance ADD COLUMN subject_id UUID;
-- UPDATE attendance SET subject_id = s.id FROM subjects s WHERE attendance.subject_code = s.subject_code;
-- ALTER TABLE attendance DROP CONSTRAINT IF EXISTS attendance_subject_code_fkey;
-- ALTER TABLE attendance ADD CONSTRAINT attendance_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

-- Step 7: Drop old primary key and create new one
ALTER TABLE subjects DROP CONSTRAINT subjects_pkey;
ALTER TABLE subjects ADD PRIMARY KEY (id);

-- Step 8: Keep subject_code as unique but not primary
ALTER TABLE subjects ADD CONSTRAINT subjects_subject_code_unique UNIQUE (subject_code);

-- Step 9: Verify changes
\d subjects;
SELECT id, subject_code, subject_name FROM subjects LIMIT 5;
*/
