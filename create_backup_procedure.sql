CREATE OR REPLACE FUNCTION backup_cc_tables()
RETURNS TEXT AS $$
DECLARE
    backup_suffix TEXT := '_backup_' || to_char(now(), 'YYYYMMDD_HH24MI');
BEGIN
    EXECUTE 'DROP TABLE IF EXISTS "CC_Messages' || backup_suffix || '"';
    EXECUTE 'CREATE TABLE "CC_Messages' || backup_suffix || '" AS SELECT * FROM "CC_Messages"';

    EXECUTE 'DROP TABLE IF EXISTS "CC_Sessions' || backup_suffix || '"';
    EXECUTE 'CREATE TABLE "CC_Sessions' || backup_suffix || '" AS SELECT * FROM "CC_Sessions"';

    EXECUTE 'DROP TABLE IF EXISTS "CC_Projects' || backup_suffix || '"';
    EXECUTE 'CREATE TABLE "CC_Projects' || backup_suffix || '" AS SELECT * FROM "CC_Projects"';

    RETURN 'Backup completed: ' || backup_suffix;
END;
$$ LANGUAGE plpgsql;