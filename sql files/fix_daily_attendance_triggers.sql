-- Fix for Daily Attendance Summary Synchronization
-- This SQL script creates triggers to ensure overall_attendance_summary 
-- is updated when daily_attendance records are inserted/updated

-- ============================================================================
-- STEP 1: Create function to update overall summary from daily attendance
-- ============================================================================

CREATE OR REPLACE FUNCTION update_overall_attendance_from_daily()
RETURNS TRIGGER AS $$
DECLARE
    student_record RECORD;
    total_days INTEGER;
    present_days INTEGER;
    calculated_percentage DECIMAL;
BEGIN
    -- Get student details
    SELECT 
        department, 
        COALESCE(semester, current_semester) as semester, 
        section 
    INTO student_record
    FROM students 
    WHERE registration_no = NEW.registration_no
    LIMIT 1;

    IF FOUND THEN
        -- Calculate attendance from daily_attendance table
        SELECT 
            COUNT(*) as total_days,
            SUM(CASE WHEN is_present THEN 1 ELSE 0 END) as present_days
        INTO total_days, present_days
        FROM daily_attendance 
        WHERE registration_no = NEW.registration_no;

        -- Calculate percentage
        calculated_percentage := CASE 
            WHEN total_days > 0 THEN ROUND((present_days::DECIMAL / total_days) * 100, 2)
            ELSE 0.0
        END;

        -- Update or insert overall summary
        INSERT INTO overall_attendance_summary (
            registration_no,
            department,
            semester,
            section,
            total_periods,
            attended_periods,
            overall_percentage,
            last_updated
        )
        VALUES (
            NEW.registration_no,
            student_record.department,
            student_record.semester,
            student_record.section,
            total_days,
            present_days,
            calculated_percentage,
            NOW()
        )
        ON CONFLICT (registration_no) 
        DO UPDATE SET
            total_periods = EXCLUDED.total_periods,
            attended_periods = EXCLUDED.attended_periods,
            overall_percentage = EXCLUDED.overall_percentage,
            last_updated = NOW();

        RAISE LOG 'Updated overall_attendance_summary for %: %/%% = %%', 
            NEW.registration_no, present_days, total_days, calculated_percentage;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 2: Create trigger for daily_attendance table
-- ============================================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS daily_attendance_summary_trigger ON daily_attendance;

-- Create new trigger
CREATE TRIGGER daily_attendance_summary_trigger
    AFTER INSERT OR UPDATE OR DELETE ON daily_attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_overall_attendance_from_daily();

-- ============================================================================
-- STEP 3: Handle DELETE operations (for completeness)
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_daily_attendance_delete()
RETURNS TRIGGER AS $$
DECLARE
    student_record RECORD;
    total_days INTEGER;
    present_days INTEGER;
    calculated_percentage DECIMAL;
BEGIN
    -- Get student details
    SELECT 
        department, 
        COALESCE(semester, current_semester) as semester, 
        section 
    INTO student_record
    FROM students 
    WHERE registration_no = OLD.registration_no
    LIMIT 1;

    IF FOUND THEN
        -- Recalculate attendance after deletion
        SELECT 
            COUNT(*) as total_days,
            SUM(CASE WHEN is_present THEN 1 ELSE 0 END) as present_days
        INTO total_days, present_days
        FROM daily_attendance 
        WHERE registration_no = OLD.registration_no;

        -- Calculate percentage
        calculated_percentage := CASE 
            WHEN total_days > 0 THEN ROUND((present_days::DECIMAL / total_days) * 100, 2)
            ELSE 0.0
        END;

        IF total_days > 0 THEN
            -- Update existing summary
            UPDATE overall_attendance_summary 
            SET 
                total_periods = total_days,
                attended_periods = present_days,
                overall_percentage = calculated_percentage,
                last_updated = NOW()
            WHERE registration_no = OLD.registration_no;
        ELSE
            -- Delete summary if no attendance records remain
            DELETE FROM overall_attendance_summary 
            WHERE registration_no = OLD.registration_no;
        END IF;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create DELETE trigger
DROP TRIGGER IF EXISTS daily_attendance_delete_trigger ON daily_attendance;
CREATE TRIGGER daily_attendance_delete_trigger
    BEFORE DELETE ON daily_attendance
    FOR EACH ROW
    EXECUTE FUNCTION handle_daily_attendance_delete();

-- ============================================================================
-- STEP 4: Initial sync - update all existing daily attendance records
-- ============================================================================

-- Update overall_attendance_summary for all existing daily_attendance records
INSERT INTO overall_attendance_summary (
    registration_no,
    department,
    semester,
    section,
    total_periods,
    attended_periods,
    overall_percentage,
    last_updated
)
SELECT 
    da.registration_no,
    s.department,
    COALESCE(s.semester, s.current_semester) as semester,
    s.section,
    COUNT(*) as total_periods,
    SUM(CASE WHEN da.is_present THEN 1 ELSE 0 END) as attended_periods,
    ROUND(
        (SUM(CASE WHEN da.is_present THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
        2
    ) as overall_percentage,
    NOW() as last_updated
FROM daily_attendance da
JOIN students s ON s.registration_no = da.registration_no
WHERE da.registration_no NOT IN (
    SELECT registration_no FROM overall_attendance_summary
)
GROUP BY da.registration_no, s.department, COALESCE(s.semester, s.current_semester), s.section
ON CONFLICT (registration_no) 
DO UPDATE SET
    total_periods = EXCLUDED.total_periods,
    attended_periods = EXCLUDED.attended_periods,
    overall_percentage = EXCLUDED.overall_percentage,
    last_updated = NOW();

-- ============================================================================
-- STEP 5: Verification query
-- ============================================================================

-- Run this to verify the fix is working
/*
SELECT 
    'daily_attendance' as source,
    COUNT(*) as record_count
FROM daily_attendance

UNION ALL

SELECT 
    'overall_attendance_summary' as source,
    COUNT(*) as record_count
FROM overall_attendance_summary

UNION ALL

SELECT 
    'recent_updates' as source,
    COUNT(*) as record_count
FROM overall_attendance_summary 
WHERE last_updated > NOW() - INTERVAL '1 hour';
*/
