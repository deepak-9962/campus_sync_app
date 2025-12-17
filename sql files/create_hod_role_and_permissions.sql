-- HOD Role Creation and Department-wide Attendance Permissions

-- 1. Add HOD role and department assignment to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'student';
ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_department TEXT;

-- 2. Update or create role check constraint to include 'hod'
-- First, drop existing constraint if it exists
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Create new constraint with only essential roles
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'admin', 'staff', 'hod'));

-- Update existing role values if needed
UPDATE users SET role = 'admin' WHERE is_admin = true;

-- 2. Create department_wise_attendance view for HODs
CREATE OR REPLACE VIEW department_wise_attendance AS
SELECT 
    s.department,
    s.semester,
    s.section,
    COUNT(DISTINCT s.registration_no) as total_students,
    COUNT(CASE WHEN a.is_present = true THEN 1 END) as present_count,
    COUNT(CASE WHEN a.is_present = false THEN 1 END) as absent_count,
    ROUND(
        (COUNT(CASE WHEN a.is_present = true THEN 1 END)::DECIMAL / 
         NULLIF(COUNT(a.is_present), 0)) * 100, 2
    ) as attendance_percentage,
    a.date as attendance_date,
    a.period_number,
    a.subject_code
FROM students s
LEFT JOIN attendance a ON s.registration_no = a.registration_no
WHERE a.date IS NOT NULL
GROUP BY s.department, s.semester, s.section, a.date, a.period_number, a.subject_code
ORDER BY s.department, s.semester, s.section, a.date DESC;

-- 3. Create RLS policies for department_wise_attendance

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "HOD can view department attendance" ON attendance;
DROP POLICY IF EXISTS "Admin can view all attendance" ON attendance;
DROP POLICY IF EXISTS "HOD can view department students" ON students;

-- HODs can view only their assigned department's attendance
CREATE POLICY "HOD can view department attendance" 
ON attendance FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'hod'
        AND users.assigned_department = (
            SELECT department FROM students 
            WHERE students.registration_no = attendance.registration_no
        )
    )
);

-- Admin can view all department attendance
CREATE POLICY "Admin can view all attendance" 
ON attendance FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND (users.role = 'admin' OR users.is_admin = true)
    )
);

-- 4. Grant permissions for HOD role on relevant tables

-- HODs can read students data from their department
CREATE POLICY "HOD can view department students" 
ON students FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'hod'
        AND users.assigned_department = students.department
    )
);

-- 5. Create summary statistics function for HODs
CREATE OR REPLACE FUNCTION get_department_attendance_summary(dept_name TEXT)
RETURNS TABLE (
    total_students BIGINT,
    avg_attendance_percentage NUMERIC,
    low_attendance_students BIGINT,
    today_present BIGINT,
    today_absent BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT s.registration_no) as total_students,
        ROUND(AVG(
            CASE 
                WHEN a.is_present = true THEN 100.0
                WHEN a.is_present = false THEN 0.0
                ELSE NULL
            END
        ), 2) as avg_attendance_percentage,
        COUNT(DISTINCT CASE 
            WHEN student_avg.avg_percentage < 75 THEN s.registration_no 
        END) as low_attendance_students,
        COUNT(CASE 
            WHEN a.is_present = true AND a.date = CURRENT_DATE THEN 1 
        END) as today_present,
        COUNT(CASE 
            WHEN a.is_present = false AND a.date = CURRENT_DATE THEN 1 
        END) as today_absent
    FROM students s
    LEFT JOIN attendance a ON s.registration_no = a.registration_no
    LEFT JOIN (
        SELECT 
            registration_no,
            AVG(CASE 
                WHEN is_present = true THEN 100.0
                WHEN is_present = false THEN 0.0
            END) as avg_percentage
        FROM attendance
        GROUP BY registration_no
    ) student_avg ON s.registration_no = student_avg.registration_no
    WHERE s.department = dept_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Sample HOD user creation (replace with actual HOD details)
-- INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'hod.cse@college.edu');
-- INSERT INTO users (id, name, email, role, assigned_department) 
-- VALUES (
--     (SELECT id FROM auth.users WHERE email = 'hod.cse@college.edu'),
--     'Dr. CSE HOD',
--     'hod.cse@college.edu',
--     'hod',
--     'Computer Science Engineering'
-- );

-- 7. Grant execute permission on the function to HODs and admins
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_students_department ON students(department);
CREATE INDEX IF NOT EXISTS idx_attendance_date_is_present ON attendance(date, is_present);
CREATE INDEX IF NOT EXISTS idx_users_role_department ON users(role, assigned_department);

COMMENT ON VIEW department_wise_attendance IS 'Department-wise attendance statistics for HOD dashboard';
COMMENT ON FUNCTION get_department_attendance_summary IS 'Get attendance summary statistics for a specific department';
