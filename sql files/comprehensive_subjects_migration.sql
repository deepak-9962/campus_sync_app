-- COMPREHENSIVE MIGRATION: Change subjects primary key from subject_code to UUID
-- This script handles all foreign key dependencies safely

-- Step 1: Add UUID column to subjects table
ALTER TABLE subjects ADD COLUMN id UUID DEFAULT gen_random_uuid() NOT NULL;

-- Step 2: Add subject_id (UUID) columns to all dependent tables
ALTER TABLE class_schedule ADD COLUMN subject_id UUID;
ALTER TABLE attendance_summary ADD COLUMN subject_id UUID;  
ALTER TABLE attendance ADD COLUMN subject_id UUID;

-- Step 3: Populate the new UUID columns with matching UUIDs from subjects
UPDATE class_schedule 
SET subject_id = s.id 
FROM subjects s 
WHERE class_schedule.subject_code = s.subject_code;

UPDATE attendance_summary 
SET subject_id = s.id 
FROM subjects s 
WHERE attendance_summary.subject_code = s.subject_code;

UPDATE attendance 
SET subject_id = s.id 
FROM subjects s 
WHERE attendance.subject_code = s.subject_code;

-- Step 4: Drop existing foreign key constraints
ALTER TABLE class_schedule DROP CONSTRAINT IF EXISTS class_schedule_subject_code_fkey;
ALTER TABLE attendance_summary DROP CONSTRAINT IF EXISTS attendance_summary_subject_code_fkey;
ALTER TABLE attendance DROP CONSTRAINT IF EXISTS attendance_subject_code_fkey;

-- Step 5: Make the new UUID columns NOT NULL (after they're populated)
ALTER TABLE class_schedule ALTER COLUMN subject_id SET NOT NULL;
ALTER TABLE attendance_summary ALTER COLUMN subject_id SET NOT NULL;
ALTER TABLE attendance ALTER COLUMN subject_id SET NOT NULL;

-- Step 6: Drop the old primary key constraint on subjects
ALTER TABLE subjects DROP CONSTRAINT subjects_pkey;

-- Step 7: Add new primary key constraint on subjects.id
ALTER TABLE subjects ADD PRIMARY KEY (id);

-- Step 8: Add new foreign key constraints using UUIDs
ALTER TABLE class_schedule 
    ADD CONSTRAINT class_schedule_subject_id_fkey 
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE;

ALTER TABLE attendance_summary 
    ADD CONSTRAINT attendance_summary_subject_id_fkey 
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE;

ALTER TABLE attendance 
    ADD CONSTRAINT attendance_subject_id_fkey 
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE;

-- Step 9: Keep subject_code as unique but not primary (for backward compatibility)
ALTER TABLE subjects ADD CONSTRAINT subjects_subject_code_unique UNIQUE (subject_code);

-- Step 10: Verify the migration
SELECT 'Migration completed. New subjects structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'subjects' 
ORDER BY ordinal_position;

-- Step 11: Verify foreign key relationships
SELECT 'New foreign key relationships:' as info;
SELECT 
    tc.table_name AS referencing_table, 
    kcu.column_name AS referencing_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
      AND ccu.table_name = 'subjects'
      AND ccu.column_name = 'id';

-- Step 12: Show sample data to verify UUIDs are working
SELECT 'Sample data with new UUIDs:' as info;
SELECT id, subject_code, subject_name, department 
FROM subjects 
ORDER BY subject_code 
LIMIT 5;
