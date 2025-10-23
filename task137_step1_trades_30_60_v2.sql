-- ШАГ 1: СОЗДАНИЕ ТАБЛИЦЫ СДЕЛОК trades_30_60_new (ОПТИМИЗИРОВАННАЯ ВЕРСИЯ)
-- Бэктест izzML Close-only для TP=30пп, SL=60пп
-- Используем LATERAL JOIN для поиска первого триггера

DROP MATERIALIZED VIEW IF EXISTS izzml.trades_30_60_new CASCADE;
CREATE MATERIALIZED VIEW izzml.trades_30_60_new AS
SELECT
  lv.id_enter,
  lv.iEnter,
  lv.dir0,
  lv.pEnter,
  lv.tm1 AS tmEnter,
  lv.tp,
  lv.sl,
  trig.iExit,
  trig.tmExit,
  trig.pExit,
  trig.result,
  CASE
    WHEN trig.result = 'TP' THEN 28.5  -- +30пп - 1.5пп комиссия
    WHEN trig.result = 'SL' THEN -61.5 -- -60пп - 1.5пп комиссия
    ELSE 0
  END AS pnl_pips
FROM izzml.levels_30_60 lv
CROSS JOIN LATERAL (
  SELECT
    b.bar AS iExit,
    b.timestamp AS tmExit,
    b.close AS pExit,
    CASE
      -- Для BUY (dir0=1): TP если close >= tp, SL если close <= sl
      WHEN lv.dir0 = 1 AND b.close >= lv.tp THEN 'TP'
      WHEN lv.dir0 = 1 AND b.close <= lv.sl THEN 'SL'
      -- Для SELL (dir0=-1): TP если close <= tp, SL если close >= sl
      WHEN lv.dir0 = -1 AND b.close <= lv.tp THEN 'TP'
      WHEN lv.dir0 = -1 AND b.close >= lv.sl THEN 'SL'
      ELSE NULL
    END AS result
  FROM izzml.bars b
  WHERE b.symbol = 'EURUSD'
    AND b.timeframe = 'Range1'
    AND b.bar > lv.iEnter
    AND (
      -- Для BUY: ищем первый бар где close >= tp ИЛИ close <= sl
      (lv.dir0 = 1 AND (b.close >= lv.tp OR b.close <= lv.sl))
      OR
      -- Для SELL: ищем первый бар где close <= tp ИЛИ close >= sl
      (lv.dir0 = -1 AND (b.close <= lv.tp OR b.close >= lv.sl))
    )
  ORDER BY b.bar
  LIMIT 1
) trig
WHERE trig.result IS NOT NULL;

-- Проверка: количество сделок и базовая статистика
SELECT
  COUNT(*) AS n_trades,
  SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) AS n_tp,
  SUM(CASE WHEN result = 'SL' THEN 1 ELSE 0 END) AS n_sl,
  ROUND(100.0 * SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_tp,
  ROUND(SUM(pnl_pips), 2) AS total_pnl
FROM izzml.trades_30_60_new;
