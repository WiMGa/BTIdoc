# BTI Project - Claude Code Instructions

---

## 🚨 ПАМЯТКА ПРИ КАЖДОМ ЗАПУСКЕ

**ПРИ НОВОМ СЕАНСЕ РАБОТЫ:**

1. 🔍 **ПЕРВЫМ ДЕЛОМ - ЧИТАТЬ БЗ:**
   
   Создать файл:
   ```bash
   cat > /c/Temp/search_bz.json << 'EOF'
   {"sSqlQuery": "SELECT * FROM core.search_knowledge('правила', 5)"}
   EOF
   ```
   
   Выполнить запрос:
   ```bash
   curl --data-binary @/c/Temp/search_bz.json http://62.149.5.16:5080/mcp/tools/query_database -H "Content-Type: application/json"
   ```

   ВСЕ правила работы в БЗ! Читать перед началом работы!

2. 📋 **Проверить pending задания:**
   
   Создать файл:
   ```bash
   cat > /c/Temp/get_tasks.json << 'EOF'
   {"sSqlQuery": "SELECT * FROM log.get_tasks('CCL')"}
   EOF
   ```
   
   Выполнить:
   ```bash
   curl --data-binary @/c/Temp/get_tasks.json http://62.149.5.16:5080/mcp/tools/query_database -H "Content-Type: application/json"
   ```

3. 💬 **Женский род, обращение "Вы"**

---

## 🔗 ДОСТУП К БД

**PostgreSQL API:** http://62.149.5.16:5080

**ВАЖНО:** Всегда использовать `--data-binary @file.json`, НЕ `-d` с экранированием!

**Алгоритм работы с БД:**
1. Создать JSON файл с запросом
2. Выполнить через curl --data-binary @файл.json

**Пример:**
```bash
cat > /c/Temp/query.json << 'EOF'
{"sSqlQuery": "SELECT * FROM core.search_knowledge('UAnotation', 3)"}
EOF

curl --data-binary @/c/Temp/query.json http://62.149.5.16:5080/mcp/tools/query_database -H "Content-Type: application/json"
```

---

## 📍 ГЛАВНОЕ ПРАВИЛО

**ВСЁ В БАЗЕ ЗНАНИЙ!**

Перед ответом ОБЯЗАТЕЛЬНО искать в БЗ через core.search_knowledge()

Процедуры БЗ:
- core.search_knowledge('keywords', limit) - поиск
- core.add_node(title, content, keywords[], type) - добавление (ТОЛЬКО через обсуждение!)
- core.update_node(id, content, title) - обновление

---

## 📊 СИСТЕМА BTI

Торговая аналитическая система на основе izzML.

Детали в БЗ: core.search_knowledge('BTI', 10)

---

## 📁 КЛЮЧЕВЫЕ ПУТИ

**Данные izzML:**
- C:\mega\izzMLmega\*.csv

**Проекты:**
- C:\Users\Gajda\source\repos\BTI_API\ - сервер
- C:\Users\Gajda\source\repos\ClaudeCodeLogger\ - логгер
- C:\Users\Gajda\source\repos\BTIdoc\ - документация

---

## ⚠️ КРИТИЧНО

**ВСЕГДА:**
- Читать БЗ при запуске
- Проверять задания
- Использовать JSON файлы для curl (--data-binary @file.json)
- Следовать UAnotation (префиксы типов обязательны)

**НИКОГДА:**
- Не использовать var
- Не изменять код без чтения и разрешения
- Не добавлять в БЗ без обсуждения
