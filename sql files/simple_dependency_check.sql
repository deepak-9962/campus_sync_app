-- STEP 1: Check dependencies BEFORE modifying subjects table

-- Check current table structure
SELECT 'Current subjects table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'subjects' 
ORDER BY ordinal_position;

-- Check what tables reference subjects.subject_code
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

-- Check if any other tables have subject_code columns
SELECT 'Tables with subject_code columns:' as info;
SELECT table_name, column_name, data_type
FROM information_schema.columns 
WHERE column_name = 'subject_code';

-- Show current subjects data
SELECT 'Current subjects data (first 5 rows):' as info;
SELECT subject_code, subject_name, department, semester, credits
FROM subjects 
ORDER BY subject_code 
LIMIT 5;
