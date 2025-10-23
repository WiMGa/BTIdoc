SELECT 'CC_Messages' as table_name, COUNT(*) as records FROM "CC_Messages"
UNION ALL
SELECT 'CC_Sessions', COUNT(*) FROM "CC_Sessions"
UNION ALL
SELECT 'CC_Projects', COUNT(*) FROM "CC_Projects"
UNION ALL
SELECT 'BTI_Master_Tree', COUNT(*) FROM "BTI_Master_Tree"
UNION ALL
SELECT 'BTI_Evolution_Log', COUNT(*) FROM "BTI_Evolution_Log"
UNION ALL
SELECT 'Tasks', COUNT(*) FROM "Tasks"
ORDER BY records DESC;