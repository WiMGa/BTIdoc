SELECT "sTitle", "sContent"
FROM "BTI_Master_Tree"
WHERE "sKeywords" ILIKE '%curl%'
   OR "sKeywords" ILIKE '%json%'
   OR "sKeywords" ILIKE '%экранирование%'
   OR "sSection" = 'TROUBLESHOOT';