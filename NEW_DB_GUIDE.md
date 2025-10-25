# Новая БД - Минималистичный подход

## Философия

**Было:** Сложная структура с 4+ схемами (tree, logging, tasks, knowledge, izzml)
**Стало:** Одна схема `log` с двумя таблицами (t_memo, t_tasks)

**Принцип:** Не логировать ВСЁ → сохранять только ВАЖНОЕ

---

## Схема `log`

### Таблица `t_memo` - Память системы

**Структура:**
```sql
CREATE TABLE log.t_memo (
    i_id INTEGER PRIMARY KEY,
    tm_created TIMESTAMP DEFAULT NOW(),
    s_who TEXT NOT NULL,           -- Кто создал: 'CC', 'DO', 'User'
    s_what TEXT NOT NULL,           -- Краткое описание (заголовок)
    as_anchors TEXT[] NOT NULL,     -- Якоря для поиска
    s_description TEXT NOT NULL     -- Подробное описание
);
```

**Процедуры:**

#### 1. Добавление в память
```sql
SELECT * FROM log.add_memo(
    p_who := 'CC',
    p_what := 'indFindPattern replaces izzML',
    p_anchors := ARRAY['indFindPattern', 'pattern', 'analysis'],
    p_description := 'New indicator indFindPattern is used instead of izzML'
);
-- Возвращает: i_id новой записи
```

#### 2. Поиск по якорю
```sql
SELECT * FROM log.find_memo('pattern');
-- Возвращает: i_id, s_what, s_description
```

**Через curl:**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM log.add_memo(\"CC\", \"Important fact\", ARRAY[\"keyword1\", \"keyword2\"], \"Full description here\")"}'
```

---

### Таблица `t_tasks` - Задания

**Структура:**
```sql
CREATE TABLE log.t_tasks (
    i_id INTEGER PRIMARY KEY,
    tm_created TIMESTAMP DEFAULT NOW(),
    s_from TEXT NOT NULL,           -- От кого: 'CC', 'DO', 'User'
    s_to TEXT NOT NULL,             -- Кому: 'CC', 'DO', 'User'
    s_title TEXT NOT NULL,          -- Заголовок
    s_description TEXT NOT NULL,    -- Описание что делать
    s_status TEXT DEFAULT 'new',    -- Статус: 'new', 'done'
    tm_completed TIMESTAMP,         -- Когда завершено
    s_result TEXT                   -- Результат выполнения
);
```

**Процедуры:**

#### 1. Создание задания
```sql
SELECT * FROM log.create_task(
    p_from := 'User',
    p_to := 'CC',
    p_title := 'Analyze EURUSD patterns',
    p_description := 'Find all patterns with success > 70% on Range1'
);
-- Возвращает: i_id нового задания
```

#### 2. Получение заданий
```sql
SELECT * FROM log.get_tasks('CC');
-- Возвращает только задания со статусом 'new' для указанного получателя
```

---

## Примеры использования

### Сценарий 1: Сохранить важный факт

**Ситуация:** Вы сказали мне важную информацию про indFindPattern

**Я делаю:**
```sql
SELECT * FROM log.add_memo(
    'CC',
    'indFindPattern replaces izzML',
    ARRAY['indFindPattern', 'pattern', 'indicator'],
    'User switched from izzML to indFindPattern for pattern analysis. IndFindPattern provides better detection.'
);
```

**Потом найду:** `SELECT * FROM log.find_memo('indFindPattern')`

---

### Сценарий 2: Создать задание

**Ситуация:** Вы хотите чтобы я что-то сделал позже

**Вы говорите:** "Создай задание: проанализировать паттерны EURUSD"

**Я делаю:**
```sql
SELECT * FROM log.create_task(
    'User',
    'CC',
    'Analyze EURUSD patterns',
    'Find patterns on Range1 with Δ=1.5, filter by success > 70%, group by sector'
);
```

**Потом я проверю:** `SELECT * FROM log.get_tasks('CC')`

---

### Сценарий 3: Восстановление контекста

**Ситуация:** Новый сеанс, нужно вспомнить что важно

**Я делаю:**
```sql
-- Ищу по ключевым словам
SELECT * FROM log.find_memo('database');
SELECT * FROM log.find_memo('indFindPattern');

-- Проверяю задания
SELECT * FROM log.get_tasks('CC');
```

---

## Whitelist процедур в BTI_API

**Разрешённые процедуры:**
```csharp
// log schema (NEW - active)
"log.add_memo", "log.find_memo",
"log.create_task", "log.get_tasks"

// legacy schemas (kept for reference)
"tree.*", "logging.*", "tasks.*", "knowledge.*"
```

**Блокируется:** Прямые SELECT/INSERT/UPDATE/DELETE

**Разрешается:** ТОЛЬКО вызовы процедур из whitelist

---

## Миграция со старой БД

**Не восстанавливаем:**
- ❌ Полные диалоги (logging.claude_messages)
- ❌ Дерево знаний (tree.*)
- ❌ Данные izzML (izzml.bars, izzml.zigzag)

**Сохраняем:**
- ✅ Важные факты → `log.add_memo()`
- ✅ Задания → `log.create_task()`

**Философия:** Вместо восстановления терабайтов старых данных → начинаем чисто, сохраняем только новое ВАЖНОЕ.

---

## Преимущества нового подхода

1. **Простота:** 1 схема, 2 таблицы, 4 процедуры
2. **Скорость:** Нет лишних данных → быстрый поиск
3. **Ясность:** Только важное → нет мусора
4. **Надёжность:** Меньше кода → меньше ошибок

---

## Что дальше?

**Этап 2 (если понадобится):**
- Упрощённое логирование диалогов (экстракты, не весь текст)
- Процедура `log.add_dialog_extract()`
- Таблица `log.t_extracts` с краткими выжимками

**НО:** Пока не делаем! Работаем с минимумом. Добавим когда реально понадобится.

---

## Статус

- ✅ Схема `log` создана
- ✅ Таблицы `t_memo`, `t_tasks` созданы
- ✅ Процедуры работают
- ✅ BTI_API whitelist обновлён
- ✅ Commit 4a54c99 отправлен на GitHub
- ✅ MCP на сервере обновлён
- ✅ Протестировано

**Дата:** 2025-10-25

---

## Контакты

**Сервер:** http://62.149.5.16:5080
**GitHub:** https://github.com/WiMGa/BTI_API
**Документация:** BTIdoc/NEW_DB_GUIDE.md
