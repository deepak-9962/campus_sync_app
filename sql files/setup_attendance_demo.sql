-- Add percentage column to attendance table for demo
-- Run this in your Supabase SQL Editor

-- 1. Add percentage column to attendance table
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS percentage DECIMAL(5,2) NULL;

-- 2. Add optional columns for detailed tracking (for demo)
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS total_classes INTEGER NULL,
ADD COLUMN IF NOT EXISTS attended_classes INTEGER NULL;

-- 3. Add comments to explain these are for demo
COMMENT ON COLUMN public.attendance.percentage IS 'Overall attendance percentage for demo display';
COMMENT ON COLUMN public.attendance.total_classes IS 'Total classes conducted (for demo)';
COMMENT ON COLUMN public.attendance.attended_classes IS 'Classes attended by student (for demo)';

-- 4. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_registration_percentage 
ON public.attendance(registration_no, percentage);

-- 5. Insert demo data for council meeting
-- Replace with your actual Excel data
INSERT INTO public.attendance (registration_no, date, status, percentage, total_classes, attended_classes) VALUES
('210823104001', CURRENT_DATE, 'present', 85.50, 100, 85),
('210823104002', CURRENT_DATE, 'present', 92.30, 100, 92),
('210823104003', CURRENT_DATE, 'absent', 78.20, 100, 78),
('210823104004', CURRENT_DATE, 'present', 88.90, 100, 88),
('210823104005', CURRENT_DATE, 'present', 95.60, 100, 95),
('210823104006', CURRENT_DATE, 'present', 82.40, 100, 82),
('210823104007', CURRENT_DATE, 'absent', 76.80, 100, 76),
('210823104008', CURRENT_DATE, 'present', 90.20, 100, 90),
('210823104009', CURRENT_DATE, 'present', 87.60, 100, 87),
('210823104010', CURRENT_DATE, 'present', 93.40, 100, 93),
-- Add TEST students for testing
('TEST001', CURRENT_DATE, 'present', 85.50, 100, 85),
('TEST002', CURRENT_DATE, 'present', 92.30, 100, 92),
('TEST003', CURRENT_DATE, 'absent', 78.20, 100, 78)
ON CONFLICT (registration_no, date) 
DO UPDATE SET 
  percentage = EXCLUDED.percentage,
  total_classes = EXCLUDED.total_classes,
  attended_classes = EXCLUDED.attended_classes;

-- 6. Create function to get attendance summary for a student
CREATE OR REPLACE FUNCTION get_student_attendance_summary(student_reg_no TEXT)
RETURNS TABLE (
    registration_no TEXT,
    department TEXT,
    current_semester INTEGER,
    section TEXT,
    percentage DECIMAL(5,2),
    total_classes INTEGER,
    attended_classes INTEGER,
    status_text TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.registration_no,
        s.department,
        s.current_semester,
        s.section,
        a.percentage,
        a.total_classes,
        a.attended_classes,
        CASE 
            WHEN a.percentage >= 90 THEN 'Excellent'
            WHEN a.percentage >= 75 THEN 'Good'
            WHEN a.percentage >= 60 THEN 'Average'
            ELSE 'Needs Improvement'
        END as status_text
    FROM public.students s
    LEFT JOIN public.attendance a ON s.registration_no = a.registration_no
    WHERE s.registration_no = student_reg_no
    AND a.date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Grant permissions
GRANT EXECUTE ON FUNCTION get_student_attendance_summary(TEXT) TO authenticated;

-- 8. Create summary view for council meeting presentation
CREATE OR REPLACE VIEW attendance_summary_report AS
SELECT 
    s.registration_no,
    s.department,
    s.current_semester,
    s.section,
    s.batch,
    a.percentage,
    a.total_classes,
    a.attended_classes,
    CASE 
        WHEN a.percentage >= 90 THEN 'Excellent'
        WHEN a.percentage >= 75 THEN 'Good'
        WHEN a.percentage >= 60 THEN 'Average'
        ELSE 'Needs Improvement'
    END as performance_status,
    CASE 
        WHEN a.percentage >= 75 THEN 'Meeting Requirements'
        ELSE 'Below Requirements'
    END as eligibility_status
FROM public.students s
LEFT JOIN public.attendance a ON s.registration_no = a.registration_no
WHERE a.date = CURRENT_DATE
ORDER BY a.percentage DESC;

-- 9. Grant access to the view
GRANT SELECT ON attendance_summary_report TO authenticated;
