-- Create exams and marks tables for Campus Sync App
-- Run this in your Supabase SQL Editor

-- Create exams table
CREATE TABLE IF NOT EXISTS public.exams (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    date DATE,
    department TEXT,
    semester INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create marks table
CREATE TABLE IF NOT EXISTS public.marks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registration_no TEXT NOT NULL,
    exam_id UUID NOT NULL,
    subject TEXT NOT NULL,
    mark INTEGER NOT NULL,
    out_of INTEGER NOT NULL DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Foreign key constraints
    CONSTRAINT fk_marks_student 
        FOREIGN KEY (registration_no) 
        REFERENCES students(registration_no) 
        ON DELETE CASCADE,
    CONSTRAINT fk_marks_exam 
        FOREIGN KEY (exam_id) 
        REFERENCES exams(id) 
        ON DELETE CASCADE,
    
    -- Unique constraint to prevent duplicate marks for same student/exam/subject
    CONSTRAINT unique_student_exam_subject 
        UNIQUE (registration_no, exam_id, subject)
);

-- Enable RLS
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marks ENABLE ROW LEVEL SECURITY;

-- Create policies for exams
CREATE POLICY "Exams are viewable by authenticated users" ON public.exams
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Exams can be managed by authenticated users" ON public.exams
    FOR ALL USING (auth.role() = 'authenticated');

-- Create policies for marks
CREATE POLICY "Marks are viewable by authenticated users" ON public.marks
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Marks can be managed by authenticated users" ON public.marks
    FOR ALL USING (auth.role() = 'authenticated');

-- Insert sample exams
INSERT INTO public.exams (name, date, department, semester) VALUES
('Model Exam 1', '2025-08-15', 'computer science and engineering', 5),
('Model Exam 2', '2025-09-15', 'computer science and engineering', 5),
('Mid Semester Exam', '2025-08-01', 'computer science and engineering', 5),
('End Semester Exam', '2025-12-01', 'computer science and engineering', 5)
ON CONFLICT DO NOTHING;

-- Insert some sample marks (optional)
INSERT INTO public.marks (registration_no, exam_id, subject, mark, out_of) 
SELECT 
    s.registration_no,
    e.id,
    'Mathematics',
    FLOOR(RANDOM() * 40 + 60)::INTEGER, -- Random marks between 60-100
    100
FROM students s 
CROSS JOIN exams e 
WHERE s.current_semester = 5 
  AND s.department ILIKE '%computer science%'
  AND e.name = 'Model Exam 1'
LIMIT 20
ON CONFLICT (registration_no, exam_id, subject) DO NOTHING;

-- Verify tables were created
SELECT 'Exams table:' as info;
SELECT COUNT(*) as exam_count FROM exams;
SELECT 'Marks table:' as info;  
SELECT COUNT(*) as marks_count FROM marks;
