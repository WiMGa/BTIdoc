SELECT
  m."tmMessage",
  m."sType",
  LEFT(m."sContent", 200) as content_preview
FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
JOIN "CC_Projects" p ON s."iProjectId" = p."iProjectId"
WHERE p."sProject" = 'BTIdoc'
  AND (m."sContent" ILIKE '%прогноз%' OR m."sContent" ILIKE '%оптимальн%' OR m."sContent" ILIKE '%определ%')
ORDER BY m."tmMessage" DESC
LIMIT 50;