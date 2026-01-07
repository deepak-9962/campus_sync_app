-- ============================================================================
-- INCREMENT ALL STUDENTS TO NEXT SEMESTER
-- ============================================================================
-- Run this FIRST before importing attendance data
-- This updates all students to their next semester (semester + 1)
-- 
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Check current semester distribution before update
-- ============================================================================
SELECT 'BEFORE UPDATE - Students by semester:' as info;
SELECT department, semester, COUNT(*) as student_count
FROM students
GROUP BY department, semester
ORDER BY department, semester;

-- Also check overall_attendance_summary
SELECT 'BEFORE UPDATE - Attendance summary by semester:' as info;
SELECT department, semester, COUNT(*) as record_count
FROM overall_attendance_summary
GROUP BY department, semester
ORDER BY department, semester;

-- ============================================================================
-- STEP 2: Update students table - increment semester by 1
-- ============================================================================
-- Students in semester 8 will become semester 9 (graduated - you may want to handle separately)
-- Adjust the WHERE clause if you want to exclude certain semesters

UPDATE students
SET semester = semester + 1,
    current_semester = COALESCE(current_semester, semester) + 1
WHERE semester IS NOT NULL
  AND semester < 8;  -- Don't increment beyond 8th semester (final year)

-- ============================================================================
-- STEP 3: Update overall_attendance_summary table - increment semester by 1
-- ============================================================================
UPDATE overall_attendance_summary
SET semester = semester + 1,
    last_updated = NOW()
WHERE semester IS NOT NULL
  AND semester < 8;

-- ============================================================================
-- STEP 4: Verify the update
-- ============================================================================
SELECT 'AFTER UPDATE - Students by semester:' as info;
SELECT department, semester, COUNT(*) as student_count
FROM students
GROUP BY department, semester
ORDER BY department, semester;

SELECT 'AFTER UPDATE - Attendance summary by semester:' as info;
SELECT department, semester, COUNT(*) as record_count
FROM overall_attendance_summary
GROUP BY department, semester
ORDER BY department, semester;

-- ============================================================================
-- DONE! All students have been moved to the next semester
-- Now you can run the attendance import script
-- ============================================================================
