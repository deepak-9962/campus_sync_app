-- Check the actual structure of daily_attendance table
SELECT 'Daily attendance table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'daily_attendance' 
ORDER BY ordinal_position;
