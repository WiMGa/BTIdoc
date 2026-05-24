# BTI Project - Claude Code Bootstrap

> **Доступ к pg18S (БЗ, задачи, диалоги на VDS) — ТОЛЬКО через MCP-тулы коннектора `bti-api`.**
> Коннектор уже настроен (managed claude.ai connector → `http://62.149.5.16:5080/mcp/streamable`, UA `claude-ccl`).
> Тулы видны как `mcp__claude_ai_bti-api__*`; если deferred — подгрузить схему через ToolSearch (`select:<name>`).
>
> **BTIcli.exe ВЫВЕДЕН ИЗ ЭКСПЛУАТАЦИИ (#1946).** Бил на `/mcp/tools/query_database` — endpoint снесён 24.05 (#1938, push 1ba7905), отдаёт 404. НЕ использовать, в шаблонах ниже его нет.

## ПРИ КАЖДОМ ЗАПУСКЕ

**1. Читай правила из БЗ** — MCP-тул `search_forms_semantic`:
- `p_query='правила CCL'`, `p_context='SYSTEM'`, `p_limit=5`
- точный поиск по токену/UUID или fallback — `search_forms`

**2. Читай задания** — MCP-тул `get_tasks`:
- `p_for='CCL'`, `p_status='new'`, `p_limit=10`
- дерево конкретной задачи — `log_get_task_tree`

**3. Сырое SQL к pg18S / сигнатуры процедур (`core.get_api_procedures`):**
у CCL прямого `query_database` НЕТ — это привилегированный канал `/mcp/admin` (зона DC). Нужно сырое SQL к pg18S — через DC.

---

## ДОСТУП К ДАННЫМ

### pg18S (БЗ / задачи / диалоги — VDS) — через MCP-тулы `bti-api`

| Назначение | MCP-тул |
|---|---|
| БЗ по смыслу (вектор e5 + trgm + RRF) | `search_forms_semantic` (`p_query` текстом, вектор считает сервер) |
| БЗ точный токен / fallback | `search_forms` |
| Читать форму по UUID | `get_form` (`p_form_id`) |
| Читать сущность | `get_entity` |
| Задачи: читать / создать-обновить / закрыть / дерево | `get_tasks` / `create_update_task` / `complete_task` / `log_get_task_tree` |
| Диалоги по смыслу / история | `search_dialog_semantic` / `get_dialog_history` |
| Записать сообщение в лог | `add_dialog_message` |
| Планы LMN | `get_lmn_plan_tree`, `get_lmn_node`, `get_lmn_subtree`, `get_lmn_open_items` |
| Тропы (procedural knowledge) | `tropa_search_candidates`, `tropa_get_candidate`, `tropa_add_candidate`, `tropa_add_execution`, `tropa_update_candidate` |

Интерфейс единый: для semantic-тулов агент шлёт только `p_query` ТЕКСТОМ — эмбеддинг и подстановку вектора делает обёртка на сервере.

### pg18L (расчёты, порт 5432 — default) — НЕ через MCP, прямой psql/psycopg2

*Вариант 1: Python + psycopg2 (РЕКОМЕНДУЕТСЯ)*
```python
python -c "import psycopg2; conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres'); cur = conn.cursor(); cur.execute('SELECT count(*) FROM bti_work.t_zz'); print(cur.fetchone()[0]); conn.close()"
```

*Вариант 2: psql (Bash/Git Bash)*
```bash
PGPASSWORD=postgres /c/"Program Files"/PostgreSQL/18/bin/psql.exe -h 127.0.0.1 -p 5432 -U postgres -d bti -t -c "SQL"
```

*Вариант 3: psql (PowerShell)*
```powershell
$env:PGPASSWORD='postgres'; & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d bti -t -c "SQL"
```

---

## БАЗОВЫЕ ПРАВИЛА

- Женский род, обращение "Вы"
- Не использовать var
- Именованные параметры: p_name := value
- Всё остальное — в БЗ (domain=SYSTEM)

## ШАБЛОНЫ ЧАСТЫХ ОПЕРАЦИЙ

**Закрыть задачу** — MCP-тул `complete_task` (3 параметра ОБЯЗАТЕЛЬНЫ!):
`p_task_id`, `p_status` (`completed`/`failed`/`cancelled`/`deferred`), `p_result`.

---

## ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО: СНАЧАЛА БЗ!

**При недостатке информации — СНАЧАЛА поиск в БЗ, ПОТОМ вопрос пользователю.**

Если не знаешь:
- Откуда брать данные?
- Какая таблица/процедура?
- Какой порт/БД?
- Какие параметры?

**СНАЧАЛА ищи** — MCP-тул `search_forms_semantic` (`p_query='ключевые слова'`, `p_context=NULL`, `p_limit=5`).

**Мастер-документы:**
- #199 — BFSCF Protocol (данные, таблицы, SQL)
- #84 — Справочник API процедур
- #171 — llm.ask_api
- #108 — Архитектура портов PostgreSQL

**Порядок:** Сначала ищи в БЗ. Спрашивай пользователя только если не нашла.
