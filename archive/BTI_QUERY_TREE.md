# BTI Query Tree - Дерево запросов к БД

## 🌳 Навигация по задачам

### 📊 ПРОВЕРКА СОСТОЯНИЯ СИСТЕМЫ
#### ├── Общее состояние
```sql
-- Быстрая проверка всех компонентов
SELECT 'Tasks' as table_name, COUNT(*) as count FROM "Tasks"
UNION ALL SELECT 'Results', COUNT(*) FROM "Results"
UNION ALL SELECT 'RunSession', COUNT(*) FROM "RunSession";
```

#### ├── Статус заданий
```sql
-- Распределение заданий по статусам
SELECT "sStatus", COUNT(*) FROM "Tasks" GROUP BY "sStatus";
```

#### └── Последняя активность
```sql
-- Когда была последняя активность
SELECT MAX("tmCreated") as last_task, MAX("tmCompleted") as last_completed
FROM "Tasks";
```

### 🎯 АНАЛИЗ РЕЗУЛЬТАТОВ
#### ├── Последние результаты
```sql
-- 10 последних результатов с ключевыми метриками
SELECT "sTaskId", "dProfitDDRatio", "kUsed", "iTPSL", "iShNo"
FROM "Results" ORDER BY "Id" DESC LIMIT 10;
```

#### ├── Статистика по параметрам
##### │   ├── По k-NN значениям
```sql
SELECT "kUsed", COUNT(*) as count, AVG("dProfitDDRatio") as avg_ratio,
       MIN("dProfitDDRatio") as min_ratio, MAX("dProfitDDRatio") as max_ratio
FROM "Results" GROUP BY "kUsed" ORDER BY "kUsed";
```

##### │   ├── По TPSL индексам
```sql
SELECT "iTPSL", COUNT(*) as count, AVG("dProfitDDRatio") as avg_ratio
FROM "Results" GROUP BY "iTPSL" ORDER BY avg_ratio DESC;
```

##### │   └── По векторам (iShNo)
```sql
SELECT "iShNo", COUNT(*) as tests, AVG("dProfitDDRatio") as avg_ratio
FROM "Results" GROUP BY "iShNo" ORDER BY avg_ratio DESC LIMIT 20;
```

#### └── Лучшие результаты
```sql
-- Топ-20 лучших результатов
SELECT "sTaskId", "dProfitDDRatio", "kUsed", "iTPSL", "iShNo"
FROM "Results" ORDER BY "dProfitDDRatio" DESC LIMIT 20;
```

### 📈 АНАЛИЗ ПРОГОНОВ
#### ├── Список всех прогонов
```sql
-- Все прогоны с основными метриками
SELECT "run_id", "tm_started", "dFinalProfit", "dMaxDrawdown", "dProfitDDRatio", "tmCompleted"
FROM "RunSession" ORDER BY "tm_started" DESC;
```

#### ├── Последний прогон детально
```sql
-- Детали последнего прогона
SELECT r.*,
       (SELECT COUNT(*) FROM "RunEquityPoints" WHERE "run_id" = r."run_id") as equity_points
FROM "RunSession" r ORDER BY "tm_started" DESC LIMIT 1;
```

#### ├── Equity кривая прогона
```sql
-- Equity точки конкретного прогона (замени run_id)
SELECT "seq", "tm", "equity"
FROM "RunEquityPoints"
WHERE "run_id" = 'YOUR_RUN_ID'
ORDER BY "seq";
```

#### └── Сравнение прогонов
```sql
-- Сравнение последних 5 прогонов
SELECT "run_id", "dFinalProfit", "dProfitDDRatio",
       EXTRACT(EPOCH FROM ("tmCompleted" - "tm_started"))/60 as duration_minutes
FROM "RunSession"
WHERE "tmCompleted" IS NOT NULL
ORDER BY "tm_started" DESC LIMIT 5;
```

### 🔍 ДИАГНОСТИКА ПРОБЛЕМ
#### ├── Зависшие задания
```sql
-- Задания в processing дольше 1 часа
SELECT "sTaskId", "sWorkerId", "tmStarted",
       EXTRACT(EPOCH FROM (NOW() - "tmStarted"))/3600 as hours_ago
FROM "Tasks"
WHERE "sStatus" = 'processing'
  AND "tmStarted" < NOW() - INTERVAL '1 hour';
```

