-- Создание активной системы БЗ с принудительными проверками
-- Цель: Предотвращение циклов повторяющихся ошибок Claude

-- 1. ТАБЛИЦА WORKFLOW ПРАВИЛ - принудительные проверки перед действиями
CREATE TABLE IF NOT EXISTS "BTI_Workflow_Rules" (
    "iRuleId" SERIAL PRIMARY KEY,
    "sActionType" VARCHAR(50) NOT NULL, -- 'EDIT_CODE', 'DELETE_TABLE', 'API_CALL', 'CURL_REQUEST'
    "sKeywordTriggers" TEXT[] NOT NULL, -- массив триггер-слов для активации правила
    "sMandatoryCheck" TEXT NOT NULL, -- обязательный SQL запрос для проверки
    "sFailureAction" VARCHAR(20) DEFAULT 'WARN', -- 'BLOCK', 'WARN', 'LOG'
    "sErrorMessage" TEXT, -- сообщение при срабатывании
    "iPriority" INTEGER DEFAULT 1, -- приоритет проверки (1=критичный)
    "bActive" BOOLEAN DEFAULT true,
    "tmCreated" TIMESTAMP DEFAULT NOW()
);

-- 2. ТАБЛИЦА КОНТЕКСТНЫХ ПОДСКАЗОК - что показывать Claude в зависимости от контекста
CREATE TABLE IF NOT EXISTS "BTI_Context_Prompts" (
    "iPromptId" SERIAL PRIMARY KEY,
    "sContext" VARCHAR(100) NOT NULL, -- 'mess-log', 'debug-errors', 'api-calls', 'db-operations'
    "sCondition" TEXT, -- SQL условие когда показывать
    "sPromptText" TEXT NOT NULL, -- что показать Claude
    "bForceShow" BOOLEAN DEFAULT false, -- принудительно показать
    "iPriority" INTEGER DEFAULT 1,
    "tmCreated" TIMESTAMP DEFAULT NOW()
);

-- 3. ТАБЛИЦА ПАТТЕРНОВ ОШИБОК - отслеживание повторений с автоинкрементом
CREATE TABLE IF NOT EXISTS "BTI_Error_Patterns" (
    "iPatternId" SERIAL PRIMARY KEY,
    "sErrorType" VARCHAR(50) NOT NULL,
    "sDescription" TEXT NOT NULL,
    "sPreventionQuery" TEXT, -- запрос для предотвращения
    "iOccurrenceCount" INTEGER DEFAULT 1, -- счётчик повторений
    "tmLastOccurrence" TIMESTAMP DEFAULT NOW(),
    "tmFirstOccurrence" TIMESTAMP DEFAULT NOW(),
    "sLastContext" TEXT, -- контекст последнего появления
    "bCritical" BOOLEAN DEFAULT false -- критичная ошибка требует блокировки
);

-- 4. ТАБЛИЦА ПРИНУДИТЕЛЬНЫХ ДЕЙСТВИЙ CLAUDE - лог выполнения обязательных проверок
CREATE TABLE IF NOT EXISTS "BTI_Claude_Actions" (
    "iActionId" SERIAL PRIMARY KEY,
    "tmAction" TIMESTAMP DEFAULT NOW(),
    "sActionType" VARCHAR(50) NOT NULL,
    "sUserInput" TEXT, -- что запросил пользователь
    "sTriggeredRules" TEXT[], -- какие правила сработали
    "sExecutedChecks" TEXT[], -- какие проверки выполнены
    "sResult" VARCHAR(20), -- 'ALLOWED', 'BLOCKED', 'WARNED'
    "sSessionId" VARCHAR(50) -- связь с сессией CC
);

-- ИНДЕКСЫ для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_workflow_rules_action ON "BTI_Workflow_Rules"("sActionType");
CREATE INDEX IF NOT EXISTS idx_error_patterns_type ON "BTI_Error_Patterns"("sErrorType");
CREATE INDEX IF NOT EXISTS idx_claude_actions_time ON "BTI_Claude_Actions"("tmAction" DESC);

