-- Query 3: Check all tables with subject_code columns
SELECT 'All tables with subject_code columns:' as info;
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE column_name = 'subject_code'
ORDER BY table_name;
