# BTI Project - Claude Code Instructions

---

## 🚨 ПАМЯТКА ПРИ КАЖДОМ ЗАПУСКЕ

**ПРИ НОВОМ СЕАНСЕ РАБОТЫ:**

0. 📝 **ВСЕГДА ПЕРВЫМ ДЕЛОМ читать session_log.txt:**
   - Файл: `.claude/session_log.txt`
   - Содержит что делала в прошлой сессии
   - ОБЯЗАТЕЛЬНО читать при КАЖДОМ запуске!

1. 💾 **НОВАЯ БД - Минималистичный подход:**
   - ✅ Схема `log` с двумя таблицами: `t_memo`, `t_tasks`
   - ✅ Память: `log.find_memo('keyword')` - поиск важных фактов
   - ✅ Задания: `log.get_tasks('CC')` - проверка заданий
   - ❌ Полного логирования диалогов НЕТ (сохраняем только важное!)

2. 📋 **Проверить pending задания:**
   ```sql
   SELECT * FROM log.get_tasks('CC')
   ```

3. 🔍 **Поиск в памяти по якорям:**
   ```sql
   SELECT * FROM log.find_memo('indFindPattern')
   SELECT * FROM log.find_memo('database')
   ```

4. 🔄 **При "Восстанови контекст":**
   - Читать важные факты: `log.find_memo('')` (все)
   - Проверять задания: `log.get_tasks('CC')`
   - Сообщать статус

5. 💬 **Женский род, обращение "Вы"**

---

## 🔄 ВОССТАНОВЛЕНИЕ КОНТЕКСТА ПОСЛЕ ПЕРЕЗАПУСКА

**КОМАНДА:** "Восстанови контекст"

**ДЕЙСТВИЯ:**
1. Читай важные факты из памяти: `log.find_memo('')`
2. Проверяй pending задания: `log.get_tasks('CC')`
3. Сообщи статус готовности

**ПРИМЕЧАНИЕ:** Полного логирования диалогов больше нет. Используется `t_memo` для важных фактов.

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
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"query_database","arguments":{"sSqlQuery":"SELECT * FROM log.find_memo(\"\")"}}}'
```

**Упрощённый endpoint (только для query_database):**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM log.get_tasks(\"CC\")"}'
```

---

## ⚡ НОВАЯ БД - Доступные процедуры

### Схема `log` - Минималистичный подход

**Память (t_memo):**
```sql
-- Добавить важный факт
SELECT * FROM log.add_memo(
  'CC',  -- кто: CC/DO/User
  'indFindPattern replaces izzML',  -- краткое описание
  ARRAY['indFindPattern', 'pattern'],  -- якоря для поиска
  'Detailed description here'  -- подробное описание
);

-- Поиск по якорю
SELECT * FROM log.find_memo('indFindPattern');

-- Получить всё из памяти
SELECT * FROM log.find_memo('');
```

**Задания (t_tasks):**
```sql
-- Создать задание
SELECT * FROM log.create_task(
  'User',  -- от кого
  'CC',    -- кому
  'Task title',  -- заголовок
  'Detailed description'  -- описание
);

-- Получить задания для CC
SELECT * FROM log.get_tasks('CC');
```

**Философия:** Не логировать ВСЁ → сохранять только ВАЖНОЕ!

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

## 🔧 РАБОТА С ЗАДАНИЯМИ (НОВАЯ СИСТЕМА)

### Протокол выполнения:

**1. Проверить pending задания:**
```sql
SELECT * FROM log.get_tasks('CC')
-- Возвращает только статус 'new' для CC
```

**2. Выполнить согласно `s_description`**

**3. Обновить статус задания (ПРЯМОЙ UPDATE):**
```sql
UPDATE log.t_tasks
SET s_status = 'done',
    tm_completed = NOW(),
    s_result = 'Task completed successfully'
WHERE i_id = {task_id}
```

**ПРИМЕЧАНИЕ:**
- ✅ Новая система ПРОЩЕ - прямой UPDATE разрешён для log.t_tasks
- ❌ Старая система manage_task больше НЕ используется
- ✅ Минимум процедур, максимум простоты

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
