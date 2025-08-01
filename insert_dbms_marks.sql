-- Insert Database Management System exam marks
-- Run this in your Supabase SQL Editor

-- First, create the exam for Database Management System if it doesn't exist
INSERT INTO public.exams (name, date, department, semester) VALUES
('Database Management System Exam', '2025-07-30', 'computer science and engineering', 5)
ON CONFLICT DO NOTHING;

-- Insert marks data for Database Management System using specific exam UUID
-- Note: AB (absent) marks are inserted as -1 (since NULL is not allowed)
INSERT INTO public.marks (registration_no, exam_id, subject, mark, out_of) VALUES
('210823104001', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 54, 100),
('210823104002', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 66, 100),
('210823104003', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 72, 100),
('210823104004', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 52, 100),
('210823104005', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 18, 100),
('210823104006', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 74, 100),
('210823104007', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 50, 100),
('210823104008', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 56, 100),
('210823104009', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 70, 100),
('210823104010', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104011', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 84, 100),
('210823104012', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 52, 100),
('210823104013', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 68, 100),
('210823104014', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 26, 100),
('210823104015', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 12, 100),
('210823104016', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 54, 100),
('210823104017', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 42, 100),
('210823104018', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 86, 100),
('210823104019', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104020', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 64, 100),
('210823104021', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 56, 100),
('210823104022', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 64, 100),
('210823104023', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 54, 100),
('210823104024', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 60, 100),
('210823104025', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 36, 100),
('210823104026', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 36, 100),
('210823104027', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 36, 100),
('210823104028', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 56, 100),
('210823104029', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 62, 100),
('210823104030', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 66, 100),
('210823104031', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 34, 100),
('210823104032', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 60, 100),
('210823104033', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 52, 100),
('210823104034', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 40, 100),
('210823104035', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 28, 100),
('210823104036', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104037', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 56, 100),
('210823104038', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 36, 100),
('210823104039', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 68, 100),
('210823104040', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 52, 100),
('210823104041', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 32, 100),
('210823104042', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104043', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 26, 100),
('210823104044', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 74, 100),
('210823104046', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104047', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 50, 100),
('210823104048', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 42, 100),
('210823104049', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 34, 100),
('210823104050', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104051', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 34, 100),
('210823104052', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 68, 100),
('210823104053', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 80, 100),
('210823104054', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 46, 100),
('210823104055', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', -1, 100), -- AB
('210823104057', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 18, 100),
('210823104058', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 52, 100),
('210823104059', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 34, 100),
('210823104060', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 72, 100),
('210823104061', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 36, 100),
('210823104062', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 30, 100),
('210823104063', '1b8ca615-29ab-40be-ac0c-24862cec4eaf', 'Database Management System', 2, 100)
ON CONFLICT (registration_no, exam_id, subject) DO UPDATE SET
    mark = EXCLUDED.mark,
    updated_at = NOW();-- Verify the insertion
SELECT 
    'Database Management System marks summary:' as info,
    COUNT(*) as total_entries,
    COUNT(CASE WHEN mark >= 0 THEN 1 END) as students_with_marks,
    COUNT(CASE WHEN mark = -1 THEN 1 END) as absent_students,
    ROUND(AVG(CASE WHEN mark >= 0 THEN mark END), 2) as average_mark,
    MIN(CASE WHEN mark >= 0 THEN mark END) as min_mark,
    MAX(mark) as max_mark
FROM public.marks m
WHERE m.exam_id = '1b8ca615-29ab-40be-ac0c-24862cec4eaf' 
  AND m.subject = 'Database Management System';

-- Show all marks for verification (with student info from users table if available)
SELECT 
    m.registration_no,
    s.department,
    s.current_semester,
    s.section,
    CASE 
        WHEN m.mark = -1 THEN 'AB'
        ELSE m.mark::text
    END as mark,
    m.out_of
FROM public.marks m
LEFT JOIN public.students s ON m.registration_no = s.registration_no
WHERE m.exam_id = '1b8ca615-29ab-40be-ac0c-24862cec4eaf' 
  AND m.subject = 'Database Management System'
ORDER BY m.registration_no;
