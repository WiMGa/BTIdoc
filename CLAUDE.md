# BTI Project - Claude Code Bootstrap

## ПРИ КАЖДОМ ЗАПУСКЕ

**1. Читай правила из БЗ:**
```bash
/c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.search_knowledge_brief(p_keywords := 'правила CCL', p_limit := 5, p_domain := 'SYSTEM')"
```

**2. Читай задания:**
```bash
/c/Mega/BTIcli/BTIcli.exe "SELECT * FROM log.get_tasks(p_for := 'CCL', p_status := 'new', p_limit := 10)"
```

**3. Сигнатуры процедур (если нужно):**
```bash
/c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.get_api_procedures()"
```

---

## ДОСТУП К БД

**BTIcli (основная БД):**
```bash
/c/Mega/BTIcli/BTIcli.exe "SQL запрос с именованными параметрами"
```

**pg18L (расчёты, порт 5432 — default):**

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

---

## ⚠️ КРИТИЧЕСКОЕ ПРАВИЛО: СНАЧАЛА БЗ!

**При недостатке информации — СНАЧАЛА поиск в БЗ, ПОТОМ вопрос пользователю.**

Если не знаешь:
- Откуда брать данные?
- Какая таблица/процедура?
- Какой порт/БД?
- Какие параметры?

**СНАЧАЛА ищи:**
```bash
/c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.search_knowledge_brief(p_keywords := 'ключевые слова', p_limit := 5, p_domain := 'BTI')"
```

**Мастер-документы:**
- #199 — BFSCF Protocol (данные, таблицы, SQL)
- #84 — Справочник API процедур
- #171 — llm.ask_api
- #108 — Архитектура портов PostgreSQL

**Порядок:** Сначала ищи в БЗ. Спрашивай пользователя только если не нашла.
