-- Timetable Management Permissions Setup
-- This file ensures both Admin and Staff users have full access to timetable management features

-- Enable RLS on class_schedule table (if not already enabled)
ALTER TABLE class_schedule ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admin and Staff can manage timetables" ON class_schedule;
DROP POLICY IF EXISTS "Admin full access to class_schedule" ON class_schedule;
DROP POLICY IF EXISTS "Staff full access to class_schedule" ON class_schedule;
DROP POLICY IF EXISTS "Allow all operations for admin and staff" ON class_schedule;

-- Create comprehensive policy for both Admin and Staff roles
CREATE POLICY "Admin and Staff can manage timetables" ON class_schedule
FOR ALL
TO authenticated
USING (
  -- Allow if user is admin or staff
  auth.jwt() ->> 'role' IN ('admin', 'staff', 'faculty', 'teacher')
  OR
  -- Also check from users table if role not in JWT
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role IN ('admin', 'staff', 'faculty', 'teacher')
  )
)
WITH CHECK (
  -- Same condition for inserts/updates
  auth.jwt() ->> 'role' IN ('admin', 'staff', 'faculty', 'teacher')
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role IN ('admin', 'staff', 'faculty', 'teacher')
  )
);

-- Ensure subjects table also allows access for admin and staff
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin and Staff can manage subjects" ON subjects;

CREATE POLICY "Admin and Staff can manage subjects" ON subjects
FOR ALL
TO authenticated
USING (
  auth.jwt() ->> 'role' IN ('admin', 'staff', 'faculty', 'teacher')
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role IN ('admin', 'staff', 'faculty', 'teacher')
  )
)
WITH CHECK (
  auth.jwt() ->> 'role' IN ('admin', 'staff', 'faculty', 'teacher')
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role IN ('admin', 'staff', 'faculty', 'teacher')
  )
);

-- Allow students to read timetables but not modify them
DROP POLICY IF EXISTS "Students can view timetables" ON class_schedule;

CREATE POLICY "Students can view timetables" ON class_schedule
FOR SELECT
TO authenticated
USING (
  -- Students can only read
  auth.jwt() ->> 'role' = 'student'
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'student'
  )
);

DROP POLICY IF EXISTS "Students can view subjects" ON subjects;

CREATE POLICY "Students can view subjects" ON subjects
FOR SELECT
TO authenticated
USING (true); -- All authenticated users can read subjects

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON class_schedule TO authenticated;
GRANT ALL ON subjects TO authenticated;

-- Verify the policies are in place
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('class_schedule', 'subjects')
ORDER BY tablename, policyname;
