UPDATE "CC_Messages"
SET "sWindowTitle" = (
    SELECT TRIM(SUBSTRING(line FROM 'WINDOW:\s*(.*)$'))
    FROM unnest(string_to_array("sContent", E'\r\n')) AS line
    WHERE line ~ '^.*WINDOW:\s*.*$'
    LIMIT 1
)
WHERE "sContent" LIKE '%WINDOW:%';