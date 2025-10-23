# BTI MCP Reference - Справочник работы с БД

## 🚀 Быстрый старт для Claude Code

### Базовый доступ к БД
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT COUNT(*) FROM \"Tasks\""}'
```

## 📋 Доступные MCP инструменты

### 1. query_database - SQL запросы
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT * FROM \"RunSession\" LIMIT 5"}'
```

### 2. log_event - Логирование эволюции
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/log_event \
  -H "Content-Type: application/json" \
  -d '{"request": {"sEvent": "Название события", "sDescription": "Описание"}}'
```

### 3. get_task_stats - Статистика заданий
```bash
curl -s http://62.149.5.16:5080/api/tasks/stats
```

## 🗄️ Структура БД (основные таблицы)

### Tasks - Очередь заданий
```sql
"Id" (int) - ID задания
"sTaskId" (text) - строковый ID
"sStatus" (text) - new/processing/completed
"iShNo" (int) - номер вектора
"sWorkerId" (text) - ID воркера
"tmCreated", "tmStarted", "tmCompleted" - временные метки
```

### Results - Результаты вычислений
```sql
"Id" (int) - ID результата
"sTaskId" (text) - связь с задание
"kUsed" (int) - использованное k
"iTPSL" (int) - индекс TPSL
"dProfitDDRatio" (double) - основная метрика
"adAxisWeights" (double[]) - веса осей
```

### RunSession - Итоги прогонов
```sql
"run_id" (text) - уникальный ID прогона
"tm_started" (timestamp) - время старта
"dFinalProfit" (double) - финальная прибыль
"dMaxDrawdown" (double) - максимальная просадка
"dProfitDDRatio" (double) - итоговое соотношение
"tmCompleted" (timestamp) - время завершения
```

### RunEquityPoints - Точки equity кривой
```sql
"run_id" (text) - связь с RunSession
"seq" (int) - порядковый номер точки
"tm" (timestamp) - время точки
"equity" (double) - значение equity
```

### BTI_Evolution_Log - Лог эволюции системы
```sql
"id" (int) - ID события
"tmEvent" (timestamp) - время события
"sEventType", "sComponent" - классификация
"sDescription" (text) - описание изменения
```

## 📊 Готовые запросы (копируй-вставляй)

### Проверка системы
```sql
-- Статистика заданий
SELECT "sStatus", COUNT(*) FROM "Tasks" GROUP BY "sStatus";

-- Последние результаты
SELECT "sTaskId", "dProfitDDRatio", "kUsed", "iTPSL"
FROM "Results" ORDER BY "Id" DESC LIMIT 10;

-- Итоги последних прогонов
SELECT "run_id", "dFinalProfit", "dProfitDDRatio", "tm_started"
FROM "RunSession" ORDER BY "tm_started" DESC LIMIT 5;
```

### Анализ эффективности
```sql
-- Распределение k-NN значений
SELECT "kUsed", COUNT(*), AVG("dProfitDDRatio")
FROM "Results" GROUP BY "kUsed" ORDER BY "kUsed";

-- История эволюции системы
SELECT "tmEvent", "sDescription"
FROM "BTI_Evolution_Log" ORDER BY "tmEvent" DESC LIMIT 10;
```

## 🔧 Частые операции

### Очистка результатов
```bash
curl -s -X DELETE http://62.149.5.16:5080/api/tasks/clear
```

### Проверка equity последнего прогона
```sql
SELECT COUNT(*) as points FROM "RunEquityPoints"
WHERE "run_id" = (SELECT "run_id" FROM "RunSession" ORDER BY "tm_started" DESC LIMIT 1);
```

## ⚡ Советы для работы

1. **Всегда экранируй имена** таблиц и полей: `"TableName"`
2. **Проверяй подключение** перед сложными запросами: `SELECT 1`
3. **Используй LIMIT** для больших таблиц: `LIMIT 100`
4. **Логируй важные изменения** через `log_event`

## 🚨 Важные URL

- **Сервер БД**: http://62.149.5.16:5080
- **Локальный тест**: http://localhost:5080
- **MCP эндпоинты**: `/mcp/tools/`
- **API эндпоинты**: `/api/tasks/`