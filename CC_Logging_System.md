# 📝 Система логирования Claude Code диалогов

## 🎯 Цель системы

Сохранение и восстановление полного контекста диалогов Claude Code для:
- **Восстановления контекста** при новых сеансах
- **Анализа эволюции решений** в BTI системе
- **Отслеживания принятых решений** и их результатов
- **Поиска по истории диалогов** для повторного использования решений

## 🏗️ Архитектура

```
Claude Code → curl → 62.149.5.16:5080/mcp/tools/query_database → PostgreSQL
```

**БЕЗ промежуточных прокси** - прямое подключение к серверному MCP BTI_API.

## 📊 Структура БД

### CC_Sessions - Сессии работы
```sql
CREATE TABLE CC_Sessions (
    Id SERIAL PRIMARY KEY,
    sSessionId VARCHAR(50) UNIQUE NOT NULL,
    tmStarted TIMESTAMP DEFAULT NOW(),
    tmLastActivity TIMESTAMP DEFAULT NOW(),
    sWorkingDirectory VARCHAR(500),
    sMainContext VARCHAR(100),           -- 'BTIman', 'BTIwork', 'analysis', 'debug'
    jsonMetadata JSONB,                  -- версии, настройки сессии
    bActive BOOLEAN DEFAULT true
);
```

### CC_Messages - Сообщения диалогов
```sql
CREATE TABLE CC_Messages (
    Id SERIAL PRIMARY KEY,
    iSessionId INTEGER REFERENCES CC_Sessions(Id),
    tmMessage TIMESTAMP DEFAULT NOW(),
    sMessageType VARCHAR(20) NOT NULL,  -- 'user', 'claude', 'system'
    sContent TEXT NOT NULL,
    sContext VARCHAR(50),                -- 'question', 'analysis', 'decision', 'result'
    jsonAttachments JSONB,               -- файлы, команды, результаты
    iParentMessageId INTEGER REFERENCES CC_Messages(Id) -- связь вопрос-ответ
);
```

### CC_Decisions - Ключевые решения
```sql
CREATE TABLE CC_Decisions (
    Id SERIAL PRIMARY KEY,
    iSessionId INTEGER REFERENCES CC_Sessions(Id),
    tmDecision TIMESTAMP DEFAULT NOW(),
    sDecisionType VARCHAR(50),           -- 'algorithm_change', 'bug_fix', 'optimization'
    sDescription TEXT NOT NULL,
    sBefore TEXT,                        -- состояние до
    sAfter TEXT,                         -- состояние после
    jsonMetrics JSONB,                   -- результаты (Profit/DD, время выполнения)
    bImplemented BOOLEAN DEFAULT false
);
```

### CC_File_References - Файлы в диалогах
```sql
CREATE TABLE CC_File_References (
    Id SERIAL PRIMARY KEY,
    iMessageId INTEGER REFERENCES CC_Messages(Id),
    sFilePath VARCHAR(500) NOT NULL,
    sOperation VARCHAR(20),              -- 'read', 'edit', 'create', 'mention'
    sFileHash VARCHAR(64),               -- для отслеживания изменений
    tmOperation TIMESTAMP DEFAULT NOW()
);
```

## 🔍 Индексы для поиска

```sql
CREATE INDEX idx_cc_sessions_active ON CC_Sessions(bActive, tmLastActivity);
CREATE INDEX idx_cc_messages_session_time ON CC_Messages(iSessionId, tmMessage);
CREATE INDEX idx_cc_messages_content_fts ON CC_Messages USING GIN(to_tsvector('russian', sContent));
CREATE INDEX idx_cc_decisions_type_time ON CC_Decisions(sDecisionType, tmDecision);
CREATE INDEX idx_cc_files_path ON CC_File_References(sFilePath);
```

## 💻 Команды для работы

### Создание новой сессии
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "INSERT INTO CC_Sessions (sSessionId, sWorkingDirectory, sMainContext, jsonMetadata) VALUES ('"'"'session_2024_09_22_analysis'"'"', '"'"'C:/Users/Gajda/source/repos/BTIdoc'"'"', '"'"'analysis'"'"', '"'"'{\"task\": \"system_analysis\", \"version\": \"1.0\"}'"'"') RETURNING Id"}'
```

### Логирование сообщения пользователя
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "INSERT INTO CC_Messages (iSessionId, sMessageType, sContent, sContext) VALUES (1, '"'"'user'"'"', '"'"'Анализ результатов BTI'"'"', '"'"'analysis'"'"')"}'
```

### Логирование решения
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "INSERT INTO CC_Decisions (iSessionId, sDecisionType, sDescription, sAfter, bImplemented) VALUES (1, '"'"'optimization'"'"', '"'"'Увеличение параметров k-NN'"'"', '"'"'k=3-50, окна=20-150'"'"', true)"}'
```

### Поиск по диалогам
```bash
# Найти все сессии по контексту
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT * FROM CC_Sessions WHERE sMainContext = '"'"'BTIman'"'"' ORDER BY tmStarted DESC"}'

# Найти решения по типу
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT * FROM CC_Decisions WHERE sDecisionType = '"'"'optimization'"'"' AND bImplemented = true"}'
```

## 🔄 Восстановление контекста

### Алгоритм восстановления контекста в новой сессии:
1. **Найти последнюю активную сессию** по рабочей директории
2. **Загрузить ключевые решения** из CC_Decisions
3. **Прочитать последние сообщения** для понимания контекста
4. **Определить текущее состояние проекта** из jsonMetrics

### Пример запроса восстановления:
```sql
-- Последняя сессия в BTIdoc
SELECT s.*,
       (SELECT COUNT(*) FROM CC_Messages m WHERE m.iSessionId = s.Id) as message_count,
       (SELECT COUNT(*) FROM CC_Decisions d WHERE d.iSessionId = s.Id AND d.bImplemented = true) as decisions_count
FROM CC_Sessions s
WHERE s.sWorkingDirectory LIKE '%BTIdoc%'
ORDER BY s.tmLastActivity DESC
LIMIT 1;

-- Ключевые решения из последней сессии
SELECT * FROM CC_Decisions
WHERE iSessionId = (последний_id) AND bImplemented = true
ORDER BY tmDecision DESC;
```

## 📈 Статистика созданной системы

**✅ Создано 2024-09-22:**
- **4 таблицы** с полной структурой логирования
- **5 индексов** для быстрого поиска
- **Первая сессия** (ID=1) протестирована
- **Прямое подключение** через серверный MCP работает

**🎯 Готовность:**
- ✅ Сохранение диалогов
- ✅ Восстановление контекста
- ✅ Поиск по истории
- ✅ Отслеживание решений
- ✅ Анализ эволюции системы

**💡 Использование:**
Теперь Claude Code может сохранять контекст каждой сессии и восстанавливать его при следующем запуске, обеспечивая непрерывность работы над BTI проектом.