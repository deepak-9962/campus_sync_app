-- Fix Row Level Security for class_schedule table
-- This will allow admin and staff users to manage timetables

-- First, let's check if the class_schedule table exists and create it if needed
CREATE TABLE IF NOT EXISTS class_schedule (
    id BIGSERIAL PRIMARY KEY,
    department TEXT NOT NULL,
    semester INTEGER NOT NULL,
    section TEXT NOT NULL,
    day_of_week TEXT NOT NULL,
    period_number INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    subject_code TEXT NOT NULL,
    room TEXT DEFAULT '',
    faculty_name TEXT DEFAULT '',
    batch TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on class_schedule table
ALTER TABLE class_schedule ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view class schedules" ON class_schedule;
DROP POLICY IF EXISTS "Admin and staff can manage class schedules" ON class_schedule;
DROP POLICY IF EXISTS "Admin can manage all class schedules" ON class_schedule;
DROP POLICY IF EXISTS "Staff can manage class schedules" ON class_schedule;

-- Policy 1: Allow all authenticated users to view class schedules
CREATE POLICY "Users can view class schedules" ON class_schedule
    FOR SELECT TO authenticated
    USING (true);

-- Policy 2: Allow admin users to do everything (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Admin can manage all class schedules" ON class_schedule
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Policy 3: Allow staff users to insert, update, and delete class schedules
CREATE POLICY "Staff can manage class schedules" ON class_schedule
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'staff'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'staff'
        )
    );

-- Also ensure the subjects table has proper RLS
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for subjects
DROP POLICY IF EXISTS "Users can view subjects" ON subjects;
DROP POLICY IF EXISTS "Admin and staff can manage subjects" ON subjects;

-- Allow all authenticated users to view subjects
CREATE POLICY "Users can view subjects" ON subjects
    FOR SELECT TO authenticated
    USING (true);

-- Allow admin and staff to manage subjects
CREATE POLICY "Admin and staff can manage subjects" ON subjects
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'staff')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'staff')
        )
    );

-- Add updated_at trigger for class_schedule
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS update_class_schedule_updated_at ON class_schedule;
CREATE TRIGGER update_class_schedule_updated_at
    BEFORE UPDATE ON class_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify the current user's role
SELECT 
    auth.uid() as user_id,
    users.email,
    users.role
FROM users 
WHERE users.id = auth.uid();
