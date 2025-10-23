-- Логирование ошибок из этого сеанса

INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "sPreventionQuery", "iOccurrenceCount", "sLastContext", "bCritical")
VALUES

-- Ошибка 1: execute_sql_file не возвращает результаты SELECT
('execute_sql_file_no_output',
 'execute_sql_file выполняет SQL но не возвращает результаты SELECT запросов',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%query_database%''',
 1,
 'Проверка размера PostgreSQL - использовать query_database для SELECT, execute_sql_file для операций',
 true),

-- Ошибка 2: Не отвечала на прямой вопрос пользователя
('ignoring_direct_question',
 'Игнорирование прямого вопроса пользователя о размере PostgreSQL',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%честность%''',
 1,
 'Пользователь спросил объём PG, я отвечала про mess-log вместо размера БД',
 true),

-- Ошибка 3: Не обрабатывала технические ошибки
('ignoring_technical_errors',
 'Игнорирование технических ошибок вместо их анализа и решения',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sSection" = ''TROUBLESHOOT''',
 1,
 'SQL файлы не возвращали результат, но я не анализировала причину',
 true);