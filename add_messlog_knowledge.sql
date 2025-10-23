-- Добавление итогов этапа восстановления mess-log в БЗ

INSERT INTO "BTI_Master_Tree"
("sSection", "sTaskType", "sTitle", "sContent", "sKeywords", "sPriority")
VALUES

-- Основной итог этапа
('SYSTEM', 'COMPLETED', 'Mess-log система восстановлена 2025-09-26',
'Полное восстановление mess-log системы: CC_Projects → CC_Sessions → CC_Messages.
BTI_API использует функцию log_message() вместо сложного кода.
Миграция claude_dialogs.txt → PostgreSQL (1155 сообщений).
Кодировка UTF-8 с emoji исправлена.
DESC индексы для быстрого поиска последних сообщений.',
'mess-log,восстановление,миграция,кодировка,система', 'HIGH'),

-- Архитектурное решение
('ARCHITECTURE', 'PATTERN', 'Функция log_message() вместо сложного кода',
'Принцип: вся логика создания проектов/сессий/сообщений в одной PostgreSQL функции log_message().
Вместо 70+ строк C# кода - один вызов SELECT log_message(...).
Автоматическое создание связей CC_Projects → CC_Sessions → CC_Messages.',
'log_message,архитектура,postgresql,функция', 'HIGH'),

-- Проблема кодировки
('TECHNICAL', 'SOLUTION', 'Кодировка UTF-8 в Python Windows',
'Решение проблемы кодировки UTF-8 с emoji в Windows Python:
1. Чтение файла: encoding="utf-8-sig" (для BOM)
2. Вывод консоли: sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
3. Переменная: PYTHONIOENCODING=utf-8',
'кодировка,utf-8,python,windows,emoji', 'HIGH'),

-- Задача на будущее
('TODO', 'PLANNING', 'Реструктуризация приоритетов БЗ',
'Задача: обновить приоритеты в БЗ вместо удаления устаревших записей.
Новые актуальные знания → HIGH priority.
Устаревшие → LOW priority.
При DESC сортировке актуальные будут первыми.',
'бз,приоритеты,реструктуризация,планирование', 'MEDIUM');