INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "iOccurrenceCount", "bCritical", "sLastContext")
VALUES
('ignoring_repeated_questions',
 'Игнорирование повторяющихся вопросов пользователя пока он не разозлится. Пользователь 3 раза спрашивал про лог ошибок.',
 1, true,
 'Сеанс активной БЗ - игнорировала вопрос про логирование ошибок до взрыва пользователя');