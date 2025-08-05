-- Optimized Period-Based Attendance System
-- This script modifies your existing schema for better period management

-- 1. Add period tracking columns to existing attendance table
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS period_number INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS subject_code TEXT DEFAULT 'GENERAL',
ADD COLUMN IF NOT EXISTS academic_year TEXT DEFAULT '2024-25';

-- 2. Drop the old unique constraint and create a new one for period-based attendance
ALTER TABLE public.attendance 
DROP CONSTRAINT IF EXISTS attendance_registration_no_date_key;

-- New unique constraint for period-based attendance
CREATE UNIQUE INDEX IF NOT EXISTS unique_period_attendance 
ON public.attendance(registration_no, date, period_number);

-- 3. Create a subjects table for better management
CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  subject_code TEXT NOT NULL UNIQUE,
  subject_name TEXT NOT NULL,
  department TEXT NOT NULL,
  semester INTEGER NOT NULL,
  credits INTEGER DEFAULT 3,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  PRIMARY KEY (id)
);

-- 4. Create a class schedule table
CREATE TABLE IF NOT EXISTS public.class_schedule (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  department TEXT NOT NULL,
  semester INTEGER NOT NULL,
  section TEXT NOT NULL,
  period_number INTEGER NOT NULL,
  subject_code TEXT NOT NULL REFERENCES public.subjects(subject_code),
  staff_id UUID REFERENCES auth.users(id),
  is_conducted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE(date, department, semester, section, period_number)
);

-- 5. Create attendance summary table for better performance
CREATE TABLE IF NOT EXISTS public.attendance_summary (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  registration_no TEXT NOT NULL REFERENCES public.students(registration_no) ON DELETE CASCADE,
  subject_code TEXT NOT NULL REFERENCES public.subjects(subject_code),
  department TEXT NOT NULL,
  semester INTEGER NOT NULL,
  section TEXT NOT NULL,
  total_classes INTEGER DEFAULT 0,
  attended_classes INTEGER DEFAULT 0,
  percentage DECIMAL(5,2) DEFAULT 0.00,
  last_updated TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE(registration_no, subject_code)
);

-- 6. Create overall attendance summary for quick access
CREATE TABLE IF NOT EXISTS public.overall_attendance_summary (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  registration_no TEXT NOT NULL REFERENCES public.students(registration_no) ON DELETE CASCADE,
  department TEXT NOT NULL,
  semester INTEGER NOT NULL,
  section TEXT NOT NULL,
  total_periods INTEGER DEFAULT 0,
  attended_periods INTEGER DEFAULT 0,
  overall_percentage DECIMAL(5,2) DEFAULT 0.00,
  last_updated TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  PRIMARY KEY (id),
  UNIQUE(registration_no)
);

-- 7. Function to calculate and update attendance summaries
CREATE OR REPLACE FUNCTION update_attendance_summaries()
RETURNS TRIGGER AS $$
DECLARE
  student_dept TEXT;
  student_sem INTEGER;
  student_sec TEXT;
  subj_total INTEGER;
  subj_attended INTEGER;
  subj_percentage DECIMAL(5,2);
  overall_total INTEGER;
  overall_attended INTEGER;
  overall_percentage DECIMAL(5,2);
BEGIN
  -- Get student information
  SELECT department, current_semester, section 
  INTO student_dept, student_sem, student_sec
  FROM students 
  WHERE registration_no = NEW.registration_no;
  
  -- Calculate subject-wise attendance
  SELECT 
    COUNT(*),
    COUNT(CASE WHEN status = 'present' THEN 1 END)
  INTO subj_total, subj_attended
  FROM attendance 
  WHERE registration_no = NEW.registration_no 
  AND subject_code = NEW.subject_code;
  
  subj_percentage := CASE 
    WHEN subj_total > 0 THEN (subj_attended::DECIMAL / subj_total) * 100
    ELSE 0 
  END;
  
  -- Update subject-wise summary
  INSERT INTO attendance_summary (
    registration_no, subject_code, department, semester, section,
    total_classes, attended_classes, percentage
  ) VALUES (
    NEW.registration_no, NEW.subject_code, student_dept, student_sem, student_sec,
    subj_total, subj_attended, subj_percentage
  )
  ON CONFLICT (registration_no, subject_code)
  DO UPDATE SET
    total_classes = subj_total,
    attended_classes = subj_attended,
    percentage = subj_percentage,
    last_updated = now();
  
  -- Calculate overall attendance
  SELECT 
    COUNT(*),
    COUNT(CASE WHEN status = 'present' THEN 1 END)
  INTO overall_total, overall_attended
  FROM attendance 
  WHERE registration_no = NEW.registration_no;
  
  overall_percentage := CASE 
    WHEN overall_total > 0 THEN (overall_attended::DECIMAL / overall_total) * 100
    ELSE 0 
  END;
  
  -- Update overall summary
  INSERT INTO overall_attendance_summary (
    registration_no, department, semester, section,
    total_periods, attended_periods, overall_percentage
  ) VALUES (
    NEW.registration_no, student_dept, student_sem, student_sec,
    overall_total, overall_attended, overall_percentage
  )
  ON CONFLICT (registration_no)
  DO UPDATE SET
    total_periods = overall_total,
    attended_periods = overall_attended,
    overall_percentage = overall_percentage,
    last_updated = now();
  
  -- Update the original attendance record with calculated percentages
  UPDATE attendance 
  SET 
    total_classes = overall_total,
    attended_classes = overall_attended,
    percentage = overall_percentage
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger for automatic summary updates
CREATE TRIGGER attendance_summary_trigger
AFTER INSERT OR UPDATE ON attendance
FOR EACH ROW EXECUTE FUNCTION update_attendance_summaries();

