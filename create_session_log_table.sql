-- =====================================================
-- Создание таблицы log.t_session_log для логирования событий
-- Дата: 2025-10-25
-- Автор: CCL
-- Описание: Отделение логирования событий (t_session_log)
--           от хранения знаний (t_memo)
-- =====================================================

-- 1. Создать таблицу log.t_session_log
CREATE TABLE IF NOT EXISTS log.t_session_log (
    i_id SERIAL PRIMARY KEY,
    tm_created TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    s_who TEXT NOT NULL,  -- CCL, DC, CCS, User
    s_event_type TEXT NOT NULL,  -- session_start, session_end, task_complete, commit, error, decision, etc.
    s_title TEXT NOT NULL,  -- Краткое название события
    as_tags TEXT[],  -- Теги для поиска (аналог as_anchors в t_memo)
    s_details TEXT  -- Подробности события (опционально)
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_session_log_created ON log.t_session_log(tm_created DESC);
CREATE INDEX IF NOT EXISTS idx_session_log_who ON log.t_session_log(s_who);
CREATE INDEX IF NOT EXISTS idx_session_log_type ON log.t_session_log(s_event_type);
CREATE INDEX IF NOT EXISTS idx_session_log_tags ON log.t_session_log USING GIN(as_tags);

-- Комментарии
COMMENT ON TABLE log.t_session_log IS
'Лог событий сессий работы CCL/DC/CCS. Для восстановления контекста и истории действий.';

COMMENT ON COLUMN log.t_session_log.s_who IS
'Кто выполнил действие: CCL (Claude Code Local), DC (Desktop Claude), CCS (Claude Code Server), User';

COMMENT ON COLUMN log.t_session_log.s_event_type IS
'Тип события: session_start, session_end, task_create, task_complete, commit, error, decision, refactor, test';

COMMENT ON COLUMN log.t_session_log.s_title IS
'Краткое название события (1-2 строки)';

COMMENT ON COLUMN log.t_session_log.as_tags IS
'Теги для поиска: [''session'', ''task''], [''git'', ''commit''], [''error'', ''sql'']';

COMMENT ON COLUMN log.t_session_log.s_details IS
'Подробное описание события, результаты, ошибки (опционально)';

-- =====================================================
-- 2. Процедура: добавить событие
-- =====================================================

CREATE OR REPLACE FUNCTION log.add_event(
    p_who TEXT,
    p_event_type TEXT,
    p_title TEXT,
    p_tags TEXT[],
    p_details TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO log.t_session_log (s_who, s_event_type, s_title, as_tags, s_details)
    VALUES (p_who, p_event_type, p_title, p_tags, p_details)
    RETURNING i_id INTO v_id;

    RETURN v_id;
END;
$function$;

COMMENT ON FUNCTION log.add_event(TEXT, TEXT, TEXT, TEXT[], TEXT) IS
'Добавить событие в лог сессии. Возвращает ID события.';

-- =====================================================
-- 3. Процедура: получить последние N событий
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_recent_events(p_limit INTEGER DEFAULT 20)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_tags TEXT[],
    s_details TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.i_id,
        e.tm_created,
        e.s_who,
        e.s_event_type,
        e.s_title,
        e.as_tags,
        e.s_details
    FROM log.t_session_log e
    ORDER BY e.tm_created DESC
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION log.get_recent_events(INTEGER) IS
'Получить последние N событий (по умолчанию 20) для восстановления контекста';

-- =====================================================
-- 4. Процедура: получить события за период
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_events_by_date(
    p_date_from DATE DEFAULT CURRENT_DATE,
    p_date_to DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_tags TEXT[],
    s_details TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.i_id,
        e.tm_created,
        e.s_who,
        e.s_event_type,
        e.s_title,
        e.as_tags,
        e.s_details
    FROM log.t_session_log e
    WHERE e.tm_created::date BETWEEN p_date_from AND p_date_to
    ORDER BY e.tm_created DESC;
END;
$function$;

COMMENT ON FUNCTION log.get_events_by_date(DATE, DATE) IS
'Получить события за период. По умолчанию - за сегодня.';

-- =====================================================
-- 5. Процедура: поиск событий по тегам
-- =====================================================

CREATE OR REPLACE FUNCTION log.search_events(
    p_tags TEXT[],
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_tags TEXT[],
    s_details TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.i_id,
        e.tm_created,
        e.s_who,
        e.s_event_type,
        e.s_title,
        e.as_tags,
        e.s_details
    FROM log.t_session_log e
    WHERE e.as_tags && p_tags  -- Пересечение массивов
    ORDER BY e.tm_created DESC
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION log.search_events(TEXT[], INTEGER) IS
'Поиск событий по тегам. Возвращает события содержащие хотя бы один из указанных тегов.';

-- =====================================================
-- 6. Процедура: получить события текущей сессии
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_current_session_events()
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_tags TEXT[],
    s_details TEXT
)
LANGUAGE plpgsql
AS $function$
DECLARE
    v_session_start TIMESTAMP;
BEGIN
    -- Найти время последнего session_start
    SELECT e.tm_created INTO v_session_start
    FROM log.t_session_log e
    WHERE e.s_event_type = 'session_start'
    ORDER BY e.tm_created DESC
    LIMIT 1;

    -- Если нет session_start, вернуть события за последние 2 часа
    IF v_session_start IS NULL THEN
        v_session_start := NOW() - INTERVAL '2 hours';
    END IF;

    RETURN QUERY
    SELECT
        e.i_id,
        e.tm_created,
        e.s_who,
        e.s_event_type,
        e.s_title,
        e.as_tags,
        e.s_details
    FROM log.t_session_log e
    WHERE e.tm_created >= v_session_start
    ORDER BY e.tm_created ASC;  -- ASC для хронологии
END;
$function$;

COMMENT ON FUNCTION log.get_current_session_events() IS
'Получить все события текущей сессии (с последнего session_start)';

-- =====================================================
-- 7. Процедура: получить статистику по типам событий
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_event_stats(
    p_date_from DATE DEFAULT CURRENT_DATE,
    p_date_to DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    s_event_type TEXT,
    i_count BIGINT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e.s_event_type,
        COUNT(*) as i_count
    FROM log.t_session_log e
    WHERE e.tm_created::date BETWEEN p_date_from AND p_date_to
    GROUP BY e.s_event_type
    ORDER BY i_count DESC;
END;
$function$;

COMMENT ON FUNCTION log.get_event_stats(DATE, DATE) IS
'Статистика по типам событий за период';

-- =====================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:
-- =====================================================

/*
-- Начало сессии:
SELECT log.add_event(
    'CCL',
    'session_start',
    'Session started: continue after restart',
    ARRAY['session', 'start']
);

-- Завершение задания:
SELECT log.add_event(
    'CCL',
    'task_complete',
    'Task #3 completed: BTIwork refactoring',
    ARRAY['task', 'completed', 'BTIwork'],
    'Refactored architecture from ~40000 tasks to N tasks (one per vector). All 3 projects compiled and committed.'
);

-- Commit в git:
SELECT log.add_event(
    'CCL',
    'commit',
    'Commit 3bc909b: add log.complete_task to whitelist',
    ARRAY['git', 'commit', 'BTI_API'],
    'Added log.complete_task, log.get_all_tasks, log.get_task_details to whitelist'
);

-- Ошибка:
SELECT log.add_event(
    'CCL',
    'error',
    'SQL script execution blocked by whitelist',
    ARRAY['error', 'sql', 'whitelist'],
    'ALTER TABLE blocked. Created Task #5 for DC to execute script via psql.'
);

-- Архитектурное решение:
SELECT log.add_event(
    'User',
    'decision',
    'Decision: create separate t_session_log table',
    ARRAY['decision', 'architecture', 'database'],
    'Decided to separate knowledge (t_memo) from events (t_session_log). Different semantics and usage patterns.'
);

-- Получить последние 20 событий:
SELECT * FROM log.get_recent_events(20);

-- Получить события сегодня:
SELECT * FROM log.get_events_by_date(CURRENT_DATE, CURRENT_DATE);

-- Получить события текущей сессии:
SELECT * FROM log.get_current_session_events();

-- Поиск по тегам:
SELECT * FROM log.search_events(ARRAY['task', 'completed']);

-- Статистика за сегодня:
SELECT * FROM log.get_event_stats(CURRENT_DATE, CURRENT_DATE);
*/
