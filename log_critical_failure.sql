INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "iOccurrenceCount", "bCritical", "sLastContext")
VALUES
('execute_sql_file_failure',
 'execute_sql_file не выполняет операции INSERT и не возвращает результаты. Пользователь указал на двойную ошибку.',
 1, true,
 'Добавление правил в БЗ - execute_sql_file не работает корректно с INSERT операциями');