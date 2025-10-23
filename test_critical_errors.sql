-- ТЕСТ: Загрузка критичных ошибок в память сеанса
SELECT
  "sErrorType",
  "sDescription",
  "iOccurrenceCount"
FROM "BTI_Error_Patterns"
WHERE "bCritical" = true
  AND "iOccurrenceCount" >= 3
ORDER BY "iOccurrenceCount" DESC
LIMIT 5;