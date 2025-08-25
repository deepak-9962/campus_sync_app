-- Check RLS status and policies for students table
-- Run this in Supabase SQL Editor

-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'students';

-- Check existing policies
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'students';

-- If RLS is causing issues, you can temporarily disable it for testing:
-- ALTER TABLE students DISABLE ROW LEVEL SECURITY;

-- Or create a policy to allow all operations:
-- CREATE POLICY "Allow all operations on students" ON students FOR ALL USING (true);
