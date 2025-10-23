-- Поиск ВСЕХ сообщений о прогнозах с самого начала
SELECT
  m."tmMessage",
  m."sType",
  LEFT(m."sContent", 300) as content_preview
FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
JOIN "CC_Projects" p ON s."iProjectId" = p."iProjectId"
WHERE p."sProject" = 'BTIdoc'
  AND (m."sContent" ILIKE '%прогноз%'
       OR m."sContent" ILIKE '%оптимальн%'
       OR m."sContent" ILIKE '%определ%'
       OR m."sContent" ILIKE '%лучш%'
       OR m."sContent" ILIKE '%выбор%'
       OR m."sContent" ILIKE '%критер%')
ORDER BY m."tmMessage" ASC
LIMIT 50;