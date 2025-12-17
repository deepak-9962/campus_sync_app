-- HOD Dashboard Database Function for Department Summary
-- This function provides optimized department-wide attendance analytics

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
BEGIN
    -- Get total students in department
    SELECT COUNT(*) INTO student_count
    FROM students 
    WHERE department ILIKE dept_name;
    
    -- Get today's attendance summary from daily_attendance
    SELECT 
        COUNT(CASE WHEN attended_periods > 0 THEN 1 END),
        COUNT(CASE WHEN attended_periods = 0 AND total_periods > 0 THEN 1 END)
    INTO present_count, absent_count
    FROM daily_attendance da
    WHERE da.date = today_date 
    AND da.department ILIKE dept_name;
    
    -- Get overall attendance average from summary table
    SELECT AVG(overall_percentage) INTO avg_attendance_val
    FROM overall_attendance_summary oas
    WHERE oas.department ILIKE dept_name;
    
    -- Get count of students with low attendance (below 75%)
    SELECT COUNT(*) INTO low_attendance_count
    FROM overall_attendance_summary oas
    WHERE oas.department ILIKE dept_name
    AND oas.overall_percentage < 75.0;
    
    -- Return the results
    RETURN QUERY SELECT 
        student_count,
        COALESCE(avg_attendance_val, 0.0),
        COALESCE(low_attendance_count, 0),
        COALESCE(present_count, 0),
        COALESCE(absent_count, 0);
        
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to authenticated users (HODs can access this function)
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;

-- Test the function (uncomment to test)
-- SELECT * FROM get_department_attendance_summary('Computer Science');