-- 9. Insert sample subjects
INSERT INTO subjects (subject_code, subject_name, department, semester) VALUES
('MAT101', 'Mathematics I', 'Computer Science and Engineering', 1),
('PHY102', 'Physics I', 'Computer Science and Engineering', 1),
('CSE103', 'Programming in C', 'Computer Science and Engineering', 1),
('ENG104', 'Technical English', 'Computer Science and Engineering', 1),
('MAT201', 'Mathematics II', 'Computer Science and Engineering', 2),
('CSE202', 'Data Structures', 'Computer Science and Engineering', 2),
('CSE301', 'Database Management', 'Computer Science and Engineering', 3),
('CSE302', 'Computer Networks', 'Computer Science and Engineering', 3),
('CSE401', 'Software Engineering', 'Computer Science and Engineering', 4),
('CSE402', 'Artificial Intelligence', 'Computer Science and Engineering', 4),
('CSE501', 'Machine Learning', 'Computer Science and Engineering', 5),
('CSE502', 'Project Work', 'Computer Science and Engineering', 5)
ON CONFLICT (subject_code) DO NOTHING;

-- 10. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_reg_subject ON attendance(registration_no, subject_code);
CREATE INDEX IF NOT EXISTS idx_attendance_date_period ON attendance(date, period_number);
CREATE INDEX IF NOT EXISTS idx_attendance_subject_date ON attendance(subject_code, date);
CREATE INDEX IF NOT EXISTS idx_class_schedule_date_dept ON class_schedule(date, department, semester, section);
CREATE INDEX IF NOT EXISTS idx_attendance_summary_reg ON attendance_summary(registration_no);
CREATE INDEX IF NOT EXISTS idx_overall_summary_reg ON overall_attendance_summary(registration_no);

-- 11. Create view for easy reporting
CREATE OR REPLACE VIEW student_attendance_report AS
SELECT 
  s.registration_no,
  s.student_name,
  s.department,
  s.current_semester,
  s.section,
  oas.total_periods,
  oas.attended_periods,
  oas.overall_percentage,
  CASE 
    WHEN oas.overall_percentage >= 90 THEN 'Excellent'
    WHEN oas.overall_percentage >= 75 THEN 'Good'
    WHEN oas.overall_percentage >= 60 THEN 'Average'
    ELSE 'Needs Improvement'
  END as performance_status,
  CASE 
    WHEN oas.overall_percentage >= 75 THEN 'Eligible'
    ELSE 'Not Eligible'
  END as exam_eligibility
FROM students s
LEFT JOIN overall_attendance_summary oas ON s.registration_no = oas.registration_no
ORDER BY s.registration_no;

-- 12. Create view for subject-wise attendance
CREATE OR REPLACE VIEW subject_attendance_report AS
SELECT 
  s.registration_no,
  s.student_name,
  s.department,
  s.current_semester,
  s.section,
  asub.subject_code,
  sub.subject_name,
  asub.total_classes,
  asub.attended_classes,
  asub.percentage as subject_percentage
FROM students s
JOIN attendance_summary asub ON s.registration_no = asub.registration_no
JOIN subjects sub ON asub.subject_code = sub.subject_code
ORDER BY s.registration_no, sub.subject_code;

-- 13. Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- 14. Migrate existing data (if any)
UPDATE attendance 
SET 
  period_number = 1,
  subject_code = 'GENERAL',
  academic_year = '2024-25'
WHERE period_number IS NULL OR subject_code IS NULL;

COMMENT ON TABLE attendance IS 'Period-wise attendance tracking with automatic summary calculation';
COMMENT ON TABLE attendance_summary IS 'Subject-wise attendance summaries for performance optimization';
COMMENT ON TABLE overall_attendance_summary IS 'Overall attendance summaries for quick dashboard access';
COMMENT ON TABLE class_schedule IS 'Daily class schedule and period management';
COMMENT ON TABLE subjects IS 'Subject master data for the institution';
