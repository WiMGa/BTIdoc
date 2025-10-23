-- Поиск этапов работы с прогнозами
SELECT
  s."tmCreated",
  s."sStageType",
  s."sTitle",
  LEFT(s."sDescription", 200) as description_preview
FROM "CC_Stage_Summary" s
WHERE s."sDescription" ILIKE '%прогноз%'
   OR s."sDescription" ILIKE '%оптимальн%'
   OR s."sTitle" ILIKE '%прогноз%'
ORDER BY s."tmCreated" DESC
LIMIT 10;