#### ├── Проблемные воркеры
```sql
-- Воркеры с необычной активностью
SELECT "sWorkerId", COUNT(*) as tasks,
       MIN("tmStarted") as first_task, MAX("tmCompleted") as last_task
FROM "Tasks"
WHERE "sWorkerId" IS NOT NULL
GROUP BY "sWorkerId" ORDER BY tasks DESC;
```

#### └── Ошибки в результатах
```sql
-- Результаты с подозрительными значениями
SELECT "sTaskId", "dProfitDDRatio", "kUsed", "iTPSL"
FROM "Results"
WHERE "dProfitDDRatio" < 0 OR "dProfitDDRatio" > 10
ORDER BY "dProfitDDRatio";
```

### 🧹 ОЧИСТКА И ОБСЛУЖИВАНИЕ
#### ├── Очистка тестовых данных
```sql
-- Удаление всех заданий и результатов (ОСТОРОЖНО!)
TRUNCATE TABLE "Tasks", "Results" RESTART IDENTITY CASCADE;
```

#### ├── Очистка итогов прогонов
```sql
-- Удаление итогов прогонов (ОСТОРОЖНО!)
TRUNCATE TABLE "RunSession", "RunEquityPoints", "runanalysisblocks" RESTART IDENTITY CASCADE;
```

#### └── Архивация старых данных
```sql
-- Подсчёт данных старше 30 дней
SELECT COUNT(*) FROM "Tasks" WHERE "tmCreated" < NOW() - INTERVAL '30 days';
```

### 📊 ОТЧЁТЫ И АНАЛИТИКА
#### ├── Эффективность параметров
```sql
-- Какие параметры дают лучшие результаты
WITH best_params AS (
  SELECT "kUsed", "iTPSL", AVG("dProfitDDRatio") as avg_ratio
  FROM "Results" GROUP BY "kUsed", "iTPSL"
)
SELECT * FROM best_params WHERE avg_ratio > 1.0 ORDER BY avg_ratio DESC;
```

#### ├── Временная динамика
```sql
-- Улучшается ли система со временем
SELECT DATE("tmCreated") as date,
       COUNT(*) as tasks, AVG("dProfitDDRatio") as avg_ratio
FROM "Results" r JOIN "Tasks" t ON r."sTaskId" = t."sTaskId"
GROUP BY DATE("tmCreated") ORDER BY date DESC LIMIT 30;
```

#### └── История эволюции
```sql
-- Последние изменения в системе
SELECT "tmEvent", "sDescription"
FROM "BTI_Evolution_Log"
ORDER BY "tmEvent" DESC LIMIT 20;
```

## 🔄 API альтернативы (без SQL)

### Быстрые проверки через API
```bash
# Статистика заданий
curl -s http://62.149.5.16:5080/api/tasks/stats

# Очистка заданий
curl -s -X DELETE http://62.149.5.16:5080/api/tasks/clear

# Лучшие результаты
curl -s http://62.149.5.16:5080/api/tasks/results/finalize
```

## 💡 Как пользоваться деревом

1. **Определи задачу**: Что именно нужно узнать?
2. **Найди раздел**: Навигируй по дереву к нужной категории
3. **Выбери запрос**: Копируй готовый SQL
4. **Адаптируй**: Замени параметры если нужно
5. **Выполни**: Через curl или MCP

## 🚨 Частые задачи (быстрый доступ)

| Задача | Раздел | Запрос |
|--------|--------|--------|
| Сколько новых заданий? | Проверка состояния → Статус заданий | `SELECT COUNT(*) FROM "Tasks" WHERE "sStatus" = 'new'` |
| Последние результаты? | Анализ результатов → Последние результаты | `SELECT * FROM "Results" ORDER BY "Id" DESC LIMIT 10` |
| Итоги последнего прогона? | Анализ прогонов → Последний прогон | `SELECT * FROM "RunSession" ORDER BY "tm_started" DESC LIMIT 1` |
| Очистить всё? | Очистка → Очистка тестовых данных | `TRUNCATE TABLE...` |