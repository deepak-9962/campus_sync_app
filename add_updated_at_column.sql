-- Add missing updated_at column to class_schedule table
-- This SQL script adds the proper updated_at column and trigger for automatic timestamp updates

-- Add updated_at column to class_schedule table
ALTER TABLE class_schedule 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing records to have current timestamp
UPDATE class_schedule 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Create or replace function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at when record is modified
DROP TRIGGER IF EXISTS update_class_schedule_updated_at ON class_schedule;
CREATE TRIGGER update_class_schedule_updated_at
    BEFORE UPDATE ON class_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify the column was added successfully
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'class_schedule' 
AND column_name = 'updated_at';
