-- Логирование исправления curl ошибки

INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "sPreventionQuery", "iOccurrenceCount", "sLastContext", "bCritical")
VALUES
('curl_json_escaping_fixed',
 'Исправлена ошибка JSON экранирования в curl - переход на SQL файлы',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%sql%'' AND "sSection" = ''TROUBLESHOOT''',
 1,
 'Создание SQL дерева - использован execute_sql_file вместо curl JSON',
 false)
ON CONFLICT ("sErrorType") DO UPDATE SET
  "iOccurrenceCount" = "BTI_Error_Patterns"."iOccurrenceCount" + 1,
  "tmLastOccurrence" = NOW(),
  "sLastContext" = EXCLUDED."sLastContext";