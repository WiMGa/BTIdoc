-- ШАГ 1: СОЗДАНИЕ ТАБЛИЦЫ СДЕЛОК trades_30_60_new
-- Бэктест izzML Close-only для TP=30пп, SL=60пп

DROP MATERIALIZED VIEW IF EXISTS izzml.trades_30_60_new CASCADE;
CREATE MATERIALIZED VIEW izzml.trades_30_60_new AS
WITH bars_after_signal AS (
  SELECT
    lv.id_enter,
    lv.iEnter,
    lv.dir0,
    lv.pEnter,
    lv.tm1 AS tmEnter,
    lv.tp,
    lv.sl,
    b.bar AS iExit,
    b.timestamp AS tmExit,
    b.close AS pExit
  FROM izzml.levels_30_60 lv
  JOIN izzml.bars b
    ON b.symbol = 'EURUSD'
   AND b.timeframe = 'Range1'
   AND b.bar > lv.iEnter
),
first_trigger AS (
  SELECT
    id_enter,
    iEnter,
    dir0,
    pEnter,
    tmEnter,
    tp,
    sl,
    iExit,
    tmExit,
    pExit,
    CASE
      -- Для BUY (dir0=1): TP сработал если close >= tp, SL если close <= sl
      WHEN dir0 = 1 AND pExit >= tp THEN 'TP'
      WHEN dir0 = 1 AND pExit <= sl THEN 'SL'
      -- Для SELL (dir0=-1): TP сработал если close <= tp, SL если close >= sl
      WHEN dir0 = -1 AND pExit <= tp THEN 'TP'
      WHEN dir0 = -1 AND pExit >= sl THEN 'SL'
      ELSE NULL
    END AS result,
    ROW_NUMBER() OVER (PARTITION BY id_enter ORDER BY iExit) AS rn
  FROM bars_after_signal
)
SELECT
  id_enter,
  iEnter,
  dir0,
  pEnter,
  tmEnter,
  tp,
  sl,
  iExit,
  tmExit,
  pExit,
  result,
  CASE
    WHEN result = 'TP' THEN 28.5  -- +30пп - 1.5пп комиссия
    WHEN result = 'SL' THEN -61.5 -- -60пп - 1.5пп комиссия
    ELSE 0
  END AS pnl_pips
FROM first_trigger
WHERE result IS NOT NULL AND rn = 1;

-- Проверка: количество сделок и базовая статистика
SELECT
  COUNT(*) AS n_trades,
  SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) AS n_tp,
  SUM(CASE WHEN result = 'SL' THEN 1 ELSE 0 END) AS n_sl,
  ROUND(100.0 * SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_tp,
  ROUND(SUM(pnl_pips), 2) AS total_pnl
FROM izzml.trades_30_60_new;
