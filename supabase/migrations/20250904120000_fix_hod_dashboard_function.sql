-- Fix the HOD dashboard function to work with correct table structure

-- First, drop the existing function
DROP FUNCTION IF EXISTS get_department_attendance_summary(TEXT);

-- Create the function with correct return type and structure
CREATE OR REPLACE FUNCTION get_department_attendance_summary(dept_name TEXT)
RETURNS TABLE(
    total_students INTEGER,
    avg_attendance NUMERIC,
    low_attendance_students INTEGER,
    today_present INTEGER,
    today_absent INTEGER
) AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    student_count INTEGER;
    present_count INTEGER;
    absent_count INTEGER;
    avg_attendance_val NUMERIC;
    low_attendance_count INTEGER;
    dept_students TEXT[];
BEGIN
    -- Get total students in department and their registration numbers
    SELECT 
        COUNT(*),
        ARRAY_AGG(registration_no)
    INTO student_count, dept_students
    FROM students 
    WHERE department ILIKE dept_name OR department ILIKE REPLACE(dept_name, ' ', '%');
    
    -- Get today's attendance summary from daily_attendance
    -- We need to join with students to filter by department
    SELECT 
        COUNT(CASE WHEN da.is_present THEN 1 END),
        COUNT(CASE WHEN NOT da.is_present THEN 1 END)
    INTO present_count, absent_count
    FROM daily_attendance da
    JOIN students s ON da.registration_no = s.registration_no
    WHERE da.date = today_date 
    AND (s.department ILIKE dept_name OR s.department ILIKE REPLACE(dept_name, ' ', '%'));
    
    -- Get overall attendance average from summary table
    SELECT AVG(overall_percentage) INTO avg_attendance_val
    FROM overall_attendance_summary oas
    WHERE oas.department ILIKE dept_name OR oas.department ILIKE REPLACE(dept_name, ' ', '%');
    
    -- Get count of students with low attendance (below 75%)
    SELECT COUNT(*) INTO low_attendance_count
    FROM overall_attendance_summary oas
    WHERE (oas.department ILIKE dept_name OR oas.department ILIKE REPLACE(dept_name, ' ', '%'))
    AND oas.overall_percentage < 75.0;
    
    -- Return the results
    RETURN QUERY SELECT 
        COALESCE(student_count, 0),
        COALESCE(avg_attendance_val, 0.0),
        COALESCE(low_attendance_count, 0),
        COALESCE(present_count, 0),
        COALESCE(absent_count, 0);
        
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;
