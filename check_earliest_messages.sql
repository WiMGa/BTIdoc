-- Проверка самых ранних сообщений в системе
SELECT
  MIN(m."tmMessage") as earliest_message,
  MAX(m."tmMessage") as latest_message,
  COUNT(*) as total_messages
FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
JOIN "CC_Projects" p ON s."iProjectId" = p."iProjectId"
WHERE p."sProject" = 'BTIdoc';