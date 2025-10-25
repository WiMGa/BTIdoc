-- =====================================================
-- Создание таблицы log.t_log для логирования событий
-- Дата: 2025-10-25 (обновлено)
-- Автор: CCL
-- Описание: Минималистичный подход к логированию событий
--           Отделение событий (t_log) от знаний (t_memo)
-- =====================================================

-- =====================================================
-- СОГЛАСОВАННОСТЬ ТАБЛИЦ СХЕМЫ log:
-- =====================================================
/*
1. t_memo (ЗНАНИЯ - что помнить):
   - i_id, tm_created, s_who, s_what, as_anchors[], s_description

2. t_tasks (ЗАДАНИЯ):
   - i_id, tm_created, s_from, s_to, s_title, s_description, s_status,
     tm_completed, s_result, s_response

3. t_log (СОБЫТИЯ - что произошло):
   - i_id, tm_created, s_who, s_event_type, s_title, as_anchors[], s_details

ЕДИНООБРАЗИЕ:
- Все таблицы: i_id, tm_created
- Якоря: as_anchors[] (t_memo, t_log)
- Описание: s_description (t_memo, t_tasks), s_details (t_log)
- Название: s_what (t_memo), s_title (t_tasks, t_log), s_event_type (t_log)
*/

-- =====================================================
-- 1. Создать таблицу log.t_log
-- =====================================================

