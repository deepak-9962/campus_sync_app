-- Fix HOD Dashboard to distinguish between "Absent" and "N/A" (Not Applicable)
-- This prevents students whose attendance wasn't taken from appearing as "Absent"

-- Drop existing function
DROP FUNCTION IF EXISTS get_department_attendance_summary(TEXT);

-- Create improved function that returns N/A status for students without attendance records
CREATE OR REPLACE FUNCTION get_department_attendance_today(p_department_name TEXT, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    registration_no TEXT,
    student_name TEXT,
    semester INTEGER,
    section TEXT,
    status TEXT,  -- Can be 'Present', 'Absent', or 'N/A'
    is_present BOOLEAN,
    has_record BOOLEAN  -- Indicates if student has an attendance record for this date
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.registration_no,
        s.student_name,
        s.current_semester AS semester,
        s.section,
        CASE
            WHEN da.registration_no IS NULL THEN 'N/A'  -- No attendance record = N/A
            WHEN da.is_present THEN 'Present'
            ELSE 'Absent'
        END AS status,
        COALESCE(da.is_present, false) AS is_present,
        (da.registration_no IS NOT NULL) AS has_record
    FROM
        students s
    LEFT JOIN
        daily_attendance da ON s.registration_no = da.registration_no 
                            AND da.date = p_date
    WHERE
        s.department ILIKE p_department_name 
        OR s.department ILIKE REPLACE(p_department_name, ' ', '%');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_department_attendance_today(TEXT, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_department_attendance_today(TEXT) TO authenticated;

-- Create summary function for department-wide stats
CREATE OR REPLACE FUNCTION get_department_attendance_summary(p_department_name TEXT, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
    total_students INTEGER,
    students_with_records INTEGER,  -- Students who have attendance records
    today_present INTEGER,
    today_absent INTEGER,
    students_na INTEGER,  -- Students without attendance records (N/A)
    avg_attendance NUMERIC,
    low_attendance_students INTEGER
) AS $$
DECLARE
    student_count INTEGER;
    records_count INTEGER;
    present_count INTEGER;
    absent_count INTEGER;
    na_count INTEGER;
    avg_attendance_val NUMERIC;
    low_attendance_count INTEGER;
BEGIN
    -- Get total students in department
    SELECT COUNT(*) INTO student_count
    FROM students s
    WHERE s.department ILIKE p_department_name 
       OR s.department ILIKE REPLACE(p_department_name, ' ', '%');
    
    -- Get today's attendance counts
    SELECT 
        COUNT(*) FILTER (WHERE da.registration_no IS NOT NULL),  -- Students with records
        COUNT(*) FILTER (WHERE da.is_present = true),            -- Present
        COUNT(*) FILTER (WHERE da.is_present = false)            -- Absent (explicitly marked)
    INTO records_count, present_count, absent_count
    FROM students s
    LEFT JOIN daily_attendance da ON s.registration_no = da.registration_no 
                                   AND da.date = p_date
    WHERE s.department ILIKE p_department_name 
       OR s.department ILIKE REPLACE(p_department_name, ' ', '%');
    
    -- Calculate N/A count (students without records)
    na_count := student_count - records_count;
    
    -- Get overall attendance average from summary table
    SELECT AVG(oas.overall_percentage) INTO avg_attendance_val
    FROM overall_attendance_summary oas
    WHERE oas.department ILIKE p_department_name 
       OR oas.department ILIKE REPLACE(p_department_name, ' ', '%');
    
    -- Get count of students with low attendance (below 75%)
    SELECT COUNT(*) INTO low_attendance_count
    FROM overall_attendance_summary oas
    WHERE (oas.department ILIKE p_department_name 
           OR oas.department ILIKE REPLACE(p_department_name, ' ', '%'))
      AND oas.overall_percentage < 75.0;
    
    -- Return the results
    RETURN QUERY SELECT 
        COALESCE(student_count, 0),
        COALESCE(records_count, 0),
        COALESCE(present_count, 0),
        COALESCE(absent_count, 0),
        COALESCE(na_count, 0),
        COALESCE(avg_attendance_val, 0.0),
        COALESCE(low_attendance_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION get_department_attendance_today IS 
'Returns attendance status for all students in a department. 
Status can be: Present, Absent (explicitly marked), or N/A (no record for that date).
This prevents students whose attendance was not taken from appearing as Absent.';

COMMENT ON FUNCTION get_department_attendance_summary IS 
'Returns department-wide attendance summary distinguishing between 
students with attendance records vs those without (N/A status).';
