SELECT "sTitle", "sContent"
FROM "BTI_Master_Tree"
WHERE "sSection" = 'TROUBLESHOOT'
   OR "sKeywords" ILIKE '%curl%'
   OR "sKeywords" ILIKE '%json%'
   OR "sKeywords" ILIKE '%экранирование%'
ORDER BY "sPriority" DESC;