-- НАЧАЛЬНЫЕ WORKFLOW ПРАВИЛА
INSERT INTO "BTI_Workflow_Rules"
("sActionType", "sKeywordTriggers", "sMandatoryCheck", "sFailureAction", "sErrorMessage", "iPriority")
VALUES

-- ПРАВИЛО 1: Изменение кода - КРИТИЧНАЯ ПРОВЕРКА
('EDIT_CODE',
 ARRAY['изменить','исправить','Edit','Write','MultiEdit','edit','write'],
 'SELECT COUNT(*) FROM "BTI_Error_Patterns" WHERE "sErrorType"=''unauthorized_changes'' AND "bCritical"=true',
 'BLOCK',
 'ОБЯЗАТЕЛЬНО: Прочтите код файла, спросите разрешение пользователя ПЕРЕД изменением!',
 1),

-- ПРАВИЛО 2: Операции с БД - предотвращение CASCADE катастроф
('DATABASE_DELETE',
 ARRAY['DROP','DELETE','CASCADE','удали','удалить','drop','delete'],
 'SELECT "sDescription" FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%cascade%'' OR "sKeywords" ILIKE ''%delete%''',
 'BLOCK',
 'СТОП! Проверьте БЗ на случаи потери данных при DELETE/DROP операциях!',
 1),

-- ПРАВИЛО 3: Curl/API запросы - проблемы экранирования
('CURL_REQUEST',
 ARRAY['curl','POST','API','запрос','api'],
 'SELECT COUNT(*) FROM "BTI_Error_Patterns" WHERE "sErrorType"=''curl_escaping'' OR "sErrorType"=''json_escaping''',
 'WARN',
 'ВНИМАНИЕ: Проверьте экранирование JSON в curl запросах! Используйте SQL файлы для длинных запросов.',
 2),

-- ПРАВИЛО 4: Повторение действий - зацикливание
('REPEAT_ACTION',
 ARRAY['снова','опять','ещё раз','повторить','again'],
 'SELECT "iOccurrenceCount" FROM "BTI_Error_Patterns" ORDER BY "iOccurrenceCount" DESC LIMIT 1',
 'WARN',
 'ПРОВЕРКА: Убедитесь что не повторяете ошибку из debug лога!',
 2);

-- НАЧАЛЬНЫЕ КОНТЕКСТНЫЕ ПОДСКАЗКИ
INSERT INTO "BTI_Context_Prompts"
("sContext", "sCondition", "sPromptText", "bForceShow", "iPriority")
VALUES

-- При работе с mess-log
('mess-log',
 'user_input ILIKE ''%mess%'' OR user_input ILIKE ''%log%'' OR user_input ILIKE ''%CC_%''',
 'КОНТЕКСТ: mess-log система восстановлена. Используйте функцию log_message() вместо сложного кода.',
 false, 1),

-- При ошибках debug
('debug-errors',
 'user_input ILIKE ''%ошибк%'' OR user_input ILIKE ''%error%'' OR user_input ILIKE ''%проблем%''',
 'КОНТЕКСТ: Проверьте БЗ на похожие ошибки в секции DEBUG перед диагностикой.',
 true, 1),

-- При работе с БД
('database-ops',
 'user_input ILIKE ''%БД%'' OR user_input ILIKE ''%PostgreSQL%'' OR user_input ILIKE ''%SQL%''',
 'КОНТЕКСТ: ВСЯ документация в БЗ PostgreSQL. Не создавайте локальные файлы.',
 false, 2);

-- НАЧАЛЬНЫЕ ПАТТЕРНЫ ОШИБОК (из анализа истории)
INSERT INTO "BTI_Error_Patterns"
("sErrorType", "sDescription", "sPreventionQuery", "iOccurrenceCount", "bCritical")
VALUES

