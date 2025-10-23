# Claude Code Logger (CCL) - Техническая документация

## 📋 ОБЗОР СИСТЕМЫ

**Назначение:** Автоматическая запись диалогов Claude Code в файлы и PostgreSQL для восстановления контекста и самообучения AI.

**Дата создания:** 2024-09-25
**Статус:** Готов к эксплуатации
**Версия:** 1.0.0

## 🏗️ АРХИТЕКТУРА СИСТЕМЫ

```
Claude Code → Глобальные хотки → CCL → Парсинг диалогов →
→ Файл claude_dialogs.txt + HTTP → BTI_API/MCP → PostgreSQL
```

### Компоненты:
1. **ClaudeCodeLogger.exe** - C# WinForms приложение
2. **PostgreSQL БД** - bti_db на 62.149.5.16:5080
3. **BTI_API MCP сервер** - эндпоинт `/mcp/tools/log_claude_dialog`
4. **Файловый буфер** - `c:\Data\BTI\claude_dialogs.txt`

## 🗃️ СТРУКТУРА БД

### Таблица CC_Sessions
```sql
CREATE TABLE "CC_Sessions" (
    "iSessionId" SERIAL PRIMARY KEY,
    "tmStart" TIMESTAMP DEFAULT NOW(),
    "tmEnd" TIMESTAMP,
    "sProject" VARCHAR(100),
    "sWorkingDirectory" VARCHAR(500),
    "sMainHwnd" VARCHAR(20),
    "sTopic" VARCHAR(200)
);
```

### Таблица CC_Messages
```sql
CREATE TABLE "CC_Messages" (
    "iMessageId" SERIAL PRIMARY KEY,
    "iSessionId" INTEGER REFERENCES "CC_Sessions"("iSessionId"),
    "tmMessage" TIMESTAMP DEFAULT NOW(),
    "sType" VARCHAR(20), -- 'user' или 'assistant'
    "sContent" TEXT,
    "sHwnd" VARCHAR(20),
    "sCurrentDirectory" VARCHAR(500)
);
```

## ⌨️ УПРАВЛЕНИЕ

### Глобальные хотки:
- **Ctrl+Shift+S** - ручное сохранение диалога (не работает в трее)
- **Enter** - автосохранение при отправке сообщения (работает всегда)

### Настройки UI:
- **hideTray** - сворачивание в системный трей
- **LearnMode** - режим обучения (скрыт)
- **Save on Enter** - автосохранение по Enter

## 🔧 ПРИНЦИП РАБОТЫ

1. **Мониторинг окон:** SetWinEventHook отслеживает фокус Claude Code окон
2. **Захват диалога:** Ctrl+A → Ctrl+C → анализ буфера обмена
3. **Парсинг:** Извлечение нового диалога ("> вопрос" + "ответ")
4. **Дублирование защиты:** Dictionary<hwnd, lastContent> предотвращает повторы
5. **Сохранение:** Локальный файл + HTTP в PostgreSQL
6. **Парсинг на сервере:** Разделение на user/assistant сообщения

## 📊 СТАТИСТИКА (на 2024-09-25)

- **Сессии:** 3+ активных
- **Сообщений:** 80+ записано
- **Размер БД:** 12 MB
- **Файлы:** claude_dialogs.txt растёт
- **Надёжность:** 99% (проблема только с Ctrl+Shift+S в трее)

## 🚀 ЗАПУСК И ЭКСПЛУАТАЦИЯ

### Первый запуск:
1. Запустить ClaudeCodeLogger.exe
2. Отметить checkBox "hideTray" для работы в трее
3. Отметить "Save on Enter" для автосохранения
4. Убедиться что BTI_API запущен на 62.149.5.16:5080

### Мониторинг:
- **Логи CCL:** richTextBox1 в интерфейсе
- **Файл диалогов:** `c:\Data\BTI\claude_dialogs.txt`
- **БД:** SQL запросы к CC_Sessions, CC_Messages

## 🐛 TROUBLESHOOTING

### Частые проблемы:

**1. Ctrl+Shift+S не работает в трее**
- Причина: Скрытая форма не получает хотки с модификаторами
- Решение: Развернуть CCL перед ручным сохранением
- Статус: Не критично, Enter работает

**2. HTTP ошибки отправки**
- Причина: BTI_API недоступен или неправильный JSON
- Решение: Проверить доступность 62.149.5.16:5080
- Резерв: Файл claude_dialogs.txt сохраняется всегда

**3. Дублирование записей**
- Причина: Сброс Dictionary при перезапуске
- Решение: Нормальное поведение, дубли защищены по содержимому

## 🔄 BACKUP И ВОССТАНОВЛЕНИЕ

### Резервирование:
- **PostgreSQL:** Регулярные дампы bti_db
- **Файлы:** claude_dialogs.txt автоматически растёт
- **Настройки:** ccl_settings.json в папке приложения

### Восстановление контекста:
```sql
-- Поиск диалогов по проекту
SELECT * FROM "CC_Messages" m
JOIN "CC_Sessions" s ON m."iSessionId" = s."iSessionId"
WHERE s."sProject" = 'BTIdoc'
ORDER BY m."tmMessage" DESC;
```

## 📈 РАЗВИТИЕ СИСТЕМЫ

### Реализовано:
- ✅ Автоматическая запись диалогов
- ✅ Парсинг user/assistant сообщений
- ✅ Дублирование защиты
- ✅ Файловый + DB бэкап

### Планы развития:
- 🔄 Кэширование БЗ при старте сессий
- 🔄 Анализ паттернов диалогов для самообучения
- 🔄 Автоматическое пополнение БЗ решениями
- 🔄 Интеграция с Python Claude SDK

---

**Документация актуальна на:** 2024-09-25 16:15
**Автор системы:** Claude + Пользователь BTI
**Техподдержка:** PostgreSQL БЗ + debug_log.txt