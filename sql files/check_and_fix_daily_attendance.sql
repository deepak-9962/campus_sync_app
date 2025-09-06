-- Check current daily_attendance table schema
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_attendance'
ORDER BY ordinal_position;

-- Add missing attendance_percentage column if it doesn't exist
ALTER TABLE daily_attendance 
ADD COLUMN IF NOT EXISTS attendance_percentage DECIMAL(5,2) DEFAULT 0.0;

-- Update existing records to calculate attendance_percentage
UPDATE daily_attendance 
SET attendance_percentage = CASE 
    WHEN is_present = true THEN 100.0 
    ELSE 0.0 
END
WHERE attendance_percentage IS NULL OR attendance_percentage = 0;

-- Show updated schema
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_attendance'
ORDER BY ordinal_position;

-- Show sample data
SELECT * FROM daily_attendance LIMIT 5;
