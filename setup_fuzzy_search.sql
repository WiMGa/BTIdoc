-- =====================================================
-- НЕЧЁТКИЙ ПОЛНОТЕКСТОВЫЙ ПОИСК С pg_trgm
-- =====================================================
-- Установка расширения триграмм для fuzzy search
-- Создание GIN индексов на текстовые поля
-- Функция поиска с ранжированием по релевантности

-- =====================================================
-- 1. УСТАНОВКА РАСШИРЕНИЯ
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- 2. GIN ИНДЕКСЫ ДЛЯ ТРИГРАММ
-- =====================================================

-- log.t_memo - память/знания
CREATE INDEX IF NOT EXISTS idx_memo_what_trgm
ON log.t_memo USING GIN (s_what gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_memo_description_trgm
ON log.t_memo USING GIN (s_description gin_trgm_ops);

-- log.t_dialog - диалоги
CREATE INDEX IF NOT EXISTS idx_dialog_content_trgm
ON log.t_dialog USING GIN (s_content gin_trgm_ops);

-- log.t_log - события
CREATE INDEX IF NOT EXISTS idx_log_title_trgm
ON log.t_log USING GIN (s_title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_log_details_trgm
ON log.t_log USING GIN (s_details gin_trgm_ops);

-- =====================================================
-- 3. ФУНКЦИЯ НЕЧЁТКОГО ПОИСКА
-- =====================================================

CREATE OR REPLACE FUNCTION log.search_knowledge_fuzzy(
    p_query TEXT,
    p_threshold FLOAT DEFAULT 0.3,  -- порог схожести (0..1)
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    source TEXT,           -- источник: 'memo', 'dialog', 'log'
    i_id INTEGER,          -- ID записи
    tm_created TIMESTAMP,  -- когда создано
    s_who TEXT,            -- кто создал
    s_matched_field TEXT,  -- какое поле совпало
    s_matched_text TEXT,   -- текст совпадения
    d_similarity FLOAT,    -- коэффициент схожести (0..1)
    s_context TEXT         -- контекст (полный текст)
) AS $$
BEGIN
    RETURN QUERY
    WITH combined_results AS (
        -- Поиск в log.t_memo
        SELECT
            'memo'::TEXT as source,
            m.i_id,
            m.tm_created,
            m.s_who,
            CASE
                WHEN similarity(m.s_what, p_query) > similarity(m.s_description, p_query)
                THEN 's_what'::TEXT
                ELSE 's_description'::TEXT
            END as s_matched_field,
            CASE
                WHEN similarity(m.s_what, p_query) > similarity(m.s_description, p_query)
                THEN m.s_what
                ELSE m.s_description
            END as s_matched_text,
            GREATEST(
                similarity(m.s_what, p_query),
                similarity(m.s_description, p_query)
            ) as d_similarity,
            (m.s_what || ' | ' || COALESCE(m.s_description, '')) as s_context
        FROM log.t_memo m
        WHERE
            similarity(m.s_what, p_query) > p_threshold
            OR similarity(m.s_description, p_query) > p_threshold

        UNION ALL

        -- Поиск в log.t_dialog
        SELECT
            'dialog'::TEXT,
            d.i_id,
            d.tm_created,
            d.s_who,
            's_content'::TEXT,
            LEFT(d.s_content, 200),  -- первые 200 символов
            similarity(d.s_content, p_query) as d_similarity,
            d.s_content
        FROM log.t_dialog d
        WHERE similarity(d.s_content, p_query) > p_threshold

        UNION ALL

        -- Поиск в log.t_log
        SELECT
            'log'::TEXT,
            l.i_id,
            l.tm_created,
            l.s_who,
            CASE
                WHEN similarity(l.s_title, p_query) > similarity(l.s_details, p_query)
                THEN 's_title'::TEXT
                ELSE 's_details'::TEXT
            END,
            CASE
                WHEN similarity(l.s_title, p_query) > similarity(l.s_details, p_query)
                THEN l.s_title
                ELSE l.s_details
            END,
            GREATEST(
                similarity(l.s_title, p_query),
                similarity(l.s_details, p_query)
            ) as d_similarity,
            (l.s_title || ' | ' || COALESCE(l.s_details, '')) as s_context
        FROM log.t_log l
        WHERE
            similarity(l.s_title, p_query) > p_threshold
            OR similarity(l.s_details, p_query) > p_threshold
    )
    SELECT
        cr.source,
        cr.i_id,
        cr.tm_created,
        cr.s_who,
        cr.s_matched_field,
        cr.s_matched_text,
        cr.d_similarity,
        cr.s_context
    FROM combined_results cr
    ORDER BY cr.d_similarity DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
-- =====================================================

-- Пример 1: Поиск с опечаткой "indFndPattern" вместо "indFindPattern"
-- SELECT * FROM log.search_knowledge_fuzzy('indFndPattern', 0.3, 10);

-- Пример 2: Поиск "databse" вместо "database" с низким порогом
-- SELECT * FROM log.search_knowledge_fuzzy('databse', 0.25, 10);

-- Пример 3: Поиск упоминаний "izzML" (с любыми регистрами)
-- SELECT * FROM log.search_knowledge_fuzzy('izzml', 0.4, 20);

-- Пример 4: Поиск "arhitecture" вместо "architecture"
-- SELECT * FROM log.search_knowledge_fuzzy('arhitecture', 0.3, 10);

-- =====================================================
-- NOTES
-- =====================================================
--
-- Threshold (порог схожести):
--   0.1 - очень мягкий (много ложных срабатываний)
--   0.3 - сбалансированный (рекомендуется)
--   0.5 - строгий (только близкие совпадения)
--   0.7 - очень строгий (почти точное совпадение)
--
-- Similarity (коэффициент схожести):
--   1.0 - идентичные строки
--   0.8+ - очень похожие (1-2 опечатки)
--   0.5-0.8 - умеренно похожие
--   0.3-0.5 - слабо похожие
--   <0.3 - мало общего
--
-- GIN индексы работают БЫСТРО на больших таблицах
-- (в отличие от ILIKE '%keyword%' который сканирует всю таблицу)
--
-- =====================================================
