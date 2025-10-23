# ⚠️ КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ АРХИТЕКТУРЫ BTI

**Дата**: 2024-09-23
**Статус**: АКТИВНО

## 🚫 УСТАРЕВШИЕ ФАЙЛЫ ПЕРЕМЕЩЕНЫ В archive/

Следующие файлы **НЕ АКТУАЛЬНЫ** и перемещены в `archive/`:
- `BTI_MASTER_TREE.md` ❌
- `BTI_QUERY_TREE.md` ❌
- `BTI_MCP_REFERENCE.md` ❌
- `ANALYTICS_QUERIES.md` ❌
- `VECTORS_SYNC_ALGORITHM.md` ❌

## ✅ НОВАЯ АРХИТЕКТУРА: ВСЁ В POSTGRESQL

**База Знаний теперь в БД:**
```sql
-- Навигация по задачам
SELECT * FROM "BTI_Master_Tree" WHERE "sKeywords" ILIKE '%ваш_запрос%';

-- История эволюции
SELECT * FROM "BTI_Evolution_Log" ORDER BY "tmEvent" DESC;
```

## 📋 АКТИВНЫЕ ФАЙЛЫ:

### Основные правила и конфигурация:
- `CLAUDE.md` ✅ - Главные правила работы с BTI
- `UAnotat.md` ✅ - Правила кодирования
- `claude_dialog_rules.md` ✅ - Правила общения

### Документация процессов:
- `BTI.md` ✅ - Общее описание системы
- `MCP_MANDATORY_PROTOCOL.md` ✅ - Протокол безопасности
- `PYTHON_TRANSITION_PLAN.md` ✅ - План перехода на Python

### Технические отчёты:
- `MCP_IMPLEMENTATION_REPORT.md` ✅ - Отчёт по MCP
- `CC_Logging_System.md` ✅ - Система логирования
- `ACTIVE_CONTROL_SYSTEM.md` ✅ - Система контроля

## 🎯 КАК РАБОТАТЬ С НОВОЙ АРХИТЕКТУРОЙ:

1. **Поиск информации**: Запрос к `BTI_Master_Tree`
2. **Добавление знаний**: INSERT в `BTI_Master_Tree`
3. **Логирование**: через `log_event` в `BTI_Evolution_Log`
4. **Экономия токенов**: 99%+ улучшение

## 🔗 БЫСТРЫЕ ССЫЛКИ:

```bash
# Проверить систему
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT * FROM \"BTI_Master_Tree\" WHERE \"sSection\" = \"CHECK\""}'

# Найти по ключевым словам
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "SELECT * FROM \"BTI_Master_Tree\" WHERE \"sKeywords\" ILIKE \"%tasks%\""}'
```

---
**🚨 ВАЖНО**: Не читайте файлы из `archive/` - они устарели!