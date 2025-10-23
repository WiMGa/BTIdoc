-- Проверка размера PostgreSQL БД и основных таблиц

-- Общий размер БД
SELECT
  pg_database.datname as database_name,
  pg_size_pretty(pg_database_size(pg_database.datname)) as size
FROM pg_database
WHERE datname = 'bti_db';

-- Размеры таблиц
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Количество записей в основных таблицах
SELECT 'CC_Messages' as table_name, COUNT(*) as records FROM "CC_Messages"
UNION ALL
SELECT 'CC_Sessions', COUNT(*) FROM "CC_Sessions"
UNION ALL
SELECT 'CC_Projects', COUNT(*) FROM "CC_Projects"
UNION ALL
SELECT 'BTI_Master_Tree', COUNT(*) FROM "BTI_Master_Tree"
UNION ALL
SELECT 'BTI_Evolution_Log', COUNT(*) FROM "BTI_Evolution_Log"
UNION ALL
SELECT 'Tasks', COUNT(*) FROM "Tasks"
ORDER BY records DESC;