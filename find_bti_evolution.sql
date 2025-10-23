SELECT "tmEvent", "sEvent", "sDescription"
FROM "BTI_Evolution_Log"
WHERE "sDescription" ILIKE '%bti%'
   OR "sDescription" ILIKE '%knn%'
   OR "sDescription" ILIKE '%tpsl%'
   OR "sDescription" ILIKE '%logic%'
   OR "sDescription" ILIKE '%логик%'
ORDER BY "tmEvent" DESC;