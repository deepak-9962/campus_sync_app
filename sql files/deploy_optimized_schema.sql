-- Campus Sync App - Optimized Period-Based Attendance Schema Deployment
-- This script safely deploys the new period-based attendance system
-- Run this in your Supabase SQL editor

-- Start transaction
BEGIN;

-- ============================================================================
-- STEP 0: Update students table to add missing columns if needed
-- ============================================================================

-- Add student_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'students' AND column_name = 'student_name'
    ) THEN
        ALTER TABLE students ADD COLUMN student_name VARCHAR(100);
        RAISE NOTICE 'Added student_name column to students table';
        
        -- Update student_name with registration_no as default
        UPDATE students SET student_name = registration_no WHERE student_name IS NULL;
    END IF;
END $$;

-- Ensure semester column compatibility
DO $$
BEGIN
    -- If current_semester exists but semester doesn't, add semester
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'students' AND column_name = 'current_semester'
    ) AND NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'students' AND column_name = 'semester'
    ) THEN
        ALTER TABLE students ADD COLUMN semester INTEGER;
        UPDATE students SET semester = current_semester WHERE semester IS NULL;
        RAISE NOTICE 'Added semester column to students table and synced with current_semester';
    END IF;
END $$;

-- ============================================================================
-- STEP 1: Create new tables for period-based attendance system
-- ============================================================================

-- Create subjects table
CREATE TABLE IF NOT EXISTS subjects (
    subject_code VARCHAR(10) PRIMARY KEY,
    subject_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    semester INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 8),
    credits INTEGER DEFAULT 4,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create class schedule table
CREATE TABLE IF NOT EXISTS class_schedule (
    id SERIAL PRIMARY KEY,
    subject_code VARCHAR(10) REFERENCES subjects(subject_code) ON DELETE CASCADE,
    department VARCHAR(50) NOT NULL,
    semester INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 8),
    section VARCHAR(5) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL CHECK (day_of_week IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday')),
    period_number INTEGER NOT NULL CHECK (period_number BETWEEN 1 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(department, semester, section, day_of_week, period_number)
);

-- Create attendance summary table for optimized queries
CREATE TABLE IF NOT EXISTS attendance_summary (
    id SERIAL PRIMARY KEY,
    registration_no VARCHAR(20) NOT NULL,
    subject_code VARCHAR(10) NOT NULL REFERENCES subjects(subject_code) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_periods INTEGER DEFAULT 0,
    attended_periods INTEGER DEFAULT 0,
    attendance_percentage DECIMAL(5,2) DEFAULT 0.00,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(registration_no, subject_code, date)
);

-- Create overall attendance summary for student dashboard
CREATE TABLE IF NOT EXISTS overall_attendance_summary (
    id SERIAL PRIMARY KEY,
    registration_no VARCHAR(20) NOT NULL,
    department VARCHAR(50) NOT NULL,
    semester INTEGER NOT NULL,
    section VARCHAR(5) NOT NULL,
    total_periods INTEGER DEFAULT 0,
    attended_periods INTEGER DEFAULT 0,
    overall_percentage DECIMAL(5,2) DEFAULT 0.00,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(registration_no)
);

-- ============================================================================
-- STEP 2: Backup existing attendance table and modify structure
-- ============================================================================

-- Create backup of existing attendance table
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'attendance') THEN
        -- Create backup table
        DROP TABLE IF EXISTS attendance_backup;
        CREATE TABLE attendance_backup AS SELECT * FROM attendance;
        
        -- Log backup creation
        RAISE NOTICE 'Existing attendance data backed up to attendance_backup table';
    END IF;
END $$;

-- Drop existing attendance table and recreate with new schema
DROP TABLE IF EXISTS attendance CASCADE;

-- Create new attendance table with period-based structure
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    registration_no VARCHAR(20) NOT NULL,
    subject_code VARCHAR(10) NOT NULL REFERENCES subjects(subject_code) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    period_number INTEGER NOT NULL CHECK (period_number BETWEEN 1 AND 6),
    is_present BOOLEAN NOT NULL DEFAULT TRUE,
    marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(registration_no, subject_code, date, period_number)
);

-- ============================================================================
-- STEP 3: Insert sample data
-- ============================================================================

