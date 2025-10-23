# УНИВЕРСАЛЬНЫЙ CLAUDE КОНТЕКСТ

## 🎯 ЕДИНСТВЕННОЕ ПРАВИЛО

**ВСЯ ИНФОРМАЦИЯ В PostgreSQL БД:** 62.149.5.16:5080

### 🚀 ПЕРВОЕ ДЕЙСТВИЕ КАЖДОГО СЕАНСА:

```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -d '{"sSqlQuery": "SELECT * FROM \"BTI_Master_Tree\" WHERE \"sPriority\" IN (\"CRITICAL\", \"HIGH\") ORDER BY \"sSection\""}'
```

**КЭШИРОВАТЬ В ПАМЯТИ СЕАНСА:**
- Правила поведения (CORE)
- Debug лог и методы диагностики
- Структуры БД и SQL шаблоны
- Документацию систем

### 🔄 РАБОЧИЙ ПРОЦЕСС:

1. **Старт** → Кэш БЗ в память
2. **Работа** → 90% из кэша
3. **Новое** → Добавить через `/mcp/tools/add_knowledge`
4. **Ошибки** → Логировать в debug БЗ

### 📊 ДОСТУПНЫЕ MCP ЭНДПОИНТЫ:

- `/mcp/tools/query_database` - SQL запросы
- `/mcp/tools/add_knowledge` - добавление в БЗ
- `/mcp/tools/log_claude_dialog` - логирование диалогов

---

**ВСЁ ОСТАЛЬНОЕ ЧИТАТЬ ИЗ БД!**