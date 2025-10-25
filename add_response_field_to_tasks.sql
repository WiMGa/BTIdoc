-- =====================================================
-- Добавление поля s_response в таблицу log.t_tasks
-- Дата: 2025-10-25
-- Автор: CCL
-- Описание: Разделение краткого результата (s_result)
--           и подробного ответа (s_response)
-- =====================================================

-- 1. Добавить поле s_response в таблицу log.t_tasks
ALTER TABLE log.t_tasks ADD COLUMN IF NOT EXISTS s_response TEXT;

COMMENT ON COLUMN log.t_tasks.s_response IS 'Подробный ответ на задание (детальный отчёт о выполнении)';
COMMENT ON COLUMN log.t_tasks.s_result IS 'Краткий результат выполнения (1-2 строки для быстрого просмотра)';

-- =====================================================
-- 2. Обновить процедуру log.complete_task()
-- =====================================================

CREATE OR REPLACE FUNCTION log.complete_task(
    p_task_id INTEGER,
    p_result TEXT,
    p_response TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE log.t_tasks
    SET
        s_status = 'done',
        tm_completed = NOW(),
        s_result = p_result,
        s_response = COALESCE(p_response, p_result)  -- если response не передан, использовать result
    WHERE i_id = p_task_id;

    RETURN FOUND;
END;
$function$;

COMMENT ON FUNCTION log.complete_task(INTEGER, TEXT, TEXT) IS
'Завершить задание. p_result - краткий итог, p_response - подробный ответ (опционально)';

-- =====================================================
-- 3. Обновить процедуру log.get_tasks()
-- Добавить возврат полей s_result и s_response для завершённых заданий
-- =====================================================

-- Версия для получения новых заданий (как раньше)
-- Оставляем без изменений
CREATE OR REPLACE FUNCTION log.get_tasks(p_for TEXT)
RETURNS TABLE(
    i_id INTEGER,
    s_from TEXT,
    s_title TEXT,
    s_description TEXT,
    s_status TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.i_id, t.s_from, t.s_title, t.s_description, t.s_status
    FROM log.t_tasks t
    WHERE t.s_to = p_for AND t.s_status = 'new'
    ORDER BY t.tm_created;
END;
$function$;

-- Новая версия для получения всех заданий (включая завершённые)
CREATE OR REPLACE FUNCTION log.get_all_tasks(p_for TEXT)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_from TEXT,
    s_to TEXT,
    s_title TEXT,
    s_description TEXT,
    s_status TEXT,
    tm_completed TIMESTAMP,
    s_result TEXT,
    s_response TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t.i_id,
        t.tm_created,
        t.s_from,
        t.s_to,
        t.s_title,
        t.s_description,
        t.s_status,
        t.tm_completed,
        t.s_result,
        t.s_response
    FROM log.t_tasks t
    WHERE t.s_to = p_for
    ORDER BY t.tm_created DESC;
END;
$function$;

COMMENT ON FUNCTION log.get_all_tasks(TEXT) IS
'Получить все задания (включая завершённые) с полной информацией';

-- =====================================================
-- 4. Создать функцию получения истории задания
-- =====================================================

CREATE OR REPLACE FUNCTION log.get_task_details(p_task_id INTEGER)
RETURNS TABLE(
    i_id INTEGER,
    tm_created TIMESTAMP,
    s_from TEXT,
    s_to TEXT,
    s_title TEXT,
    s_description TEXT,
    s_status TEXT,
    tm_completed TIMESTAMP,
    s_result TEXT,
    s_response TEXT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t.i_id,
        t.tm_created,
        t.s_from,
        t.s_to,
        t.s_title,
        t.s_description,
        t.s_status,
        t.tm_completed,
        t.s_result,
        t.s_response
    FROM log.t_tasks t
    WHERE t.i_id = p_task_id;
END;
$function$;

COMMENT ON FUNCTION log.get_task_details(INTEGER) IS
'Получить полную информацию о задании по ID';

-- =====================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:
-- =====================================================

/*
-- Завершить задание с кратким результатом и подробным ответом:
SELECT log.complete_task(
    3,
    'Vypolneno uspeshno za 50 min',
    'Detalnoe opisanie: uproshhena arhitektura CTask, dobavleny konstanty...'
);

-- Завершить задание только с кратким результатом:
SELECT log.complete_task(3, 'Vypolneno uspeshno');

-- Получить новые задания:
SELECT * FROM log.get_tasks('CCL');

-- Получить все задания с результатами:
SELECT * FROM log.get_all_tasks('CCL');

-- Получить детали конкретного задания:
SELECT * FROM log.get_task_details(3);
*/
