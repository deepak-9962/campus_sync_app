-- ============================================================================
-- ATTENDANCE DATA IMPORT FOR 6TH SEMESTER CSE-B
-- ============================================================================
-- This script imports 15 days of attendance data (Dec 4-20, 2025)
-- for 60 students in Computer Science and Engineering, Section B
-- 
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Insert/Update overall_attendance_summary (what the app displays)
-- ============================================================================
-- 15 working days total, updating with actual present days and percentage
-- IMPORTANT: Department must be 'Computer Science and Engineering' to match app queries

INSERT INTO overall_attendance_summary (registration_no, department, semester, section, total_periods, attended_periods, overall_percentage, last_updated)
VALUES
('210823104064', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104065', 'Computer Science and Engineering', 6, 'B', 15, 10, 66.67, NOW()),
('210823104066', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104067', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104068', 'Computer Science and Engineering', 6, 'B', 15, 14, 93.33, NOW()),
('210823104069', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104070', 'Computer Science and Engineering', 6, 'B', 15, 9, 60.00, NOW()),
('210823104071', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104072', 'Computer Science and Engineering', 6, 'B', 15, 14, 93.33, NOW()),
('210823104073', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW()),
('210823104074', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104075', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104076', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104077', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104078', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104080', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104081', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104082', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104083', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104084', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104085', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104087', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104088', 'Computer Science and Engineering', 6, 'B', 15, 10, 66.67, NOW()),
('210823104089', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104090', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104091', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104092', 'Computer Science and Engineering', 6, 'B', 15, 14, 93.33, NOW()),
('210823104093', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104094', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW()),
('210823104095', 'Computer Science and Engineering', 6, 'B', 15, 9, 60.00, NOW()),
('210823104096', 'Computer Science and Engineering', 6, 'B', 15, 10, 66.67, NOW()),
('210823104097', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104098', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104099', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW()),
('210823104100', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW()),
('210823104101', 'Computer Science and Engineering', 6, 'B', 15, 7, 46.67, NOW()),
('210823104102', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104103', 'Computer Science and Engineering', 6, 'B', 15, 10, 66.67, NOW()),
('210823104104', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104105', 'Computer Science and Engineering', 6, 'B', 15, 7, 46.67, NOW()),
('210823104106', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104107', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW()),
('210823104108', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104109', 'Computer Science and Engineering', 6, 'B', 15, 9, 60.00, NOW()),
('210823104110', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104111', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104112', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104113', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104114', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104115', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104116', 'Computer Science and Engineering', 6, 'B', 15, 14, 93.33, NOW()),
('210823104117', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104118', 'Computer Science and Engineering', 6, 'B', 15, 15, 100.00, NOW()),
('210823104119', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104120', 'Computer Science and Engineering', 6, 'B', 15, 13, 86.67, NOW()),
('210823104121', 'Computer Science and Engineering', 6, 'B', 15, 14, 93.33, NOW()),
('210823104122', 'Computer Science and Engineering', 6, 'B', 15, 12, 80.00, NOW()),
('210823104123', 'Computer Science and Engineering', 6, 'B', 15, 7, 46.67, NOW()),
('210823104124', 'Computer Science and Engineering', 6, 'B', 15, 11, 73.33, NOW()),
('210823104125', 'Computer Science and Engineering', 6, 'B', 15, 8, 53.33, NOW())
ON CONFLICT (registration_no) DO UPDATE SET
    department = EXCLUDED.department,
    semester = EXCLUDED.semester,
    section = EXCLUDED.section,
    total_periods = EXCLUDED.total_periods,
    attended_periods = EXCLUDED.attended_periods,
    overall_percentage = EXCLUDED.overall_percentage,
    last_updated = NOW();

-- ============================================================================
-- STEP 2: Verify the import
-- ============================================================================
SELECT 'Section B attendance records imported:' as info, COUNT(*) as count
FROM overall_attendance_summary 
WHERE department = 'Computer Science and Engineering' AND semester = 6 AND section = 'B';

-- Sample data check
SELECT registration_no, total_periods, attended_periods, overall_percentage
FROM overall_attendance_summary
WHERE department = 'Computer Science and Engineering' AND semester = 6 AND section = 'B'
ORDER BY registration_no
LIMIT 10;

-- Summary statistics
SELECT 
    'CSE 6th Sem Section B Summary' as info,
    COUNT(*) as total_students,
    ROUND(AVG(overall_percentage), 2) as avg_attendance,
    COUNT(CASE WHEN overall_percentage >= 75 THEN 1 END) as above_75_percent,
    COUNT(CASE WHEN overall_percentage < 75 THEN 1 END) as below_75_percent
FROM overall_attendance_summary
WHERE department = 'Computer Science and Engineering' AND semester = 6 AND section = 'B';

-- ============================================================================
-- DONE! The attendance should now be visible in the app for 6th semester CSE-B
-- ============================================================================