CREATE TABLE IF NOT EXISTS log.t_log (
    i_id SERIAL PRIMARY KEY,
    tm_created TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    s_who TEXT NOT NULL,           -- CCL, DC, CCS, User
    s_event_type TEXT NOT NULL,    -- session_start, session_end, task_complete, commit, error, decision
    s_title TEXT NOT NULL,         -- Краткое название события
    as_anchors TEXT[],             -- Якоря для поиска (единообразие с t_memo!)
    s_details TEXT                 -- Подробности события (опционально)
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_log_created ON log.t_log(tm_created DESC);
CREATE INDEX IF NOT EXISTS idx_log_who ON log.t_log(s_who);
CREATE INDEX IF NOT EXISTS idx_log_type ON log.t_log(s_event_type);
CREATE INDEX IF NOT EXISTS idx_log_anchors ON log.t_log USING GIN(as_anchors);

-- Комментарии
COMMENT ON TABLE log.t_log IS
'Лог событий. Для восстановления контекста: что было, когда, кем. Отдельно от знаний (t_memo).';

COMMENT ON COLUMN log.t_log.s_who IS
'Автор события: CCL (Claude Code Local), DC (Desktop Claude), CCS (Claude Code Server), User';

COMMENT ON COLUMN log.t_log.s_event_type IS
'Тип события: session_start, session_end, task_complete, commit, error, decision, refactor, test';

COMMENT ON COLUMN log.t_log.s_title IS
'Краткое название события (1-2 строки)';

COMMENT ON COLUMN log.t_log.as_anchors IS
'Якоря для поиска, единообразие с t_memo: [''session''], [''task'', ''completed''], [''git'', ''commit'']';

COMMENT ON COLUMN log.t_log.s_details IS
'Подробное описание события, результаты, ошибки (опционально)';

-- =====================================================
-- 2. Процедура: добавить событие в лог
-- =====================================================

CREATE OR REPLACE FUNCTION log.add_event(
    p_who TEXT,
    p_event_type TEXT,
    p_title TEXT,
    p_anchors TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_details TEXT DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO log.t_log (s_who, s_event_type, s_title, as_anchors, s_details)
    VALUES (p_who, p_event_type, p_title, p_anchors, p_details)
    RETURNING i_id INTO v_id;

    RETURN v_id;
END;
$function$;

COMMENT ON FUNCTION log.add_event(TEXT, TEXT, TEXT, TEXT[], TEXT) IS
'Добавить событие в лог. Возвращает ID события.';

-- =====================================================
-- 3. Процедура: получить последние N событий (ОТ ВСЕХ!)
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_recent_events(p_limit INTEGER DEFAULT 15)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_anchors TEXT[],
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
        e.as_anchors,
        e.s_details
    FROM log.t_log e
    ORDER BY e.tm_created DESC
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION log.get_recent_events(INTEGER) IS
'Получить последние N событий от ВСЕХ авторов для восстановления контекста. По умолчанию 15 (оптимально для DC с лимитами).';

-- =====================================================
-- 4. Процедура: поиск событий по якорям
-- =====================================================

CREATE OR REPLACE FUNCTION log.search_events(
    p_anchors TEXT[],
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_who TEXT,
    s_event_type TEXT,
    s_title TEXT,
    as_anchors TEXT[],
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
        e.as_anchors,
        e.s_details
    FROM log.t_log e
    WHERE e.as_anchors && p_anchors  -- Пересечение массивов
    ORDER BY e.tm_created DESC
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION log.search_events(TEXT[], INTEGER) IS
'Поиск событий по якорям. Возвращает события содержащие хотя бы один из указанных якорей.';

-- =====================================================
-- 5. Процедура: получить события за период
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
    as_anchors TEXT[],
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
        e.as_anchors,
        e.s_details
    FROM log.t_log e
    WHERE e.tm_created::date BETWEEN p_date_from AND p_date_to
    ORDER BY e.tm_created DESC;
END;
$function$;

COMMENT ON FUNCTION log.get_events_by_date(DATE, DATE) IS
'Получить события за период. По умолчанию - за сегодня.';

-- =====================================================
-- ТИПЫ СОБЫТИЙ (s_event_type):
-- =====================================================
/*
session_start    - Начало сессии работы
session_end      - Конец сессии
task_create      - Создание задания
task_complete    - Завершение задания
commit           - Git commit
error            - Ошибка
decision         - Архитектурное/важное решение
refactor         - Рефакторинг кода
test             - Тестирование
*/

-- =====================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:
-- =====================================================

/*
-- ===== ВОССТАНОВЛЕНИЕ КОНТЕКСТА =====

-- Получить последние события от ВСЕХ (по умолчанию 15):
SELECT * FROM log.get_recent_events();

-- Или явно указать количество:
SELECT * FROM log.get_recent_events(20);  -- CCL может запросить больше

-- Результат: хронология работы CCL+DC+User за последнее время
-- Экономия ~90% токенов по сравнению с чтением всего session_log.txt
-- Default 15 оптимален для DC (избегаем превышения лимитов)


-- ===== НАЧАЛО/КОНЕЦ СЕССИИ =====

-- Начало сессии CCL:
SELECT log.add_event(
    'CCL',
    'session_start',
    'Started session after restart',
    ARRAY['session', 'start']
);

-- Конец сессии:
SELECT log.add_event(
    'CCL',
    'session_end',
    'Session ended: completed Task #3 and #5',
    ARRAY['session', 'end'],
    'Total: 2 tasks completed, 5 commits, 3 memo entries added'
);


-- ===== ЗАДАНИЯ =====

-- Создание задания:
SELECT log.add_event(
    'CCL',
    'task_create',
    'Created Task #6 for DC: execute create_log_table.sql',
    ARRAY['task', 'create', 'sql', 'database']
);

-- Завершение задания:
SELECT log.add_event(
    'CCL',
    'task_complete',
    'Completed Task #3: BTIwork refactoring',
    ARRAY['task', 'completed', 'BTIwork', 'refactoring'],
    'Refactored to one-task-per-vector architecture. 3 projects compiled. Commits: fbf1b37, 2415f4b, de6feff'
);


-- ===== GIT ОПЕРАЦИИ =====

-- Commit:
SELECT log.add_event(
    'CCL',
    'commit',
    'Commit 8164468: add session log procedures to whitelist',
    ARRAY['git', 'commit', 'BTI_API', 'whitelist'],
    'Added 6 procedures: add_event, get_recent_events, search_events, get_events_by_date, get_current_session_events, get_event_stats'
);


-- ===== ОШИБКИ =====

-- Ошибка:
SELECT log.add_event(
    'CCL',
    'error',
    'SQL script execution blocked by whitelist',
    ARRAY['error', 'sql', 'whitelist', 'permissions'],
    'ALTER TABLE log.t_tasks blocked. Created Task #5 for DC to execute script via psql.'
);


-- ===== РЕШЕНИЯ =====

-- Архитектурное решение:
SELECT log.add_event(
    'User',
    'decision',
    'Decision: create separate t_log table for events',
    ARRAY['decision', 'architecture', 'database', 't_log'],
    'Separated knowledge (t_memo) from events (t_log). Different semantics: facts vs history. Different queries.'
);


-- ===== ПОИСК =====

-- Где обсуждалось s_response?
SELECT * FROM log.search_events(ARRAY['s_response', 'database']);

-- Все завершённые задания:
SELECT * FROM log.search_events(ARRAY['task', 'completed']);

-- Все коммиты в BTI_API:
SELECT * FROM log.search_events(ARRAY['commit', 'BTI_API']);


-- ===== СОБЫТИЯ ЗА ПЕРИОД =====

-- Что было сегодня:
SELECT * FROM log.get_events_by_date(CURRENT_DATE, CURRENT_DATE);

-- События за последнюю неделю:
SELECT * FROM log.get_events_by_date(CURRENT_DATE - 7, CURRENT_DATE);


-- ===== СРАВНЕНИЕ С t_memo =====

-- t_memo - ЗНАНИЯ (что помнить):
SELECT * FROM log.find_memo('BTIwork');  -- Найти факты о BTIwork

-- t_log - СОБЫТИЯ (что было):
SELECT * FROM log.search_events(ARRAY['BTIwork']);  -- Найти события о BTIwork
*/
