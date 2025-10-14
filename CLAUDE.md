# BTIman Project Context

## 🔄 ВОССТАНОВЛЕНИЕ КОНТЕКСТА ПОСЛЕ ПЕРЕЗАПУСКА

**КОМАНДА ДЛЯ ПОЛЬЗОВАТЕЛЯ:** "Восстанови контекст"

**ЧТО ДЕЛАЕТ CLAUDE CODE:**

### 1. Читает последние сообщения диалога
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM logging.get_recent_messages(30)"}'
```

### 2. Проверяет pending задания
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM tasks.get_pending_tasks()"}'
```

### 3. Сообщает статус
- Что было сделано в предыдущей сессии
- Какие задания pending
- Готовность к работе

---

## 📊 СИСТЕМА BTI (Back Test Intelligence)

Распределённая система машинного обучения для торгового прогнозирования на основе k-NN алгоритма с оптимизацией параметров TP/SL.

### Архитектура

**BTIman** (Task Manager) - текущий проект
- `frmMan.cs` - главная форма менеджера задач
- `Timer.cs` - метод `FinalizeTasks()` (критически важный)
- `CHttpApi.cs` - HTTP API клиент для BTI_API
- `CTask.cs`, `CVector.cs`, `CParams.cs` - основные классы

**BTIwork** - воркер-процесс (`C:\Users\Gajda\source\repos\BTIwork\`)

**indFindPattern** - индикатор cTrader (`C:\Users\Gajda\OneDrive\Documents\cAlgo\Sources\Indicators\indFindPattern\`)

### Доступ к БД

**Серверная PostgreSQL** (по умолчанию): `http://62.149.5.16:5080`

```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json" \
  -d '{"sSqlQuery": "ваш SQL запрос"}'
```

### Файлы данных
- **Входные**: `c:\mega\DBM\vectors_bti.json`
- **Результаты**: `c:\mega\DBM\task_results\eSh*.json`
- **Настройки**: `c:\mega\DBM\bti_man_settings.json`

---

## 📝 ПРАВИЛА КОДИРОВАНИЯ (UAnotat)

### Префиксы типов (ОБЯЗАТЕЛЬНО)
- `i*` - int: `iCount`, `iShNo`, `iTPSL`
- `d*` - double: `dPrice`, `dProfit`, `dProfitDDRatio`
- `s*` - string: `sTaskId`, `sFile`, `sJson`
- `b*` - bool: `bIniciator`
- `tm*` - DateTime: `tmCreated`, `tmLast`
- `ad*` - double[]: `adGridUpDownPips`, `adAxis`
- `ai*` - int[]: `aiWindows`, `aiKVariants`
- `l*` - List: `lVectors`, `lTasks`
- `dc*` - Dictionary: `dcBestResults`
- `e*` - объекты: `eTask`, `eVector`, `eBestResult`

### ЗАПРЕЩЕНО
- `var` - только явное указание типов
- Избыточные null-проверки
- Маскировка ошибок (`if (obj == null) return;`)

### ОБЯЗАТЕЛЬНО
- Честный крах программы при ошибках
- Явность лучше неявности
- Код читается как документация

---

## 💬 ПРАВИЛА ДИАЛОГА

- ✅ Женский род в ответах
- ✅ Обращение на "Вы"
- ✅ Профессиональный тон
- ✅ Четкие однозначные ответы
- ✅ Анализ всех граничных случаев
- ✅ Признание ошибок

---

## 🔧 РАБОТА С ЗАДАНИЯМИ

### Протокол выполнения задания

**1. Получить pending задания**
```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/query_database \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"sSqlQuery": "SELECT * FROM tasks.get_pending_tasks()"}'
```

**2. Прочитать ТОЛЬКО пропущенный диалог**
```sql
SELECT * FROM logging.get_messages_after(i_last_message_cc)
```
Где `i_last_message_cc` - номер последнего прочитанного сообщения из задания.

**Экономия токенов:** читаем не все 100 сообщений, а только новые с момента последнего чтения!

**3. Выполнить задание** согласно `s_description`

**4. ЗАВЕРШИТЬ ЗАДАНИЕ ПРАВИЛЬНО - manage_task complete**

⚠️ **КРИТИЧЕСКИ ВАЖНО!** ⚠️

**ИСПОЛЬЗОВАТЬ ТОЛЬКО manage_task с sAction = "complete":**

```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/manage_task \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{
    "sAction": "complete",
    "iTaskId": 120,
    "sResult": "Podrobnoe opisanie vypolnennoi raboty (translit esli problemy s UTF-8)",
    "sCompletedBy": "CC"
  }'
```

**ЗАПРЕЩЕНО:**
- ❌ Прямой UPDATE tasks.dev_tasks SET s_status = 'completed' - НИКОГДА!
- ❌ manage_task с sAction = "update" - это НЕ завершение задания!
- ❌ Русский текст если получаются кракозябры - использовать транслит!

**ПРАВИЛЬНО:**
- ✅ manage_task с sAction = "complete"
- ✅ sResult = детальное описание выполненной работы
- ✅ sCompletedBy = "CC"
- ✅ Транслит если проблемы с кодировкой UTF-8

**Поля синхронизации:**
- `i_last_message_cc` - что прочитал Claude Code
- `i_last_message_dc` - что прочитал Desktop Claude

**Каждый пишет в своё поле - нет конфликтов!**

---

## ⚠️ ПРОТОКОЛ ИЗМЕНЕНИЙ КОДА

**ПЕРЕД ЛЮБЫМ ИЗМЕНЕНИЕМ:**
1. Прочитать существующий код ПОЛНОСТЬЮ
2. Спросить разрешение пользователя
3. Получить явное "ДА"
4. Только тогда изменять

**ПРИНЦИП: РАБОТАЕТ - НЕ ТРОГАЙ!**

---

## 🛠️ КОМАНДЫ СБОРКИ

```bash
dotnet build
```
