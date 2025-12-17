-- SIMPLE HOD USER CREATION - DIRECT FIX
-- Run these commands one by one if needed

-- 1. Drop the problematic constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS "valid_roles";

-- 2. Add HOD user immediately
INSERT INTO users (id, name, email, role, assigned_department, created_at) 
VALUES (
    '5c0f2db3-2692-429b-8100-e180f5cc617d',
    'Dr.D.C. Jullie Josphine',
    'csehod@kingsedu.ac.in',
    'hod',
    'computer science engineering',
    now()
);

-- 3. Add the constraint back with HOD included
ALTER TABLE users ADD CONSTRAINT valid_roles 
CHECK (role IN ('student', 'admin', 'staff', 'hod'));

-- 4. Add missing column if needed
ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_department TEXT;

-- 5. Update the HOD user's department (in case column was just added)
UPDATE users 
SET assigned_department = 'computer science engineering' 
WHERE email = 'csehod@kingsedu.ac.in' AND role = 'hod';
