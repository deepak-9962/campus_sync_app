-- Check the structure of the summary tables
SELECT 'daily_attendance columns:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_attendance' 
ORDER BY ordinal_position;

SELECT 'overall_attendance_summary columns:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'overall_attendance_summary' 
ORDER BY ordinal_position;