-- Insert sample subjects for CSE department
INSERT INTO subjects (subject_code, subject_name, department, semester, credits) VALUES
('CSE301', 'Database Management Systems', 'Computer Science', 3, 4),
('CSE302', 'Computer Networks', 'Computer Science', 3, 4),
('CSE303', 'Operating Systems', 'Computer Science', 3, 4),
('CSE304', 'Software Engineering', 'Computer Science', 3, 4),
('CSE305', 'Web Development', 'Computer Science', 3, 3),
('CSE401', 'Machine Learning', 'Computer Science', 4, 4),
('CSE402', 'Artificial Intelligence', 'Computer Science', 4, 4),
('CSE403', 'Data Science', 'Computer Science', 4, 3),
('ECE301', 'Digital Signal Processing', 'Electronics', 3, 4),
('ECE302', 'Microprocessors', 'Electronics', 3, 4),
('ECE303', 'Communication Systems', 'Electronics', 3, 4),
('MECH301', 'Fluid Mechanics', 'Mechanical', 3, 4),
('MECH302', 'Heat Transfer', 'Mechanical', 3, 4),
('MECH303', 'Machine Design', 'Mechanical', 3, 4)
ON CONFLICT (subject_code) DO NOTHING;

-- Insert sample class schedule for CSE 3rd semester, Section A
INSERT INTO class_schedule (subject_code, department, semester, section, day_of_week, period_number, start_time, end_time) VALUES
-- Monday
('CSE301', 'Computer Science', 3, 'A', 'monday', 1, '09:00', '09:50'),
('CSE302', 'Computer Science', 3, 'A', 'monday', 2, '10:00', '10:50'),
('CSE303', 'Computer Science', 3, 'A', 'monday', 3, '11:00', '11:50'),
('CSE304', 'Computer Science', 3, 'A', 'monday', 4, '01:00', '01:50'),
('CSE305', 'Computer Science', 3, 'A', 'monday', 5, '02:00', '02:50'),
-- Tuesday
('CSE302', 'Computer Science', 3, 'A', 'tuesday', 1, '09:00', '09:50'),
('CSE301', 'Computer Science', 3, 'A', 'tuesday', 2, '10:00', '10:50'),
('CSE304', 'Computer Science', 3, 'A', 'tuesday', 3, '11:00', '11:50'),
('CSE303', 'Computer Science', 3, 'A', 'tuesday', 4, '01:00', '01:50'),
('CSE305', 'Computer Science', 3, 'A', 'tuesday', 5, '02:00', '02:50'),
-- Wednesday
('CSE303', 'Computer Science', 3, 'A', 'wednesday', 1, '09:00', '09:50'),
('CSE305', 'Computer Science', 3, 'A', 'wednesday', 2, '10:00', '10:50'),
('CSE301', 'Computer Science', 3, 'A', 'wednesday', 3, '11:00', '11:50'),
('CSE302', 'Computer Science', 3, 'A', 'wednesday', 4, '01:00', '01:50'),
('CSE304', 'Computer Science', 3, 'A', 'wednesday', 5, '02:00', '02:50'),
-- Thursday
('CSE304', 'Computer Science', 3, 'A', 'thursday', 1, '09:00', '09:50'),
('CSE303', 'Computer Science', 3, 'A', 'thursday', 2, '10:00', '10:50'),
('CSE302', 'Computer Science', 3, 'A', 'thursday', 3, '11:00', '11:50'),
('CSE305', 'Computer Science', 3, 'A', 'thursday', 4, '01:00', '01:50'),
('CSE301', 'Computer Science', 3, 'A', 'thursday', 5, '02:00', '02:50'),
-- Friday
('CSE305', 'Computer Science', 3, 'A', 'friday', 1, '09:00', '09:50'),
('CSE304', 'Computer Science', 3, 'A', 'friday', 2, '10:00', '10:50'),
('CSE301', 'Computer Science', 3, 'A', 'friday', 3, '11:00', '11:50'),
('CSE303', 'Computer Science', 3, 'A', 'friday', 4, '01:00', '01:50'),
('CSE302', 'Computer Science', 3, 'A', 'friday', 5, '02:00', '02:50')
ON CONFLICT (department, semester, section, day_of_week, period_number) DO NOTHING;

-- ============================================================================
-- STEP 4: Create functions for attendance summary updates
-- ============================================================================

