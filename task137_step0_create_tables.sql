-- ШАГ 0: СОЗДАНИЕ БАЗОВЫХ ТАБЛИЦ ДЛЯ ЗАДАНИЯ #137
-- Бэктест izzML Close-only для 30/60 и 40/60

-- 0.1) segments - пары соседних экстремумов ZigZag
DROP MATERIALIZED VIEW IF EXISTS izzml.segments CASCADE;
CREATE MATERIALIZED VIEW izzml.segments AS
WITH pair AS (
  SELECT z0.id AS id_prev, z1.id AS id_enter,
         z0.bar_extremum AS bar0, z1.bar_extremum AS bar1,
         z0.time_extremum AS tm0, z1.time_extremum AS tm1,
         z0.price AS p0, z1.price AS p1
  FROM izzml.zz_extremums z0
  JOIN LATERAL (
    SELECT * FROM izzml.zz_extremums
    WHERE symbol=z0.symbol AND timeframe=z0.timeframe AND zz_delta=z0.zz_delta
      AND bar_extremum > z0.bar_extremum
    ORDER BY bar_extremum LIMIT 1
  ) z1 ON TRUE
  WHERE z0.symbol='EURUSD' AND z0.timeframe='Range1' AND z0.zz_delta=1.5
)
SELECT *,
  (bar1 - bar0) AS dbars,
  ROUND(ABS(p1 - p0) * 10000)::int AS seg_size_pips,
  SIGN(p1 - p0)::int AS price_direction,
  DEGREES(ATAN((ROUND(ABS(p1 - p0) * 10000)::float) / NULLIF(bar1 - bar0, 0))) AS alpha_deg
FROM pair;

-- 0.2) sectors - классификация по углу (пороги: q30=26.5651°, q60=33.6901°)
DROP MATERIALIZED VIEW IF EXISTS izzml.sectors CASCADE;
CREATE MATERIALIZED VIEW izzml.sectors AS
SELECT s.*,
       CASE
         WHEN ABS(s.alpha_deg) < 26.5651 THEN 0
         WHEN ABS(s.alpha_deg) < 33.6901 THEN s.price_direction
         ELSE 2 * s.price_direction
       END AS s
FROM izzml.segments s;

-- 0.3) signals_flat - фильтр flat: |alpha| < 26.5651°
DROP MATERIALIZED VIEW IF EXISTS izzml.signals_flat CASCADE;
CREATE MATERIALIZED VIEW izzml.signals_flat AS
SELECT id_enter, bar1 AS iEnter, p1 AS pEnter, price_direction AS dir0, alpha_deg, tm1
FROM izzml.segments
WHERE ABS(alpha_deg) < 26.5651;

-- 0.4) levels_30_60 - уровни TP=30пп, SL=60пп
DROP MATERIALIZED VIEW IF EXISTS izzml.levels_30_60 CASCADE;
CREATE MATERIALIZED VIEW izzml.levels_30_60 AS
SELECT id_enter, iEnter, dir0, pEnter, tm1,
       CASE WHEN dir0 = 1 THEN pEnter + 0.0030 ELSE pEnter - 0.0030 END AS tp,
       CASE WHEN dir0 = 1 THEN pEnter - 0.0060 ELSE pEnter + 0.0060 END AS sl
FROM izzml.signals_flat;

-- 0.5) levels_40_60 - уровни TP=40пп, SL=60пп
DROP MATERIALIZED VIEW IF EXISTS izzml.levels_40_60 CASCADE;
CREATE MATERIALIZED VIEW izzml.levels_40_60 AS
SELECT id_enter, iEnter, dir0, pEnter, tm1,
       CASE WHEN dir0 = 1 THEN pEnter + 0.0040 ELSE pEnter - 0.0040 END AS tp,
       CASE WHEN dir0 = 1 THEN pEnter - 0.0060 ELSE pEnter + 0.0060 END AS sl
FROM izzml.signals_flat;

-- 0.6) Проверка создания таблиц
SELECT
  (SELECT COUNT(*) FROM izzml.segments) as n_segments,
  (SELECT COUNT(*) FROM izzml.sectors) as n_sectors,
  (SELECT COUNT(*) FROM izzml.signals_flat) as n_signals,
  (SELECT COUNT(*) FROM izzml.levels_30_60) as n_levels_30,
  (SELECT COUNT(*) FROM izzml.levels_40_60) as n_levels_40;

-- Ожидаемые результаты:
-- n_segments: ~30228
-- n_sectors: ~30228
-- n_signals: ~11927
-- n_levels_30: ~11927
-- n_levels_40: ~11927
