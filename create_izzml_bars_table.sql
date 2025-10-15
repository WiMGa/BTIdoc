-- Создание таблицы izzml.bars для хранения Close цен по барам
CREATE TABLE IF NOT EXISTS izzml.bars (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    timeframe VARCHAR(10) NOT NULL,
    bar INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    close NUMERIC(10,5) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Уникальный индекс по symbol + timeframe + bar
CREATE UNIQUE INDEX IF NOT EXISTS idx_bars_unique ON izzml.bars(symbol, timeframe, bar);

-- Индекс по номеру бара
CREATE INDEX IF NOT EXISTS idx_bars_bar ON izzml.bars(bar);

-- Индекс по времени
CREATE INDEX IF NOT EXISTS idx_bars_timestamp ON izzml.bars(timestamp);

-- Индекс по symbol + timeframe
CREATE INDEX IF NOT EXISTS idx_bars_symbol_tf ON izzml.bars(symbol, timeframe);

-- Композитный индекс для быстрого поиска по symbol + timeframe + timestamp
CREATE INDEX IF NOT EXISTS idx_bars_composite ON izzml.bars(symbol, timeframe, timestamp);

-- Комментарии
COMMENT ON TABLE izzml.bars IS 'Таблица Close цен по барам из индикатора izzML';
COMMENT ON COLUMN izzml.bars.symbol IS 'Символ инструмента (EURUSD, GBPUSD, etc.)';
COMMENT ON COLUMN izzml.bars.timeframe IS 'Таймфрейм (Range1, Range5, m1, m5, etc.)';
COMMENT ON COLUMN izzml.bars.bar IS 'Номер бара (iBar) из индикатора';
COMMENT ON COLUMN izzml.bars.timestamp IS 'Время открытия бара (UTC)';
COMMENT ON COLUMN izzml.bars.close IS 'Цена закрытия бара';
