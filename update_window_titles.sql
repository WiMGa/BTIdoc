UPDATE "CC_Messages"
SET "sWindowTitle" = CASE
    WHEN "sContent" ~ 'WINDOW: (.+)' THEN
        TRIM(regexp_replace("sContent", '.*WINDOW: ([^\r\n]+).*', '\1', 's'))
    ELSE NULL
END
WHERE "sContent" LIKE '%WINDOW:%';