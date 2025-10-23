-- ЗАДАНИЕ #139: Поиск паттернов ZigZag по 14 условиям (ОПТИМИЗИРОВАННАЯ ВЕРСИЯ)
-- Используем self-joins вместо LATERAL JOIN для лучшей производительности

-- Шаг 1: Присваиваем порядковые номера экстремумам
WITH numbered AS (
  SELECT
    id,
    bar_extremum,
    bar_confirmed,
    price AS dPrice,
    direction,
    ray_size,
    ROW_NUMBER() OVER (ORDER BY bar_extremum) AS iNo
  FROM izzml.zz_extremums
  WHERE bar_confirmed IS NOT NULL
    AND symbol = 'EURUSD'
    AND timeframe = 'Range1'
    AND zz_delta = 1.5
)
-- Шаг 2: Проверяем 14 условий паттерна через self-joins
SELECT
  COUNT(*) AS n_patterns,
  MIN(p0.iNo) AS first_match_iNo,
  MAX(p0.iNo) AS last_match_iNo
FROM numbered p0
JOIN numbered p1 ON p1.iNo = p0.iNo - 1
JOIN numbered p2 ON p2.iNo = p0.iNo - 2
JOIN numbered p3 ON p3.iNo = p0.iNo - 3
JOIN numbered p4 ON p4.iNo = p0.iNo - 4
JOIN numbered p5 ON p5.iNo = p0.iNo - 5
JOIN numbered p6 ON p6.iNo = p0.iNo - 6
JOIN numbered p7 ON p7.iNo = p0.iNo - 7
JOIN numbered p8 ON p8.iNo = p0.iNo - 8
JOIN numbered p9 ON p9.iNo = p0.iNo - 9
JOIN numbered p10 ON p10.iNo = p0.iNo - 10
JOIN numbered p11 ON p11.iNo = p0.iNo - 11
JOIN numbered p12 ON p12.iNo = p0.iNo - 12
JOIN numbered p13 ON p13.iNo = p0.iNo - 13
JOIN numbered p14 ON p14.iNo = p0.iNo - 14
JOIN numbered p15 ON p15.iNo = p0.iNo - 15
JOIN numbered p16 ON p16.iNo = p0.iNo - 16
WHERE p0.iNo >= 17  -- Нужно минимум 16 предыдущих
  AND p2.dPrice < p0.dPrice
  AND p3.dPrice > p1.dPrice
  AND p4.dPrice > p2.dPrice
  AND p6.dPrice < p4.dPrice
  AND p7.dPrice < p5.dPrice
  AND p7.dPrice < p1.dPrice
  AND p9.dPrice > p7.dPrice
  AND p10.dPrice > p8.dPrice
  AND p12.dPrice < p10.dPrice
  AND p13.dPrice < p11.dPrice
  AND p13.dPrice > p7.dPrice
  AND p15.dPrice > p13.dPrice
  AND p16.dPrice > p14.dPrice
  AND p16.dPrice > p10.dPrice;

-- Показать первые 10 примеров для проверки
WITH numbered AS (
  SELECT
    id,
    bar_extremum,
    bar_confirmed,
    price AS dPrice,
    direction,
    ray_size,
    ROW_NUMBER() OVER (ORDER BY bar_extremum) AS iNo
  FROM izzml.zz_extremums
  WHERE bar_confirmed IS NOT NULL
    AND symbol = 'EURUSD'
    AND timeframe = 'Range1'
    AND zz_delta = 1.5
)
SELECT
  p0.iNo,
  p0.bar_extremum,
  p0.dPrice AS p0_price,
  p1.dPrice AS p1_price,
  p2.dPrice AS p2_price,
  p7.dPrice AS p7_price,
  p10.dPrice AS p10_price,
  p13.dPrice AS p13_price,
  p16.dPrice AS p16_price
FROM numbered p0
JOIN numbered p1 ON p1.iNo = p0.iNo - 1
JOIN numbered p2 ON p2.iNo = p0.iNo - 2
JOIN numbered p3 ON p3.iNo = p0.iNo - 3
JOIN numbered p4 ON p4.iNo = p0.iNo - 4
JOIN numbered p5 ON p5.iNo = p0.iNo - 5
JOIN numbered p6 ON p6.iNo = p0.iNo - 6
JOIN numbered p7 ON p7.iNo = p0.iNo - 7
JOIN numbered p8 ON p8.iNo = p0.iNo - 8
JOIN numbered p9 ON p9.iNo = p0.iNo - 9
JOIN numbered p10 ON p10.iNo = p0.iNo - 10
JOIN numbered p11 ON p11.iNo = p0.iNo - 11
JOIN numbered p12 ON p12.iNo = p0.iNo - 12
JOIN numbered p13 ON p13.iNo = p0.iNo - 13
JOIN numbered p14 ON p14.iNo = p0.iNo - 14
JOIN numbered p15 ON p15.iNo = p0.iNo - 15
JOIN numbered p16 ON p16.iNo = p0.iNo - 16
WHERE p0.iNo >= 17
  AND p2.dPrice < p0.dPrice
  AND p3.dPrice > p1.dPrice
  AND p4.dPrice > p2.dPrice
  AND p6.dPrice < p4.dPrice
  AND p7.dPrice < p5.dPrice
  AND p7.dPrice < p1.dPrice
  AND p9.dPrice > p7.dPrice
  AND p10.dPrice > p8.dPrice
  AND p12.dPrice < p10.dPrice
  AND p13.dPrice < p11.dPrice
  AND p13.dPrice > p7.dPrice
  AND p15.dPrice > p13.dPrice
  AND p16.dPrice > p14.dPrice
  AND p16.dPrice > p10.dPrice
ORDER BY p0.iNo
LIMIT 10;
