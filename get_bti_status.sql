-- Восстановление состояния BTI системы из БЗ

SELECT "sTitle", "sContent"
FROM "BTI_Master_Tree"
WHERE "sKeywords" ILIKE '%bti%'
   OR "sKeywords" ILIKE '%task%'
   OR "sKeywords" ILIKE '%equity%'
   OR "sSection" = 'CORE'
ORDER BY "sPriority" DESC;