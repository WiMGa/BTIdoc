-- Migration: Convert bti.t_result to array-based structure
-- Task #96: Store forecasts for all iBar [0..50]
-- Date: 2025-11-01

BEGIN;

-- 1. Удалить тестовые данные
TRUNCATE TABLE bti.t_result;

-- 2. Удалить старые скалярные поля
ALTER TABLE bti.t_result
  DROP COLUMN IF EXISTS i_bar,
  DROP COLUMN IF EXISTS d_price_mean,
  DROP COLUMN IF EXISTS d_price_stddev,
  DROP COLUMN IF EXISTS d_consensus,
  DROP COLUMN IF EXISTS d_density;

-- 3. Добавить новые поля-массивы [51 элемент для iBar 0..50]
ALTER TABLE bti.t_result
  ADD COLUMN ad_price_mean double precision[51] NOT NULL,
  ADD COLUMN ad_price_stddev double precision[51] NOT NULL,
  ADD COLUMN ad_consensus double precision[51] NOT NULL,
  ADD COLUMN ad_density double precision[51] NOT NULL,
  ADD COLUMN ad_price_actual double precision[51];

-- 4. Добавить constraint для проверки длины массивов
ALTER TABLE bti.t_result
  ADD CONSTRAINT check_array_lengths CHECK (
    array_length(ad_price_mean, 1) = 51 AND
    array_length(ad_price_stddev, 1) = 51 AND
    array_length(ad_consensus, 1) = 51 AND
    array_length(ad_density, 1) = 51 AND
    (ad_price_actual IS NULL OR array_length(ad_price_actual, 1) = 51)
  );

COMMIT;

-- Проверка структуры
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'bti'
  AND table_name = 't_result'
ORDER BY ordinal_position;
