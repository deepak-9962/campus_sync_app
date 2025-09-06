-- Modify subjects table to use UUID primary key instead of subject_code

-- Step 1: Add a new UUID column
ALTER TABLE subjects ADD COLUMN id UUID DEFAULT gen_random_uuid();

-- Step 2: Update any foreign key references (if they exist)
-- Check what tables reference subjects.subject_code
SELECT 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
      AND ccu.table_name='subjects';

-- Step 3: If there are foreign key constraints, we need to handle them
-- Example: If attendance table references subject_code, add subject_id column
-- ALTER TABLE attendance ADD COLUMN subject_id UUID;
-- UPDATE attendance SET subject_id = s.id FROM subjects s WHERE attendance.subject_code = s.subject_code;

-- Step 4: Drop the old primary key constraint
ALTER TABLE subjects DROP CONSTRAINT subjects_pkey;

-- Step 5: Add the new primary key
ALTER TABLE subjects ADD PRIMARY KEY (id);

-- Step 6: Make subject_code non-unique (optional, or keep it as unique constraint)
-- If you want to keep subject_code unique but not primary:
ALTER TABLE subjects ADD CONSTRAINT subjects_subject_code_unique UNIQUE (subject_code);

-- Step 7: Verify the changes
SELECT 'New subjects table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'subjects' 
ORDER BY ordinal_position;

-- Step 8: Show sample data
SELECT 'Sample subjects data:' as info;
SELECT id, subject_code, subject_name, department, semester, credits 
FROM subjects 
ORDER BY subject_code 
LIMIT 5;
