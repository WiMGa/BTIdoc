-- МИНИМАЛЬНАЯ СИСТЕМА КОНТРОЛЯ - только 3 обязательных действия

-- 1. СТАРТОВЫЙ ЗАПРОС - загрузить критичные ошибки в память сеанса
-- Использовать в начале каждого сеанса Claude
SELECT
  "sErrorType",
  "sDescription",
  "iOccurrenceCount"
FROM "BTI_Error_Patterns"
WHERE "bCritical" = true
  AND "iOccurrenceCount" >= 3
ORDER BY "iOccurrenceCount" DESC
LIMIT 5;

-- 2. БЫСТРАЯ ПРОВЕРКА БЗ - когда нужно найти готовое решение
-- Заменить {keyword} на нужную тему
SELECT
  "sTitle",
  LEFT("sContent", 200) as solution_preview
FROM "BTI_Master_Tree"
WHERE "sKeywords" ILIKE '%{keyword}%'
   OR "sContent" ILIKE '%{keyword}%'
ORDER BY "sPriority" DESC
LIMIT 3;

-- 3. ЛОГИРОВАНИЕ НОВОЙ ОШИБКИ - только если ошибка НОВАЯ
-- Заменить {error_type} и {description} на актуальные
INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "bCritical")
VALUES ('{error_type}', '{description}', true)
ON CONFLICT ("sErrorType") DO UPDATE SET
  "iOccurrenceCount" = "BTI_Error_Patterns"."iOccurrenceCount" + 1,
  "tmLastOccurrence" = NOW();