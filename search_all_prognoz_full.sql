-- Поиск ВСЕХ сообщений о прогнозах с САМОГО НАЧАЛА во ВСЕХ проектах
SELECT
  p."sProject",
  m."tmMessage",
  m."sType",
  LEFT(m."sContent", 250) as content_preview
FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
JOIN "CC_Projects" p ON s."iProjectId" = p."iProjectId"
WHERE m."sContent" ILIKE '%прогноз%'
   OR m."sContent" ILIKE '%оптимальн%'
   OR m."sContent" ILIKE '%определ%'
   OR m."sContent" ILIKE '%лучш%'
   OR m."sContent" ILIKE '%точност%'
   OR m."sContent" ILIKE '%критер%'
   OR m."sContent" ILIKE '%резудльтат%'
   OR m."sContent" ILIKE '%результат%'
ORDER BY m."tmMessage" ASC;