-- Поиск записей в BTI_Evolution_Log о прогнозах
SELECT
  "tmEvent",
  "sEvent",
  LEFT("sDescription", 300) as description_preview
FROM "BTI_Evolution_Log"
WHERE "sDescription" ILIKE '%прогноз%'
   OR "sDescription" ILIKE '%оптимальн%'
   OR "sDescription" ILIKE '%определя%'
   OR "sEvent" ILIKE '%прогноз%'
ORDER BY "tmEvent" DESC
LIMIT 10;