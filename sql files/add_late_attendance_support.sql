-- ============================================================
-- ADD LATE ATTENDANCE STATUS SUPPORT
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Add 'late' status to attendance table (if using CHECK constraint)
-- First, drop existing constraint if any
ALTER TABLE attendance 
DROP CONSTRAINT IF EXISTS attendance_status_check;

-- Add new constraint with 'late' status
ALTER TABLE attendance 
ADD CONSTRAINT attendance_status_check 
CHECK (status IN ('present', 'absent', 'late', 'excused'));

-- 2. Add tracking columns for edit history
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id);

ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS remarks TEXT;

-- 3. Add same columns to daily_attendance table
ALTER TABLE daily_attendance 
DROP CONSTRAINT IF EXISTS daily_attendance_status_check;

ALTER TABLE daily_attendance 
ADD CONSTRAINT daily_attendance_status_check 
CHECK (status IN ('present', 'absent', 'late', 'excused'));

ALTER TABLE daily_attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE daily_attendance 
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id);

ALTER TABLE daily_attendance 
ADD COLUMN IF NOT EXISTS remarks TEXT;

-- 4. Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
CREATE INDEX IF NOT EXISTS idx_attendance_date_period ON attendance(date, period);
CREATE INDEX IF NOT EXISTS idx_attendance_department_semester ON attendance(department, semester, section);

CREATE INDEX IF NOT EXISTS idx_daily_attendance_status ON daily_attendance(status);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_date ON daily_attendance(date);
CREATE INDEX IF NOT EXISTS idx_daily_attendance_department_semester ON daily_attendance(department, semester, section);

-- 5. Create function to update timestamp on edit
CREATE OR REPLACE FUNCTION update_attendance_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger for attendance table
DROP TRIGGER IF EXISTS attendance_update_timestamp ON attendance;
CREATE TRIGGER attendance_update_timestamp
  BEFORE UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_attendance_timestamp();

-- 7. Create trigger for daily_attendance table
DROP TRIGGER IF EXISTS daily_attendance_update_timestamp ON daily_attendance;
CREATE TRIGGER daily_attendance_update_timestamp
  BEFORE UPDATE ON daily_attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_attendance_timestamp();

-- 8. (Optional) Create audit history table for tracking all changes
CREATE TABLE IF NOT EXISTS attendance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id UUID NOT NULL,
  table_name TEXT NOT NULL, -- 'attendance' or 'daily_attendance'
  old_status TEXT,
  new_status TEXT,
  remarks TEXT,
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Create index on history table
CREATE INDEX IF NOT EXISTS idx_attendance_history_attendance_id ON attendance_history(attendance_id);
CREATE INDEX IF NOT EXISTS idx_attendance_history_changed_at ON attendance_history(changed_at);

-- 10. Create function to log attendance changes
CREATE OR REPLACE FUNCTION log_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO attendance_history (attendance_id, table_name, old_status, new_status, remarks, changed_by)
    VALUES (NEW.id, TG_TABLE_NAME, OLD.status, NEW.status, NEW.remarks, NEW.updated_by);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Create trigger to log changes on attendance table
DROP TRIGGER IF EXISTS log_attendance_changes ON attendance;
CREATE TRIGGER log_attendance_changes
  AFTER UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION log_attendance_change();

-- 12. Create trigger to log changes on daily_attendance table
DROP TRIGGER IF EXISTS log_daily_attendance_changes ON daily_attendance;
CREATE TRIGGER log_daily_attendance_changes
  AFTER UPDATE ON daily_attendance
  FOR EACH ROW
  EXECUTE FUNCTION log_attendance_change();

-- 13. Update RLS policies for editing attendance (Staff, Admin, HOD can edit)
-- First enable RLS if not already
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_history ENABLE ROW LEVEL SECURITY;

-- Policy for staff/admin/hod to update attendance
DROP POLICY IF EXISTS attendance_update_policy ON attendance;
CREATE POLICY attendance_update_policy ON attendance
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('staff', 'admin', 'hod', 'faculty')
    )
  );

DROP POLICY IF EXISTS daily_attendance_update_policy ON daily_attendance;
CREATE POLICY daily_attendance_update_policy ON daily_attendance
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('staff', 'admin', 'hod', 'faculty')
    )
  );

-- Policy for viewing attendance history
DROP POLICY IF EXISTS attendance_history_select_policy ON attendance_history;
CREATE POLICY attendance_history_select_policy ON attendance_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('staff', 'admin', 'hod', 'faculty')
    )
  );

-- Policy for inserting into history (triggered by system)
DROP POLICY IF EXISTS attendance_history_insert_policy ON attendance_history;
CREATE POLICY attendance_history_insert_policy ON attendance_history
  FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Check if columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'attendance' 
AND column_name IN ('updated_at', 'updated_by', 'remarks');

-- Check constraints
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname LIKE '%attendance%status%';

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================
SELECT 'Late attendance status support added successfully!' as message;
