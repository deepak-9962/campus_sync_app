-- Query 2: Check foreign key dependencies
SELECT 'Tables that reference subjects.subject_code:' as info;
SELECT 
    tc.table_name AS referencing_table, 
    kcu.column_name AS referencing_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
      AND ccu.table_name = 'subjects'
      AND ccu.column_name = 'subject_code';
