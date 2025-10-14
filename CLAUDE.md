# BTI Project - Claude Code Instructions

---

## 🚨 ПАМЯТКА ПРИ КАЖДОМ ЗАПУСКЕ

**ПРИ НОВОМ СЕАНСЕ РАБОТЫ:**

1. ⚡ **ВСЕГДА читать из БД, НЕ из файлов!**
   - ❌ НЕ читать `desktop_openai_dialogs.txt`
   - ❌ НЕ использовать `tail`, `cat`, `head` для логов
   - ✅ Использовать `logging.get_recent_messages(30)`
   - ✅ Использовать `logging.get_do_messages(20)` для DO
   - **Экономия: 34,172 токена → 2,000 (94%!)**

2. 📋 **Проверить pending задания:**
   ```sql
   SELECT * FROM tasks.get_pending_tasks()
   ```

3. 🔄 **При "Восстанови контекст":**
   - Читать последние сообщения из БД
   - Проверять pending задания
   - Сообщать статус

4. ✅ **Завершать задания через JSON-RPC:**
   - Использовать `manage_task` с `sAction="complete"`
   - НЕ делать прямой UPDATE в БД

5. 💬 **Женский род, обращение "Вы"**

---

## 🔄 ВОССТАНОВЛЕНИЕ КОНТЕКСТА ПОСЛЕ ПЕРЕЗАПУСКА

**КОМАНДА:** "Восстанови контекст"

**ДЕЙСТВИЯ:**
1. Читай последние сообщения: `logging.get_recent_messages(30)`
2. Проверяй pending задания: `tasks.get_pending_tasks()`
3. Сообщи статус готовности

---

## 📊 СИСТЕМА BTI (Back Test Intelligence)

Торговая аналитическая система на основе izzML (индикатор ZigZag Machine Learning):
- Анализ паттернов ZigZag для прогнозирования движений
- Оптимизация TP/SL параметров
- Train/Test валидация стратегий
- Секторизация рынка (Flat/Mid/Strong)

**Текущий фокус:** izzML анализ EURUSD Range1 Δ=1.5

---

## 🔗 ДОСТУП К БД

**PostgreSQL API:** `http://62.149.5.16:5080`

**JSON-RPC endpoint:**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"query_database","arguments":{"sSqlQuery":"SELECT * FROM logging.get_recent_messages(10)"}}}'
```

**Упрощённый endpoint (только для query_database):**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM tasks.get_pending_tasks()"}'
```

---

## ⚡ ПРАВИЛА ОПТИМИЗАЦИИ ТОКЕНОВ

### КРИТИЧЕСКИ ВАЖНО: ВСЕГДА ЧИТАТЬ ИЗ БД, НЕ ИЗ ФАЙЛОВ!

**ЗАПРЕЩЕНО:**
- ❌ Читать `desktop_openai_dialogs.txt` (34,172 токена)
- ❌ Читать `desktop_claude_dialogs.txt` (аналогично)
- ❌ Использовать `tail`, `head`, `cat` для логов

**ОБЯЗАТЕЛЬНО:**
- ✅ Читать из БД через процедуры (экономия 94% токенов!)
- ✅ `logging.get_do_messages(20)` - для DO диалогов
- ✅ `logging.get_recent_messages(30)` - для CC/DC
- ✅ Фильтровать по `s_window_title` если нужна тема

### Доступные процедуры:

**Desktop OpenAI (DO):**
```sql
SELECT * FROM logging.get_do_messages(20);
SELECT * FROM logging.search_do_by_title('%equity%', 10);
```

**Claude Code / Desktop Claude:**
```sql
SELECT * FROM logging.get_recent_messages(30);
SELECT * FROM logging.get_messages_after(3500);
```

**Поиск:**
```sql
SELECT * FROM logging.smart_search_messages('trading strategy', 10);
```

| Метод | Токены | Экономия |
|-------|--------|----------|
| ❌ Файл .txt | 34,172 | 0% |
| ✅ БД процедура | ~2,000 | **94%** |

---

## 📝 ПРАВИЛА КОДИРОВАНИЯ (UAnotation)

### Префиксы типов (ОБЯЗАТЕЛЬНО)
- `i*` - int: `iCount`, `iTaskId`, `iBar`
- `d*` - double: `dPrice`, `dProfit`, `dAlpha`
- `s*` - string: `sTitle`, `sJson`, `sSector`
- `b*` - bool: `bSuccess`, `bIniciator`
- `tm*` - DateTime: `tmCreated`, `tmMessage`
- `ad*` - double[]: `adPrices`, `adAngles`
- `ai*` - int[]: `aiWindows`, `aiIndexes`
- `l*` - List: `lVectors`, `lResults`
- `dc*` - Dictionary: `dcParams`
- `e*` - объекты: `eTask`, `eSegment`

### ЗАПРЕЩЕНО
- `var` - только явные типы
- Маскировка ошибок

### ОБЯЗАТЕЛЬНО
- Честный крах при ошибках
- Явность > неявность

---

## 💬 ПРАВИЛА ДИАЛОГА

- ✅ Женский род
- ✅ Обращение "Вы"
- ✅ Профессиональный тон
- ✅ Однозначные ответы
- ✅ Анализ граничных случаев
- ✅ Признание ошибок

---

## 🔧 РАБОТА С ЗАДАНИЯМИ

### Протокол выполнения:

**1. Получить pending:**
```sql
SELECT * FROM tasks.get_pending_tasks()
```

**2. Прочитать новый диалог:**
```sql
SELECT * FROM logging.get_messages_after(i_last_message_cc)
```

**3. Выполнить согласно `s_description`**

**4. ЗАВЕРШИТЬ через JSON-RPC:**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"manage_task","arguments":{"sAction":"complete","iTaskId":120,"sResult":"Vypolneno uspeshno (translit)","sCompletedBy":"CC"}}}'
```

**ЗАПРЕЩЕНО:**
- ❌ Прямой UPDATE в БД
- ❌ manage_task с sAction="update"
- ❌ Русский текст если кракозябры

**ПРАВИЛЬНО:**
- ✅ JSON-RPC manage_task complete
- ✅ Транслит для sResult
- ✅ sCompletedBy = "CC"

---

## ⚠️ ПРОТОКОЛ ИЗМЕНЕНИЙ КОДА

**ВСЕГДА:**
1. Прочитать код ПОЛНОСТЬЮ
2. Спросить разрешение
3. Получить явное "ДА"
4. Только тогда изменять

**ПРИНЦИП: РАБОТАЕТ - НЕ ТРОГАЙ!**

---

## 🏢 КОМАНДЫ

**BTI_API (сервер):**
- Не запускать локально!
- Изменения: commit → push → на сервере: git pull + restart

**ClaudeCodeLogger:**
```bash
cd /c/Users/Gajda/source/repos/ClaudeCodeLogger
dotnet build
```

**BTIdoc (документация):**
- Коммитить изменения после обновления

---

## 📍 КЛЮЧЕВЫЕ ПУТИ

**Данные izzML:**
- `C:\mega\izzMLmega\*.csv` - исходные данные
- Таймер BTI_API автозагружает через 5-10 сек

**Логи:**
- `C:\Data\BTI\*.txt` - резервные копии (НЕ читать!)
- БД logging.claude_messages - основной источник

**Проекты:**
- `C:\Users\Gajda\source\repos\BTI_API\` - сервер
- `C:\Users\Gajda\source\repos\ClaudeCodeLogger\` - логгер
- `C:\Users\Gajda\source\repos\BTIdoc\` - документация