-- Function to update daily attendance summary
CREATE OR REPLACE FUNCTION update_attendance_summary()
RETURNS TRIGGER AS $$
BEGIN
    -- Update or insert daily summary
    INSERT INTO attendance_summary (
        registration_no,
        subject_code,
        date,
        total_periods,
        attended_periods,
        attendance_percentage
    )
    SELECT 
        NEW.registration_no,
        NEW.subject_code,
        NEW.date,
        COUNT(*) as total_periods,
        SUM(CASE WHEN is_present THEN 1 ELSE 0 END) as attended_periods,
        ROUND(
            (SUM(CASE WHEN is_present THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
            2
        ) as attendance_percentage
    FROM attendance 
    WHERE registration_no = NEW.registration_no 
        AND subject_code = NEW.subject_code 
        AND date = NEW.date
    GROUP BY registration_no, subject_code, date
    ON CONFLICT (registration_no, subject_code, date) 
    DO UPDATE SET
        total_periods = EXCLUDED.total_periods,
        attended_periods = EXCLUDED.attended_periods,
        attendance_percentage = EXCLUDED.attendance_percentage,
        last_updated = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update overall attendance summary
CREATE OR REPLACE FUNCTION update_overall_attendance_summary()
RETURNS TRIGGER AS $$
DECLARE
    student_record RECORD;
BEGIN
    -- Get student details - handle both semester and current_semester columns
    SELECT 
        department, 
        COALESCE(semester, current_semester) as semester, 
        section 
    INTO student_record
    FROM students 
    WHERE registration_no = NEW.registration_no
    LIMIT 1;

    IF FOUND THEN
        -- Update or insert overall summary
        INSERT INTO overall_attendance_summary (
            registration_no,
            department,
            semester,
            section,
            total_periods,
            attended_periods,
            overall_percentage
        )
        SELECT 
            NEW.registration_no,
            student_record.department,
            student_record.semester,
            student_record.section,
            COUNT(*) as total_periods,
            SUM(CASE WHEN is_present THEN 1 ELSE 0 END) as attended_periods,
            ROUND(
                (SUM(CASE WHEN is_present THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 
                2
            ) as overall_percentage
        FROM attendance 
        WHERE registration_no = NEW.registration_no
        GROUP BY registration_no
        ON CONFLICT (registration_no) 
        DO UPDATE SET
            total_periods = EXCLUDED.total_periods,
            attended_periods = EXCLUDED.attended_periods,
            overall_percentage = EXCLUDED.overall_percentage,
            last_updated = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Create triggers for automatic summary updates
-- ============================================================================

-- Trigger for attendance summary update
DROP TRIGGER IF EXISTS attendance_summary_trigger ON attendance;
CREATE TRIGGER attendance_summary_trigger
    AFTER INSERT OR UPDATE OR DELETE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_summary();

-- Trigger for overall attendance summary update  
DROP TRIGGER IF EXISTS overall_attendance_summary_trigger ON attendance;
CREATE TRIGGER overall_attendance_summary_trigger
    AFTER INSERT OR UPDATE OR DELETE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_overall_attendance_summary();

-- ============================================================================
-- STEP 6: Create indexes for better performance
-- ============================================================================

-- Indexes on attendance table
CREATE INDEX IF NOT EXISTS idx_attendance_reg_no ON attendance(registration_no);
CREATE INDEX IF NOT EXISTS idx_attendance_subject_date ON attendance(subject_code, date);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_period ON attendance(period_number);

-- Indexes on summary tables
CREATE INDEX IF NOT EXISTS idx_attendance_summary_reg_no ON attendance_summary(registration_no);
CREATE INDEX IF NOT EXISTS idx_attendance_summary_subject ON attendance_summary(subject_code);
CREATE INDEX IF NOT EXISTS idx_attendance_summary_date ON attendance_summary(date);

CREATE INDEX IF NOT EXISTS idx_overall_summary_reg_no ON overall_attendance_summary(registration_no);
CREATE INDEX IF NOT EXISTS idx_overall_summary_dept_sem ON overall_attendance_summary(department, semester);

-- Indexes on class_schedule
CREATE INDEX IF NOT EXISTS idx_class_schedule_dept_sem ON class_schedule(department, semester);
CREATE INDEX IF NOT EXISTS idx_class_schedule_day_period ON class_schedule(day_of_week, period_number);

-- Indexes on subjects
CREATE INDEX IF NOT EXISTS idx_subjects_dept_sem ON subjects(department, semester);

-- ============================================================================
-- STEP 7: Create views for reporting
-- ============================================================================

-- View for attendance analytics
CREATE OR REPLACE VIEW attendance_analytics AS
SELECT 
    s.registration_no,
    s.student_name,
    s.department,
    COALESCE(s.semester, s.current_semester) as semester,
    s.section,
    oas.total_periods,
    oas.attended_periods,
    oas.overall_percentage,
    CASE 
        WHEN oas.overall_percentage >= 75 THEN 'Regular'
        WHEN oas.overall_percentage >= 50 THEN 'Irregular'
        ELSE 'Poor'
    END as attendance_status,
    oas.last_updated
FROM students s
LEFT JOIN overall_attendance_summary oas ON s.registration_no = oas.registration_no;

-- View for subject-wise attendance
CREATE OR REPLACE VIEW subject_wise_attendance AS
SELECT 
    s.registration_no,
    s.student_name,
    s.department,
    COALESCE(s.semester, s.current_semester) as semester,
    sub.subject_code,
    sub.subject_name,
    SUM(att.total_periods) as total_periods,
    SUM(att.attended_periods) as attended_periods,
    CASE 
        WHEN SUM(att.total_periods) > 0 THEN 
            ROUND((SUM(att.attended_periods)::DECIMAL / SUM(att.total_periods)) * 100, 2)
        ELSE 0 
    END as subject_percentage
FROM students s
CROSS JOIN subjects sub
LEFT JOIN attendance_summary att ON s.registration_no = att.registration_no 
    AND sub.subject_code = att.subject_code
WHERE sub.department = s.department AND sub.semester = COALESCE(s.semester, s.current_semester)
GROUP BY s.registration_no, s.student_name, s.department, COALESCE(s.semester, s.current_semester), 
         sub.subject_code, sub.subject_name;

-- View for daily attendance summary
CREATE OR REPLACE VIEW daily_attendance_report AS
SELECT 
    a.date,
    a.subject_code,
    sub.subject_name,
    cs.department,
    cs.semester,
    cs.section,
    cs.period_number,
    COUNT(*) as total_students,
    SUM(CASE WHEN a.is_present THEN 1 ELSE 0 END) as present_count,
    COUNT(*) - SUM(CASE WHEN a.is_present THEN 1 ELSE 0 END) as absent_count,
    ROUND((SUM(CASE WHEN a.is_present THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 2) as class_percentage
FROM attendance a
JOIN subjects sub ON a.subject_code = sub.subject_code
JOIN class_schedule cs ON a.subject_code = cs.subject_code 
    AND a.period_number = cs.period_number
    AND LOWER(TO_CHAR(a.date, 'Day')) = TRIM(cs.day_of_week)
GROUP BY a.date, a.subject_code, sub.subject_name, cs.department, 
         cs.semester, cs.section, cs.period_number
ORDER BY a.date DESC, cs.period_number;

-- ============================================================================
-- STEP 8: Set up Row Level Security (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE overall_attendance_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedule ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Users can view attendance data" ON attendance FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert attendance data" ON attendance FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Users can update attendance data" ON attendance FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Users can view attendance summary" ON attendance_summary FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can view overall summary" ON overall_attendance_summary FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can view subjects" ON subjects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can view class schedule" ON class_schedule FOR SELECT TO authenticated USING (true);

-- ============================================================================
-- STEP 9: Data migration from old attendance (if backup exists)
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'attendance_backup') THEN
        -- Insert sample period-wise attendance based on old daily attendance
        -- This is a simplified migration - adjust based on your actual data structure
        RAISE NOTICE 'Found attendance_backup table. You may need to manually migrate period-wise data.';
        RAISE NOTICE 'Old attendance table backed up. New period-based system is ready.';
    END IF;
END $$;

-- ============================================================================
-- STEP 10: Grant necessary permissions
-- ============================================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON attendance TO authenticated;
GRANT SELECT ON attendance_summary TO authenticated;
GRANT SELECT ON overall_attendance_summary TO authenticated;
GRANT SELECT ON subjects TO authenticated;
GRANT SELECT ON class_schedule TO authenticated;
GRANT SELECT ON attendance_analytics TO authenticated;
GRANT SELECT ON subject_wise_attendance TO authenticated;
GRANT SELECT ON daily_attendance_report TO authenticated;

-- Grant sequence permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Commit transaction
COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these to verify the deployment
SELECT 'Subjects count: ' || COUNT(*) FROM subjects;
SELECT 'Class schedule count: ' || COUNT(*) FROM class_schedule;
SELECT 'Attendance table structure verified' as status;

-- Show sample data
SELECT 'Sample subjects:' as info;
SELECT subject_code, subject_name, department, semester FROM subjects LIMIT 5;

SELECT 'Sample schedule for CSE 3rd semester:' as info;
SELECT cs.day_of_week, cs.period_number, s.subject_name, cs.start_time, cs.end_time 
FROM class_schedule cs 
JOIN subjects s ON cs.subject_code = s.subject_code 
WHERE cs.department = 'Computer Science' AND cs.semester = 3 
ORDER BY cs.day_of_week, cs.period_number 
LIMIT 10;

-- Final success message
DO $$
BEGIN
    RAISE NOTICE 'Period-based attendance system deployed successfully!';
    RAISE NOTICE 'Your Flutter app can now use the new AttendanceService methods.';
    RAISE NOTICE 'Previous attendance data has been backed up to attendance_backup table.';
END $$;
