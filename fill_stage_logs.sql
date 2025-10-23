-- Заполнение CC_Stage_Logs из текущего сеанса

-- ЭТАП 1: Восстановление mess-log системы
INSERT INTO "CC_Stage_Logs"
("iSessionId", "tmStageStart", "tmStageEnd", "sStageName", "sObjectives", "sAchievements", "sProblems", "sLessonsLearned", "iMessagesCount", "iErrorsCount", "sNextSteps")
VALUES (
  (SELECT MAX("iSessionId") FROM "CC_Sessions" WHERE "sMainHwnd" LIKE '%BTIdoc%'),
  '2025-09-26 18:00:00',
  '2025-09-26 18:20:00',
  'Восстановление mess-log системы',
  'Оптимизировать структуру БД mess-log, исправить BTI_API, мигрировать claude_dialogs.txt',
  'CC_Projects→CC_Sessions→CC_Messages восстановлена, BTI_API использует log_message(), 1155 сообщений мигрировано',
  'Случайное удаление CC_Projects с CASCADE, проблемы кодировки UTF-8, curl JSON экранирование',
  'Никогда не делать CASCADE без согласования, использовать SQL файлы вместо curl JSON',
  50, 4,
  'Создать активную БЗ систему'
);

-- ЭТАП 2: Создание активной БЗ системы
INSERT INTO "CC_Stage_Logs"
("iSessionId", "tmStageStart", "tmStageEnd", "sStageName", "sObjectives", "sAchievements", "sProblems", "sLessonsLearned", "iMessagesCount", "iErrorsCount", "sNextSteps")
VALUES (
  (SELECT MAX("iSessionId") FROM "CC_Sessions" WHERE "sMainHwnd" LIKE '%BTIdoc%'),
  '2025-09-26 18:20:00',
  '2025-09-26 18:50:00',
  'Активная БЗ с принудительными проверками',
  'Создать БЗ которая предотвращает повторение ошибок ИИ',
  'BTI_Workflow_Rules и BTI_Error_Patterns созданы, SQL дерево из 18 шаблонов, минимальная система контроля',
  'execute_sql_file не возвращает результаты SELECT, проблемы с добавлением данных',
  'Использовать query_database для SELECT, execute_sql_file только для операций',
  40, 3,
  'Обновить правила общения'
);

-- ЭТАП 3: Обновление правил общения
INSERT INTO "CC_Stage_Logs"
("iSessionId", "tmStageStart", "tmStageEnd", "sStageName", "sObjectives", "sAchievements", "sProblems", "sLessonsLearned", "iMessagesCount", "iErrorsCount", "sNextSteps")
VALUES (
  (SELECT MAX("iSessionId") FROM "CC_Sessions" WHERE "sMainHwnd" LIKE '%BTIdoc%'),
  '2025-09-26 18:50:00',
  '2025-09-26 19:10:00',
  'Обновление правил общения на основе реальных ошибок',
  'Дополнить правила критичными пунктами из анализа mess-log',
  'Правила дополнены 4 критичными пунктами, перенесены в БЗ PostgreSQL вместо локальных файлов',
  'Игнорирование повторяющихся вопросов пользователя, чтение локальных файлов вместо БЗ',
  'Концентрироваться на каждом вопросе, всегда использовать БЗ PostgreSQL как единый источник',
  25, 2,
  'Практическое применение новой системы'
);