-- Подсчет паттернов где p2 < p0 (только первое условие из 14)

WITH numbered AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY bar_extremum) AS iNo,
    price AS dPrice
  FROM izzml.zz_extremums
  WHERE bar_confirmed IS NOT NULL
    AND symbol = 'EURUSD'
    AND timeframe = 'Range1'
    AND zz_delta = 1.5
)
SELECT COUNT(*) AS n_patterns
FROM numbered p0
JOIN numbered p2 ON p2.iNo = p0.iNo - 2
WHERE p0.iNo >= 3
  AND p2.dPrice < p0.dPrice;
