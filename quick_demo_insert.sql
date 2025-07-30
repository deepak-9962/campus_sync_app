-- Quick demo data insertion for council meeting - REAL EXCEL DATA
-- Run this in your Supabase SQL Editor after running setup_attendance_demo.sql

-- Insert actual attendance data from Excel sheet (Total classes: 120)
INSERT INTO public.attendance (registration_no, date, status, percentage, total_classes, attended_classes) VALUES
-- Computer Science and Engineering students - Real Data from Excel
-- Status based on attendance percentage: >=75% = present, <75% = absent
('210823104001', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104002', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104003', CURRENT_DATE, 'present', 90.0, 120, 108),
('210823104004', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104005', CURRENT_DATE, 'absent', 25.0, 120, 30),
('210823104006', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104007', CURRENT_DATE, 'absent', 60.0, 120, 72),
('210823104008', CURRENT_DATE, 'absent', 45.0, 120, 54),
('210823104009', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104010', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104011', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104012', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104013', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104014', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104015', CURRENT_DATE, 'absent', 40.0, 120, 48),
('210823104016', CURRENT_DATE, 'present', 80.0, 120, 96),
('210823104017', CURRENT_DATE, 'absent', 55.0, 120, 66),
('210823104018', CURRENT_DATE, 'present', 90.0, 120, 108),
('210823104020', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104021', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104022', CURRENT_DATE, 'absent', 55.0, 120, 66),
('210823104023', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104024', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104025', CURRENT_DATE, 'absent', 0.0, 120, 0),
('210823104026', CURRENT_DATE, 'present', 80.0, 120, 96),
('210823104027', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104028', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104029', CURRENT_DATE, 'absent', 55.0, 120, 66),
('210823104030', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104031', CURRENT_DATE, 'present', 80.0, 120, 96),
('210823104032', CURRENT_DATE, 'absent', 45.0, 120, 54),
('210823104033', CURRENT_DATE, 'absent', 70.0, 120, 84),
('210823104034', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104035', CURRENT_DATE, 'absent', 40.0, 120, 48),
('210823104036', CURRENT_DATE, 'absent', 55.0, 120, 66),
('210823104037', CURRENT_DATE, 'present', 90.0, 120, 108),
('210823104038', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104039', CURRENT_DATE, 'present', 80.0, 120, 96),
('210823104040', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104041', CURRENT_DATE, 'absent', 45.0, 120, 54),
('210823104043', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104044', CURRENT_DATE, 'absent', 60.0, 120, 72),
('210823104046', CURRENT_DATE, 'absent', 0.0, 120, 0),
('210823104047', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104048', CURRENT_DATE, 'present', 95.0, 120, 114),
('210823104049', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104051', CURRENT_DATE, 'absent', 55.0, 120, 66),
('210823104052', CURRENT_DATE, 'absent', 50.0, 120, 60),
('210823104053', CURRENT_DATE, 'present', 85.0, 120, 102),
('210823104054', CURRENT_DATE, 'absent', 30.0, 120, 36),
('210823104055', CURRENT_DATE, 'absent', 45.0, 120, 54),
('210823104057', CURRENT_DATE, 'present', 75.0, 120, 90),
('210823104058', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104059', CURRENT_DATE, 'absent', 70.0, 120, 84),
('210823104060', CURRENT_DATE, 'present', 100.0, 120, 120),
('210823104061', CURRENT_DATE, 'absent', 60.0, 120, 72),
('210823104062', CURRENT_DATE, 'absent', 65.0, 120, 78),
('210823104063', CURRENT_DATE, 'absent', 40.0, 120, 48)

ON CONFLICT (registration_no, date) 
DO UPDATE SET 
  percentage = EXCLUDED.percentage,
  total_classes = EXCLUDED.total_classes,
  attended_classes = EXCLUDED.attended_classes,
  status = EXCLUDED.status;

-- Verify the insertion
SELECT COUNT(*) as total_records, 
       AVG(percentage) as average_percentage,
       COUNT(CASE WHEN percentage >= 75 THEN 1 END) as meeting_requirements,
       COUNT(CASE WHEN percentage < 75 THEN 1 END) as below_requirements
FROM public.attendance 
WHERE date = CURRENT_DATE;

-- Quick summary for council meeting
SELECT 
    'Total Students' as metric,
    COUNT(*)::text as value
FROM public.attendance WHERE date = CURRENT_DATE
UNION ALL
SELECT 
    'Average Attendance',
    ROUND(AVG(percentage), 1)::text || '%'
FROM public.attendance WHERE date = CURRENT_DATE
UNION ALL
SELECT 
    'Meeting Requirements (≥75%)',
    COUNT(CASE WHEN percentage >= 75 THEN 1 END)::text
FROM public.attendance WHERE date = CURRENT_DATE
UNION ALL
SELECT 
    'Below Requirements (<75%)',
    COUNT(CASE WHEN percentage < 75 THEN 1 END)::text
FROM public.attendance WHERE date = CURRENT_DATE;

-- Top performers
SELECT 
    registration_no,
    percentage || '%' as attendance_rate,
    CASE 
        WHEN percentage >= 90 THEN 'Excellent'
        WHEN percentage >= 75 THEN 'Good'
        ELSE 'Needs Improvement'
    END as performance
FROM public.attendance 
WHERE date = CURRENT_DATE
ORDER BY percentage DESC
LIMIT 10;
