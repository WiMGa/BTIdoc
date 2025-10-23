-- Временный SQL для переноса CCL документации в БЗ
-- ВЫПОЛНИТЬ ЧЕРЕЗ ПРЯМОЕ ПОДКЛЮЧЕНИЕ К PostgreSQL

INSERT INTO "BTI_Master_Tree"
("sSection", "sTaskType", "sTitle", "sContent", "sKeywords", "sPriority")
VALUES

-- CCL Архитектура
('SYSTEM', 'DOCS', 'CCL Архитектура',
'Claude Code Logger - система автозаписи диалогов CC в файлы и PostgreSQL.
Архитектура: Claude Code → хотки → CCL → парсинг → файл + HTTP → BTI_API → PostgreSQL.
Компоненты: ClaudeCodeLogger.exe, PostgreSQL bti_db, MCP /log_claude_dialog.
Статус: готов к эксплуатации. Версия 1.0.0',
'ccl,архитектура,система,документация', 'HIGH'),

-- CCL Таблицы БД
('SYSTEM', 'SCHEMA', 'CCL Структура БД',
'CC_Sessions: сессии диалогов (iSessionId, tmStart, sProject, sMainHwnd).
CC_Messages: сообщения (iMessageId, iSessionId, sType user/assistant, sContent, tmMessage).
Связь: CC_Messages.iSessionId → CC_Sessions.iSessionId.
Индексы по времени и сессиям для быстрого поиска.',
'ccl,бд,структура,таблицы', 'HIGH'),

-- CCL Управление
('SYSTEM', 'USAGE', 'CCL Управление',
'Хотки: Ctrl+Shift+S (ручное сохранение, не работает в трее), Enter (авто, работает всегда).
Настройки: hideTray (трей), Save on Enter (авто).
Принцип: мониторинг CC окон → захват диалога → парсинг → дублирование защита → сохранение.',
'ccl,управление,хотки,настройки', 'HIGH'),

-- CCL Статистика
('SYSTEM', 'STATUS', 'CCL Статистика 2024-09-25',
'Сессии: 3+ активных. Сообщения: 80+ записано. Размер БД: 12 MB.
Надёжность: 99% (Enter работает, Ctrl+Shift+S проблема в трее).
Файлы: claude_dialogs.txt растёт. Резерв работает.',
'ccl,статистика,производительность', 'MEDIUM');