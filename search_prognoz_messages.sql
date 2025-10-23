SELECT
  m."tmMessage",
  m."sType",
  LEFT(m."sContent", 300) as content_preview
FROM "CC_Messages" m
WHERE m."sContent" ILIKE '%прогноз%'
   OR m."sContent" ILIKE '%оптимальный%'
   OR m."sContent" ILIKE '%определять%'
ORDER BY m."tmMessage" DESC
LIMIT 15;