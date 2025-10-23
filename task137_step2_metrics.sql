-- ШАГ 2: РАСЧЕТ МЕТРИК ДЛЯ ОБЕИХ СТРАТЕГИЙ
-- Разбивка на Train (iExit <= 179607) и Test (iExit > 179607)

-- Метрики для trades_30_60_new
WITH equity_30_60 AS (
  SELECT
    iExit,
    result,
    pnl_pips,
    SUM(pnl_pips) OVER (ORDER BY iExit) AS cumulative_pnl,
    MAX(SUM(pnl_pips) OVER (ORDER BY iExit)) OVER (ORDER BY iExit) AS running_max
  FROM izzml.trades_30_60_new
),
drawdown_30_60 AS (
  SELECT
    MAX(running_max - cumulative_pnl) AS max_dd
  FROM equity_30_60
),
metrics_30_60 AS (
  SELECT
    'TP30/SL60' AS variant,
    part,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pTP,
    ROUND(SUM(pnl_pips), 2) AS Profit,
    (SELECT max_dd FROM drawdown_30_60) AS MaxDD,
    ROUND(SUM(pnl_pips) / (SELECT NULLIF(max_dd, 0) FROM drawdown_30_60), 4) AS ProfitDDRatio
  FROM (
    SELECT
      CASE WHEN iExit <= 179607 THEN 'Train' ELSE 'Test' END AS part,
      result,
      pnl_pips
    FROM izzml.trades_30_60_new
  ) t
  GROUP BY part
),
-- Метрики для trades_40_60_new
equity_40_60 AS (
  SELECT
    iExit,
    result,
    pnl_pips,
    SUM(pnl_pips) OVER (ORDER BY iExit) AS cumulative_pnl,
    MAX(SUM(pnl_pips) OVER (ORDER BY iExit)) OVER (ORDER BY iExit) AS running_max
  FROM izzml.trades_40_60_new
),
drawdown_40_60 AS (
  SELECT
    MAX(running_max - cumulative_pnl) AS max_dd
  FROM equity_40_60
),
metrics_40_60 AS (
  SELECT
    'TP40/SL60' AS variant,
    part,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(CASE WHEN result = 'TP' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pTP,
    ROUND(SUM(pnl_pips), 2) AS Profit,
    (SELECT max_dd FROM drawdown_40_60) AS MaxDD,
    ROUND(SUM(pnl_pips) / (SELECT NULLIF(max_dd, 0) FROM drawdown_40_60), 4) AS ProfitDDRatio
  FROM (
    SELECT
      CASE WHEN iExit <= 179607 THEN 'Train' ELSE 'Test' END AS part,
      result,
      pnl_pips
    FROM izzml.trades_40_60_new
  ) t
  GROUP BY part
)
SELECT * FROM metrics_30_60
UNION ALL
SELECT * FROM metrics_40_60
ORDER BY variant, part;