('curl_escaping',
 'Проблемы экранирования JSON в curl запросах - повторяющаяся ошибка несколько дней',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%curl%'' OR "sKeywords" ILIKE ''%json%''',
 5, true),

('unauthorized_changes',
 'Изменение кода без чтения файла и разрешения пользователя',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sSection"=''RULES'' AND "sKeywords" ILIKE ''%разрешение%''',
 3, true),

('cascade_deletion',
 'Случайное удаление таблиц с CASCADE - потеря данных',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%cascade%''',
 1, true),

('ignore_documentation',
 'Игнорирование собственной документации и debug логов',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sSection"=''DEBUG'' ORDER BY "sPriority" DESC',
 7, true),

('architectural_violations',
 'Нарушение архитектурных решений (файлы вместо БД)',
 'SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE ''%единый источник%'' OR "sKeywords" ILIKE ''%архитектура%''',
 4, true);

-- ФУНКЦИЯ ДЛЯ ПРОВЕРКИ WORKFLOW ПРАВИЛ
CREATE OR REPLACE FUNCTION check_workflow_rules(p_user_input TEXT, p_session_id VARCHAR DEFAULT NULL)
RETURNS TABLE (
    rule_triggered BOOLEAN,
    action_type VARCHAR,
    error_message TEXT,
    failure_action VARCHAR,
    prevention_data TEXT
) AS $$
DECLARE
    rule_rec RECORD;
    check_result TEXT;
BEGIN
    -- Проверяем все активные правила
    FOR rule_rec IN
        SELECT * FROM "BTI_Workflow_Rules"
        WHERE "bActive" = true
        AND p_user_input ILIKE ANY("sKeywordTriggers")
        ORDER BY "iPriority", "iRuleId"
    LOOP
        -- Выполняем обязательную проверку
        EXECUTE rule_rec."sMandatoryCheck" INTO check_result;

        -- Возвращаем результат
        rule_triggered := true;
        action_type := rule_rec."sActionType";
        error_message := rule_rec."sErrorMessage";
        failure_action := rule_rec."sFailureAction";
        prevention_data := check_result;

        -- Логируем проверку
        INSERT INTO "BTI_Claude_Actions"
        ("sActionType", "sUserInput", "sTriggeredRules", "sResult", "sSessionId")
        VALUES
        (rule_rec."sActionType", p_user_input, ARRAY[rule_rec."sActionType"],
         rule_rec."sFailureAction", p_session_id);

        RETURN NEXT;
    END LOOP;

    -- Если правила не сработали
    IF NOT FOUND THEN
        rule_triggered := false;
        RETURN NEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ФУНКЦИЯ ДЛЯ ОБНОВЛЕНИЯ СЧЁТЧИКА ОШИБОК
CREATE OR REPLACE FUNCTION increment_error_pattern(p_error_type VARCHAR, p_context TEXT DEFAULT NULL)
RETURNS INTEGER AS $$
DECLARE
    current_count INTEGER;
BEGIN
    -- Обновляем счётчик или создаём новую запись
    INSERT INTO "BTI_Error_Patterns" ("sErrorType", "sLastContext", "iOccurrenceCount", "tmLastOccurrence")
    VALUES (p_error_type, p_context, 1, NOW())
    ON CONFLICT ("sErrorType") DO UPDATE SET
        "iOccurrenceCount" = "BTI_Error_Patterns"."iOccurrenceCount" + 1,
        "tmLastOccurrence" = NOW(),
        "sLastContext" = p_context;

    -- Возвращаем новый счётчик
    SELECT "iOccurrenceCount" INTO current_count
    FROM "BTI_Error_Patterns"
    WHERE "sErrorType" = p_error_type;

    RETURN current_count;
END;
$$ LANGUAGE plpgsql;

-- ТЕСТОВЫЙ ЗАПРОС WORKFLOW ПРАВИЛ
-- SELECT * FROM check_workflow_rules('Нужно изменить код в файле test.cs');
-- SELECT * FROM check_workflow_rules('Хочу удалить таблицу');
-- SELECT * FROM check_workflow_rules('Выполнить curl запрос к API');