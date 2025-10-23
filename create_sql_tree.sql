-- Создание дерева SQL запросов в БЗ для переиспользования
-- Цель: Не создавать SQL с нуля, а использовать готовые шаблоны

INSERT INTO "BTI_Master_Tree"
("sSection", "sTaskType", "sTitle", "sContent", "sKeywords", "sPriority")
VALUES

-- === РАЗДЕЛ: SQL_СТАТИСТИКА ===
('SQL_СТАТИСТИКА', 'TEMPLATE', 'Подсчёт записей в таблице',
'SELECT COUNT(*) as record_count FROM "{table_name}";',
'count,записи,количество,статистика', 'HIGH'),

('SQL_СТАТИСТИКА', 'TEMPLATE', 'Статистика Tasks BTI',
'SELECT
  COUNT(*) as total_tasks,
  COUNT(CASE WHEN "sStatus" = ''new'' THEN 1 END) as new_tasks,
  COUNT(CASE WHEN "sStatus" = ''processing'' THEN 1 END) as processing_tasks,
  COUNT(CASE WHEN "sStatus" = ''completed'' THEN 1 END) as completed_tasks
FROM "Tasks";',
'tasks,статистика,задачи,bti', 'HIGH'),

('SQL_СТАТИСТИКА', 'TEMPLATE', 'Статистика сессий CC',
'SELECT
  p."sProject",
  COUNT(s."iSessionId") as session_count,
  COUNT(m."iMessageId") as message_count
FROM "CC_Projects" p
LEFT JOIN "CC_Sessions" s ON p."iProjectId" = s."iProjectId"
LEFT JOIN "CC_Messages" m ON s."iSessionId" = m."iSessionId"
GROUP BY p."sProject"
ORDER BY message_count DESC;',
'cc,sessions,messages,статистика', 'HIGH'),

-- === РАЗДЕЛ: SQL_СТРУКТУРА ===
('SQL_СТРУКТУРА', 'TEMPLATE', 'Список таблиц PostgreSQL',
'SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = ''public''
ORDER BY table_name;',
'таблицы,структура,schema,postgresql', 'HIGH'),

('SQL_СТРУКТУРА', 'TEMPLATE', 'Столбцы таблицы',
'SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = ''{table_name}''
ORDER BY ordinal_position;',
'столбцы,структура,columns,таблица', 'HIGH'),

('SQL_СТРУКТУРА', 'TEMPLATE', 'Индексы таблицы',
'SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = ''{table_name}'';',
'индексы,indexes,производительность', 'HIGH'),

-- === РАЗДЕЛ: SQL_ОПЕРАЦИИ ===
('SQL_ОПЕРАЦИИ', 'TEMPLATE', 'Вставка в BTI_Master_Tree',
'INSERT INTO "BTI_Master_Tree"
("sSection", "sTaskType", "sTitle", "sContent", "sKeywords", "sPriority")
VALUES (''{section}'', ''{task_type}'', ''{title}'', ''{content}'', ''{keywords}'', ''{priority}'');',
'insert,добавление,bti_master_tree,бз', 'HIGH'),

('SQL_ОПЕРАЦИИ', 'TEMPLATE', 'Обновление приоритета в БЗ',
'UPDATE "BTI_Master_Tree"
SET "sPriority" = ''{new_priority}''
WHERE "sSection" = ''{section}'' AND "sTitle" = ''{title}'';',
'update,обновление,приоритет,бз', 'HIGH'),

('SQL_ОПЕРАЦИИ', 'TEMPLATE', 'Логирование события',
'INSERT INTO "BTI_Evolution_Log" ("sEvent", "sDescription")
VALUES (''{event}'', ''{description}'');',
'log,событие,эволюция,логирование', 'HIGH'),

-- === РАЗДЕЛ: SQL_ПОИСК ===
('SQL_ПОИСК', 'TEMPLATE', 'Поиск в БЗ по ключевым словам',
'SELECT "sSection", "sTitle", "sContent", "sPriority"
FROM "BTI_Master_Tree"
WHERE "sKeywords" ILIKE ''%{keyword}%'' OR "sContent" ILIKE ''%{keyword}%''
ORDER BY "sPriority" DESC, "sSection";',
'поиск,search,keywords,бз', 'HIGH'),

('SQL_ПОИСК', 'TEMPLATE', 'Поиск ошибок по типу',
'SELECT "sErrorType", "sDescription", "iOccurrenceCount", "tmLastOccurrence"
FROM "BTI_Error_Patterns"
WHERE "sErrorType" ILIKE ''%{error_type}%''
ORDER BY "iOccurrenceCount" DESC;',
'ошибки,errors,patterns,debug', 'HIGH'),

('SQL_ПОИСК', 'TEMPLATE', 'Последние события эволюции',
'SELECT "tmEvent", "sEvent", "sDescription"
FROM "BTI_Evolution_Log"
ORDER BY "tmEvent" DESC
LIMIT {limit_count};',
'события,evolution,история,последние', 'HIGH'),

-- === РАЗДЕЛ: SQL_БЕЗОПАСНОСТЬ ===
('SQL_БЕЗОПАСНОСТЬ', 'TEMPLATE', 'Проверка перед удалением',
'SELECT
  ''{table_name}'' as table_to_delete,
  COUNT(*) as records_count,
  ''WARNING: будет удалено записей'' as warning
FROM "{table_name}";',
'delete,удаление,безопасность,проверка', 'HIGH'),

('SQL_БЕЗОПАСНОСТЬ', 'TEMPLATE', 'Бэкап таблицы перед изменением',
'CREATE TABLE "{table_name}_backup" AS
SELECT * FROM "{table_name}";',
'backup,бэкап,безопасность,копия', 'HIGH'),

-- === РАЗДЕЛ: SQL_МОНИТОРИНГ ===
('SQL_МОНИТОРИНГ', 'TEMPLATE', 'Размеры таблиц PostgreSQL',
'SELECT
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats
WHERE schemaname = ''public''
ORDER BY tablename;',
'размеры,мониторинг,производительность,pg_stats', 'HIGH'),

('SQL_МОНИТОРИНГ', 'TEMPLATE', 'Активные подключения PostgreSQL',
'SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start
FROM pg_stat_activity
WHERE state = ''active'';',
'подключения,connections,мониторинг,активность', 'HIGH'),

-- === РАЗДЕЛ: SQL_АНАЛИТИКА ===
('SQL_АНАЛИТИКА', 'TEMPLATE', 'Топ ошибок по частоте',
'SELECT
  "sErrorType",
  "iOccurrenceCount",
  "tmLastOccurrence",
  "bCritical"
FROM "BTI_Error_Patterns"
ORDER BY "iOccurrenceCount" DESC, "tmLastOccurrence" DESC
LIMIT {limit_count};',
'аналитика,ошибки,топ,частота', 'HIGH'),

('SQL_АНАЛИТИКА', 'TEMPLATE', 'Статистика по секциям БЗ',
'SELECT
  "sSection",
  COUNT(*) as records_count,
  COUNT(CASE WHEN "sPriority" = ''HIGH'' THEN 1 END) as high_priority,
  MAX("sPriority") as max_priority
FROM "BTI_Master_Tree"
GROUP BY "sSection"
ORDER BY records_count DESC;',
'аналитика,бз,секции,статистика', 'HIGH');