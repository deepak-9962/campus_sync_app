-- Corrected HOD Dashboard Function for Overall Attendance Statistics
-- This function calculates overall attendance statistics for a department

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_department_attendance_summary(TEXT);

-- Create the corrected function
CREATE OR REPLACE FUNCTION get_department_attendance_summary(dept_name TEXT)
RETURNS TABLE(
    total_students INTEGER,
    avg_attendance NUMERIC,
    low_attendance_students INTEGER,
    excellent_attendance_students INTEGER,
    good_attendance_students INTEGER,
    average_attendance_students INTEGER,
    below_average_students INTEGER
) AS $$
DECLARE
    student_count INTEGER;
    avg_attendance_val NUMERIC;
    low_attendance_count INTEGER;
    excellent_count INTEGER;
    good_count INTEGER;
    average_count INTEGER;
    below_average_count INTEGER;
BEGIN
    -- Get total students in department (handle variations in department names)
    SELECT COUNT(DISTINCT s.registration_no)
    INTO student_count
    FROM students s
    WHERE s.department ILIKE '%' || dept_name || '%'
       OR s.department ILIKE REPLACE(dept_name, ' and ', '%')
       OR s.department ILIKE REPLACE(dept_name, ' & ', '%')
       OR dept_name ILIKE '%' || s.department || '%';
    
    -- If no students found, return zeros
    IF student_count = 0 THEN
        RETURN QUERY SELECT 
            0::INTEGER,
            0.0::NUMERIC,
            0::INTEGER,
            0::INTEGER,
            0::INTEGER,
            0::INTEGER,
            0::INTEGER;
        RETURN;
    END IF;
    
    -- Get overall attendance statistics from overall_attendance_summary table
    -- This table should contain the calculated overall attendance percentages
    WITH department_stats AS (
        SELECT oas.overall_percentage
        FROM overall_attendance_summary oas
        JOIN students s ON oas.registration_no = s.registration_no
        WHERE s.department ILIKE '%' || dept_name || '%'
           OR s.department ILIKE REPLACE(dept_name, ' and ', '%')
           OR s.department ILIKE REPLACE(dept_name, ' & ', '%')
           OR dept_name ILIKE '%' || s.department || '%'
    )
    SELECT 
        COALESCE(AVG(overall_percentage), 0.0),
        COUNT(CASE WHEN overall_percentage < 75.0 THEN 1 END),
        COUNT(CASE WHEN overall_percentage >= 90.0 THEN 1 END),
        COUNT(CASE WHEN overall_percentage >= 75.0 AND overall_percentage < 90.0 THEN 1 END),
        COUNT(CASE WHEN overall_percentage >= 60.0 AND overall_percentage < 75.0 THEN 1 END),
        COUNT(CASE WHEN overall_percentage < 60.0 THEN 1 END)
    INTO avg_attendance_val, low_attendance_count, excellent_count, good_count, average_count, below_average_count
    FROM department_stats;
    
    -- If no attendance data found in summary table, try to calculate from raw attendance data
    IF avg_attendance_val IS NULL OR avg_attendance_val = 0 THEN
        WITH student_attendance AS (
            SELECT 
                s.registration_no,
                COUNT(a.id) as total_periods,
                COUNT(CASE WHEN a.is_present = true THEN 1 END) as attended_periods,
                CASE 
                    WHEN COUNT(a.id) > 0 THEN 
                        (COUNT(CASE WHEN a.is_present = true THEN 1 END) * 100.0 / COUNT(a.id))
                    ELSE 0.0 
                END as attendance_percentage
            FROM students s
            LEFT JOIN attendance a ON s.registration_no = a.registration_no
            WHERE s.department ILIKE '%' || dept_name || '%'
               OR s.department ILIKE REPLACE(dept_name, ' and ', '%')
               OR s.department ILIKE REPLACE(dept_name, ' & ', '%')
               OR dept_name ILIKE '%' || s.department || '%'
            GROUP BY s.registration_no
        )
        SELECT 
            COALESCE(AVG(attendance_percentage), 0.0),
            COUNT(CASE WHEN attendance_percentage < 75.0 THEN 1 END),
            COUNT(CASE WHEN attendance_percentage >= 90.0 THEN 1 END),
            COUNT(CASE WHEN attendance_percentage >= 75.0 AND attendance_percentage < 90.0 THEN 1 END),
            COUNT(CASE WHEN attendance_percentage >= 60.0 AND attendance_percentage < 75.0 THEN 1 END),
            COUNT(CASE WHEN attendance_percentage < 60.0 THEN 1 END)
        INTO avg_attendance_val, low_attendance_count, excellent_count, good_count, average_count, below_average_count
        FROM student_attendance;
    END IF;
    
    -- Return the results
    RETURN QUERY SELECT 
        COALESCE(student_count, 0),
        COALESCE(avg_attendance_val, 0.0),
        COALESCE(low_attendance_count, 0),
        COALESCE(excellent_count, 0),
        COALESCE(good_count, 0),
        COALESCE(average_count, 0),
        COALESCE(below_average_count, 0);
        
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_department_attendance_summary(TEXT) TO authenticated;

-- Test the function with a sample department
-- SELECT * FROM get_department_attendance_summary('Computer Science and Engineering');
