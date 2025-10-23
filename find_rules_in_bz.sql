SELECT "sTitle", "sContent"
FROM "BTI_Master_Tree"
WHERE "sSection" = 'RULES'
   OR "sKeywords" ILIKE '%правила%'
   OR "sKeywords" ILIKE '%общение%'
   OR "sKeywords" ILIKE '%диалог%';