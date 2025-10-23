INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "iOccurrenceCount", "bCritical", "sLastContext")
VALUES
('query_database_failure',
 'query_database возвращает "CommandText property has not been initialized" - баг MCP сервера BTI_API',
 1, true,
 'Поиск сообщений о прогнозах в PostgreSQL БД - невозможно выполнить SELECT запросы');