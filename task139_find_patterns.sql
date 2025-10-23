-- ЗАДАНИЕ #139: Поиск паттернов ZigZag по 14 условиям

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
),
-- Шаг 2: Для каждого экстремума получаем 16 предыдущих
patterns AS (
  SELECT
    p0.iNo,
    p0.bar_extremum,
    p0.dPrice AS p0_price,

    -- Получаем предыдущие 16 экстремумов через LATERAL JOIN
    prev.p1_price, prev.p2_price, prev.p3_price, prev.p4_price,
    prev.p5_price, prev.p6_price, prev.p7_price, prev.p8_price,
    prev.p9_price, prev.p10_price, prev.p11_price, prev.p12_price,
    prev.p13_price, prev.p14_price, prev.p15_price, prev.p16_price

  FROM numbered p0
  CROSS JOIN LATERAL (
    SELECT
      MAX(CASE WHEN rn = 1 THEN dPrice END) AS p1_price,
      MAX(CASE WHEN rn = 2 THEN dPrice END) AS p2_price,
      MAX(CASE WHEN rn = 3 THEN dPrice END) AS p3_price,
      MAX(CASE WHEN rn = 4 THEN dPrice END) AS p4_price,
      MAX(CASE WHEN rn = 5 THEN dPrice END) AS p5_price,
      MAX(CASE WHEN rn = 6 THEN dPrice END) AS p6_price,
      MAX(CASE WHEN rn = 7 THEN dPrice END) AS p7_price,
      MAX(CASE WHEN rn = 8 THEN dPrice END) AS p8_price,
      MAX(CASE WHEN rn = 9 THEN dPrice END) AS p9_price,
      MAX(CASE WHEN rn = 10 THEN dPrice END) AS p10_price,
      MAX(CASE WHEN rn = 11 THEN dPrice END) AS p11_price,
      MAX(CASE WHEN rn = 12 THEN dPrice END) AS p12_price,
      MAX(CASE WHEN rn = 13 THEN dPrice END) AS p13_price,
      MAX(CASE WHEN rn = 14 THEN dPrice END) AS p14_price,
      MAX(CASE WHEN rn = 15 THEN dPrice END) AS p15_price,
      MAX(CASE WHEN rn = 16 THEN dPrice END) AS p16_price
    FROM (
      SELECT dPrice, ROW_NUMBER() OVER (ORDER BY iNo DESC) AS rn
      FROM numbered
      WHERE iNo < p0.iNo
      ORDER BY iNo DESC
      LIMIT 16
    ) sub
  ) prev
  WHERE p0.iNo >= 17  -- Нужно минимум 16 предыдущих
)
-- Шаг 3: Проверяем 14 условий паттерна
SELECT
  COUNT(*) AS n_patterns,
  MIN(iNo) AS first_match_iNo,
  MAX(iNo) AS last_match_iNo
FROM patterns
WHERE
  p2_price < p0_price
  AND p3_price > p1_price
  AND p4_price > p2_price
  AND p6_price < p4_price
  AND p7_price < p5_price
  AND p7_price < p1_price
  AND p9_price > p7_price
  AND p10_price > p8_price
  AND p12_price < p10_price
  AND p13_price < p11_price
  AND p13_price > p7_price
  AND p15_price > p13_price
  AND p16_price > p14_price
  AND p16_price > p10_price;

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
),
patterns AS (
  SELECT
    p0.iNo,
    p0.bar_extremum,
    p0.dPrice AS p0_price,

    prev.p1_price, prev.p2_price, prev.p3_price, prev.p4_price,
    prev.p5_price, prev.p6_price, prev.p7_price, prev.p8_price,
    prev.p9_price, prev.p10_price, prev.p11_price, prev.p12_price,
    prev.p13_price, prev.p14_price, prev.p15_price, prev.p16_price

  FROM numbered p0
  CROSS JOIN LATERAL (
    SELECT
      MAX(CASE WHEN rn = 1 THEN dPrice END) AS p1_price,
      MAX(CASE WHEN rn = 2 THEN dPrice END) AS p2_price,
      MAX(CASE WHEN rn = 3 THEN dPrice END) AS p3_price,
      MAX(CASE WHEN rn = 4 THEN dPrice END) AS p4_price,
      MAX(CASE WHEN rn = 5 THEN dPrice END) AS p5_price,
      MAX(CASE WHEN rn = 6 THEN dPrice END) AS p6_price,
      MAX(CASE WHEN rn = 7 THEN dPrice END) AS p7_price,
      MAX(CASE WHEN rn = 8 THEN dPrice END) AS p8_price,
      MAX(CASE WHEN rn = 9 THEN dPrice END) AS p9_price,
      MAX(CASE WHEN rn = 10 THEN dPrice END) AS p10_price,
      MAX(CASE WHEN rn = 11 THEN dPrice END) AS p11_price,
      MAX(CASE WHEN rn = 12 THEN dPrice END) AS p12_price,
      MAX(CASE WHEN rn = 13 THEN dPrice END) AS p13_price,
      MAX(CASE WHEN rn = 14 THEN dPrice END) AS p14_price,
      MAX(CASE WHEN rn = 15 THEN dPrice END) AS p15_price,
      MAX(CASE WHEN rn = 16 THEN dPrice END) AS p16_price
    FROM (
      SELECT dPrice, ROW_NUMBER() OVER (ORDER BY iNo DESC) AS rn
      FROM numbered
      WHERE iNo < p0.iNo
      ORDER BY iNo DESC
      LIMIT 16
    ) sub
  ) prev
  WHERE p0.iNo >= 17
)
SELECT
  iNo,
  bar_extremum,
  p0_price,
  p1_price, p2_price, p7_price, p10_price, p13_price, p16_price
FROM patterns
WHERE
  p2_price < p0_price
  AND p3_price > p1_price
  AND p4_price > p2_price
  AND p6_price < p4_price
  AND p7_price < p5_price
  AND p7_price < p1_price
  AND p9_price > p7_price
  AND p10_price > p8_price
  AND p12_price < p10_price
  AND p13_price < p11_price
  AND p13_price > p7_price
  AND p15_price > p13_price
  AND p16_price > p14_price
  AND p16_price > p10_price
ORDER BY iNo
LIMIT 10;
