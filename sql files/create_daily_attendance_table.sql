-- Create daily_attendance table for day-wise attendance tracking

-- Create daily_attendance table
CREATE TABLE IF NOT EXISTS public.daily_attendance (
    id BIGSERIAL PRIMARY KEY,
    registration_no TEXT NOT NULL,
    date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT false,
    marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    marked_by TEXT DEFAULT auth.email(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique attendance record per student per day
    UNIQUE(registration_no, date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_daily_attendance_reg_no ON public.daily_attendance (registration_no);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_date ON public.daily_attendance (date);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_reg_date ON public.daily_attendance (registration_no, date);

-- Enable Row Level Security
ALTER TABLE public.daily_attendance ENABLE ROW LEVEL SECURITY;

-- Create policies for daily_attendance table

-- Policy for admins (full access)
CREATE POLICY "Admins can manage all daily attendance" ON public.daily_attendance
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_email = auth.email() 
        AND role = 'admin'
    )
);

-- Policy for staff (can mark and view attendance)
CREATE POLICY "Staff can manage daily attendance" ON public.daily_attendance
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_email = auth.email() 
        AND role IN ('staff', 'admin')
    )
);

-- Policy for students (can only view their own attendance)
CREATE POLICY "Students can view their own daily attendance" ON public.daily_attendance
FOR SELECT USING (
    registration_no = (
        SELECT registration_no FROM public.students 
        WHERE email = auth.email()
    )
);

-- Create trigger to update updated_at column
CREATE OR REPLACE FUNCTION update_daily_attendance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_daily_attendance_updated_at
    BEFORE UPDATE ON public.daily_attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_attendance_updated_at();

-- Grant necessary permissions
GRANT ALL ON public.daily_attendance TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.daily_attendance_id_seq TO authenticated;

-- Insert some test data (optional)
-- INSERT INTO public.daily_attendance (registration_no, date, is_present) VALUES
-- ('2021CSEA001', '2025-08-07', true),
-- ('2021CSEA002', '2025-08-07', true),
-- ('2021CSEA003', '2025-08-07', false);

-- Query to verify the table creation
-- SELECT * FROM public.daily_attendance LIMIT 5;

COMMENT ON TABLE public.daily_attendance IS 'Daily attendance records for students - tracks full day presence/absence';
COMMENT ON COLUMN public.daily_attendance.registration_no IS 'Student registration number';
COMMENT ON COLUMN public.daily_attendance.date IS 'Date of attendance';
COMMENT ON COLUMN public.daily_attendance.is_present IS 'Whether student was present for the day';
COMMENT ON COLUMN public.daily_attendance.marked_by IS 'Email of staff who marked the attendance';
