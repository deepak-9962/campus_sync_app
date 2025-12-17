-- HOD Setup Script - Fixed Version
-- Run this step by step if needed

-- 1. Add columns if they don't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'student';
ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_department TEXT;

-- 2. Handle any existing role constraints
DO $$
BEGIN
    -- Try to drop any existing role-related constraints
    EXECUTE 'ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check';
    EXECUTE 'ALTER TABLE users DROP CONSTRAINT IF EXISTS "valid roles"';
    EXECUTE 'ALTER TABLE users DROP CONSTRAINT IF EXISTS valid_roles';
    EXECUTE 'ALTER TABLE users DROP CONSTRAINT IF EXISTS role_check';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Some constraints may not exist, continuing...';
END $$;

-- 3. Create new constraint with HOD role
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'admin', 'staff', 'hod'));

-- 4. Update existing admin users
UPDATE users SET role = 'admin' WHERE is_admin = true;

-- 5. Create department view
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

-- 6. Clean up existing policies
DROP POLICY IF EXISTS "HOD can view department attendance" ON attendance;
DROP POLICY IF EXISTS "Admin can view all attendance" ON attendance;
DROP POLICY IF EXISTS "HOD can view department students" ON students;

-- 7. Create HOD policies
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

CREATE POLICY "Admin can view all attendance" 
ON attendance FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND (users.role = 'admin' OR users.is_admin = true)
    )
);

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

-- 8. Create summary function
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

-- 9. Grant permissions
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;

-- 10. Create indexes
CREATE INDEX IF NOT EXISTS idx_students_department ON students(department);
CREATE INDEX IF NOT EXISTS idx_attendance_date_is_present ON attendance(date, is_present);
CREATE INDEX IF NOT EXISTS idx_users_role_department ON users(role, assigned_department);

-- 11. Add comments
COMMENT ON VIEW department_wise_attendance IS 'Department-wise attendance statistics for HOD dashboard';
COMMENT ON FUNCTION get_department_attendance_summary IS 'Get attendance summary statistics for a specific department';
