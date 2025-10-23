SELECT "sContent"
FROM "CC_Messages"
WHERE "sContent" ILIKE '%прогноз%'
   OR "sContent" ILIKE '%точност%'
   OR "sContent" ILIKE '%оптимальн%'
ORDER BY "iMessageId" ASC
LIMIT 10;