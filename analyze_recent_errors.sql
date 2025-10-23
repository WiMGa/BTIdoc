-- Анализ последних ошибок из mess-log для выявления паттернов

-- 1. Последние сообщения с ошибками
SELECT
  m."tmMessage",
  m."sType",
  LEFT(m."sContent", 100) as error_preview,
  p."sProject"
FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
JOIN "CC_Projects" p ON s."iProjectId" = p."iProjectId"
WHERE m."sContent" ILIKE '%ошибка%'
   OR m."sContent" ILIKE '%error%'
   OR m."sContent" ILIKE '%fail%'
   OR m."sContent" ILIKE '%блядь%'
   OR m."sContent" ILIKE '%срать%'
ORDER BY m."tmMessage" DESC
LIMIT 20;