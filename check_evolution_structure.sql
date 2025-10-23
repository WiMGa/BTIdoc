SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'BTI_Evolution_Log'
ORDER BY ordinal_position;