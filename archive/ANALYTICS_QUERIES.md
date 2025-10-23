# BTI Analytics Queries - Стандартные запросы для анализа

## 📊 ОБЩАЯ СТАТИСТИКА СИСТЕМЫ

### Базовая статистика циклов
```sql
-- Общее количество циклов и точек equity
SELECT COUNT(DISTINCT run_id) as total_runs,
       COUNT(*) as total_equity_points,
       AVG(equity) as avg_equity,
       MIN(equity) as min_equity,
       MAX(equity) as max_equity
FROM "RunEquityPoints";
```

### Статистика блоков анализа
```sql
-- Количество блоков анализа по типам
SELECT block_type,
       COUNT(*) as blocks_count,
       COUNT(DISTINCT run_id) as runs_with_blocks
FROM runanalysisblocks
GROUP BY block_type
ORDER BY blocks_count DESC;
```

### Циклы с полным анализом
```sql
-- Циклы имеющие все 5 блоков анализа
SELECT run_id, COUNT(*) as blocks_count
FROM runanalysisblocks
GROUP BY run_id
HAVING COUNT(*) = 5
ORDER BY run_id DESC;
```

## 🎯 АНАЛИЗ ОПТИМАЛЬНЫХ ПАРАМЕТРОВ

### Распределение TPSL индексов
```sql
-- Извлечение и анализ TPSL распределения
SELECT run_id, content_lines
FROM runanalysisblocks
WHERE block_type = 'tpsl_distribution'
ORDER BY "id" DESC LIMIT 10;
```

### Распределение k-NN значений
```sql
-- Анализ эффективности k-NN
SELECT run_id, content_lines
FROM runanalysisblocks
WHERE block_type = 'knn_distribution'
ORDER BY "id" DESC LIMIT 10;
```

### Распределение размеров окон
```sql
-- Анализ ширины окон
SELECT run_id, content_lines
FROM runanalysisblocks
WHERE block_type = 'window_distribution'
ORDER BY "id" DESC LIMIT 10;
```

### Рекомендации системы
```sql
-- Последние рекомендации по оптимизации
SELECT run_id, content_lines
FROM runanalysisblocks
WHERE block_type = 'recommendations'
ORDER BY "id" DESC LIMIT 5;
```

## 📈 ФИНАНСОВЫЕ МЕТРИКИ

### Статистика Profit/DD Ratio
```sql
-- Анализ Profit/DD Ratio по циклам
SELECT run_id, content_lines
FROM runanalysisblocks
WHERE block_type = 'ratio_statistics'
ORDER BY "id" DESC LIMIT 10;
```

### Финальные результаты по циклам
```sql
-- Финальные equity значения по каждому циклу
SELECT run_id,
       MAX(equity) as final_equity,
       COUNT(*) as equity_points,
       MIN(equity) as min_equity_in_cycle,
       MAX(equity) - MIN(equity) as equity_range
FROM "RunEquityPoints"
WHERE seq = (SELECT MAX(seq) FROM "RunEquityPoints" as rp2 WHERE rp2.run_id = "RunEquityPoints".run_id)
GROUP BY run_id
ORDER BY final_equity DESC;
```

### Статистика просадок по всем циклам
```sql
-- Средние показатели финальных результатов
SELECT AVG(equity) as avg_final_equity,
       MIN(equity) as worst_result,
       MAX(equity) as best_result,
       STDDEV(equity) as volatility,
       COUNT(*) as total_final_results
FROM "RunEquityPoints"
WHERE seq = (SELECT MAX(seq) FROM "RunEquityPoints" as rp2 WHERE rp2.run_id = "RunEquityPoints".run_id);
```

## 🔍 ДИАГНОСТИКА И ТРЕНДЫ

### Хронология развития системы
```sql
-- История эволюции BTI системы
SELECT "Id", "tmEvent", "sEventType", "sDescription", "dProfitDDRatio"
FROM "BTI_Evolution_Log"
ORDER BY "Id" DESC LIMIT 10;
```

### Циклы с аномальными результатами
```sql
-- Поиск циклов с низкими результатами (equity < 0)
SELECT run_id, equity as negative_result, seq, tm
FROM "RunEquityPoints"
WHERE equity < 0
AND seq = (SELECT MAX(seq) FROM "RunEquityPoints" as rp2 WHERE rp2.run_id = "RunEquityPoints".run_id)
ORDER BY equity ASC;
```

### Временная динамика результатов
```sql
-- Последние 5 завершённых циклов с их результатами
SELECT rs.run_id,
       MAX(rep.equity) as final_equity,
       COUNT(rep.seq) as equity_points
FROM "RunSession" rs
JOIN "RunEquityPoints" rep ON rs.run_id = rep.run_id
GROUP BY rs.run_id
ORDER BY rs.run_id DESC
LIMIT 5;
```

## 🎯 БЫСТРЫЕ ПРОВЕРКИ ДЛЯ CLAUDE

### Полная сводка системы (1 запрос)
```sql
-- Комплексная статистика для анализа
SELECT
    'runs' as metric, COUNT(DISTINCT run_id)::text as value
FROM "RunSession"
UNION ALL
SELECT
    'equity_points' as metric, COUNT(*)::text as value
FROM "RunEquityPoints"
UNION ALL
SELECT
    'analysis_blocks' as metric, COUNT(*)::text as value
FROM runanalysisblocks
UNION ALL
SELECT
    'avg_final_equity' as metric, ROUND(AVG(equity), 2)::text as value
FROM "RunEquityPoints"
WHERE seq = (SELECT MAX(seq) FROM "RunEquityPoints" as rp2 WHERE rp2.run_id = "RunEquityPoints".run_id);
```

### Последние рекомендации и статистика (1 запрос)
```sql
-- Последний цикл: рекомендации + статистика
WITH latest_run AS (
    SELECT run_id
    FROM runanalysisblocks
    WHERE block_type = 'recommendations'
    ORDER BY "id" DESC LIMIT 1
)
SELECT block_type, block_title, content_lines
FROM runanalysisblocks
WHERE run_id = (SELECT run_id FROM latest_run)
ORDER BY
    CASE block_type
        WHEN 'recommendations' THEN 1
        WHEN 'ratio_statistics' THEN 2
        WHEN 'tpsl_distribution' THEN 3
        WHEN 'knn_distribution' THEN 4
        WHEN 'window_distribution' THEN 5
    END;
```

## 📋 ИСПОЛЬЗОВАНИЕ

**Для Claude Code:**
1. Копировать нужный запрос из этого файла
2. Выполнить через MCP: `curl -X POST http://62.149.5.16:5080/mcp/tools/query_database`
3. Анализировать результаты без трат времени на написание SQL

**Категории по приоритету:**
- **Быстрые проверки** - для общего понимания состояния
- **Финансовые метрики** - для анализа производительности
- **Анализ параметров** - для рекомендаций по оптимизации
- **Диагностика** - для поиска проблем

---
*Файл создан для экономии времени и ресурсов при анализе BTI системы*