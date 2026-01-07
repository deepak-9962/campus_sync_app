-- ============================================================================
-- ATTENDANCE DATA IMPORT FOR 6TH SEMESTER CSE-A
-- ============================================================================
-- This script imports 15 days of attendance data (Dec 4-20, 2025)
-- and updates the overall_attendance_summary table that the app reads
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
('210823104001', 'Computer Science and Engineering', 6, 'A', 15, 15, 100.00, NOW()),
('210823104002', 'Computer Science and Engineering', 6, 'A', 15, 15, 100.00, NOW()),
('210823104003', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104004', 'Computer Science and Engineering', 6, 'A', 15, 10, 66.67, NOW()),
('210823104005', 'Computer Science and Engineering', 6, 'A', 15, 3, 20.00, NOW()),
('210823104006', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104007', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104008', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104009', 'Computer Science and Engineering', 6, 'A', 15, 14, 93.33, NOW()),
('210823104010', 'Computer Science and Engineering', 6, 'A', 15, 9, 60.00, NOW()),
('210823104011', 'Computer Science and Engineering', 6, 'A', 15, 15, 100.00, NOW()),
('210823104012', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104013', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104014', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104015', 'Computer Science and Engineering', 6, 'A', 15, 3, 20.00, NOW()),
('210823104016', 'Computer Science and Engineering', 6, 'A', 15, 7, 46.67, NOW()),
('210823104017', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104018', 'Computer Science and Engineering', 6, 'A', 15, 13, 86.67, NOW()),
('210823104020', 'Computer Science and Engineering', 6, 'A', 15, 14, 93.33, NOW()),
('210823104021', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104022', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104023', 'Computer Science and Engineering', 6, 'A', 15, 10, 66.67, NOW()),
('210823104024', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104025', 'Computer Science and Engineering', 6, 'A', 15, 6, 40.00, NOW()),
('210823104026', 'Computer Science and Engineering', 6, 'A', 15, 14, 93.33, NOW()),
('210823104027', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104028', 'Computer Science and Engineering', 6, 'A', 15, 10, 66.67, NOW()),
('210823104029', 'Computer Science and Engineering', 6, 'A', 15, 7, 46.67, NOW()),
('210823104030', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104031', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104032', 'Computer Science and Engineering', 6, 'A', 15, 0, 0.00, NOW()),
('210823104033', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104034', 'Computer Science and Engineering', 6, 'A', 15, 9, 60.00, NOW()),
('210823104035', 'Computer Science and Engineering', 6, 'A', 15, 4, 26.67, NOW()),
('210823104036', 'Computer Science and Engineering', 6, 'A', 15, 10, 66.67, NOW()),
('210823104037', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104038', 'Computer Science and Engineering', 6, 'A', 15, 7, 46.67, NOW()),
('210823104039', 'Computer Science and Engineering', 6, 'A', 15, 10, 66.67, NOW()),
('210823104040', 'Computer Science and Engineering', 6, 'A', 15, 13, 86.67, NOW()),
('210823104041', 'Computer Science and Engineering', 6, 'A', 15, 4, 26.67, NOW()),
('210823104043', 'Computer Science and Engineering', 6, 'A', 15, 7, 46.67, NOW()),
('210823104044', 'Computer Science and Engineering', 6, 'A', 15, 7, 46.67, NOW()),
('210823104046', 'Computer Science and Engineering', 6, 'A', 15, 6, 40.00, NOW()),
('210823104047', 'Computer Science and Engineering', 6, 'A', 15, 2, 13.33, NOW()),
('210823104048', 'Computer Science and Engineering', 6, 'A', 15, 15, 100.00, NOW()),
('210823104049', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104051', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104052', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104053', 'Computer Science and Engineering', 6, 'A', 15, 8, 53.33, NOW()),
('210823104054', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104055', 'Computer Science and Engineering', 6, 'A', 15, 6, 40.00, NOW()),
('210823104057', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104058', 'Computer Science and Engineering', 6, 'A', 15, 15, 100.00, NOW()),
('210823104059', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104060', 'Computer Science and Engineering', 6, 'A', 15, 11, 73.33, NOW()),
('210823104061', 'Computer Science and Engineering', 6, 'A', 15, 1, 6.67, NOW()),
('210823104062', 'Computer Science and Engineering', 6, 'A', 15, 12, 80.00, NOW()),
('210823104063', 'Computer Science and Engineering', 6, 'A', 15, 6, 40.00, NOW())
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
SELECT 'Attendance records imported:' as info, COUNT(*) as count
FROM overall_attendance_summary 
WHERE department = 'Computer Science and Engineering' AND semester = 6 AND section = 'A';

-- Sample data check
SELECT registration_no, total_periods, attended_periods, overall_percentage
FROM overall_attendance_summary
WHERE department = 'Computer Science and Engineering' AND semester = 6 AND section = 'A'
ORDER BY registration_no
LIMIT 10;

-- ============================================================================
-- DONE! The attendance should now be visible in the app for 6th semester CSE-A
-- ============================================================================
