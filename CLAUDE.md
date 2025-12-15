# BTI Project - Claude Code Instructions

## ПРИ КАЖДОМ ЗАПУСКЕ

1. **Читай БЗ:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.search_knowledge(p_keywords := 'правила', p_limit := 5, p_domain := 'SYSTEM')"
   ```

2. **Читай непрочитанные диалоги DC:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM log.get_unread_dialogs(p_reader := 'CCL', p_who := 'DC', p_limit := 20)"
   ```

3. **Читай задания:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM log.get_tasks(p_for := 'CCL', p_status := 'new', p_limit := 10)"
   ```

4. **Все доступные процедуры:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.get_api_procedures()"
   ```

---

## ДОСТУП К БД

**ЕДИНСТВЕННЫЙ СПОСОБ — через BTIcli.exe:**
```bash
/c/Mega/BTIcli/BTIcli.exe "SQL запрос с именованными параметрами"
```

**ЗАПРЕЩЕНО:** curl, Invoke-RestMethod, любые другие способы.

---

## ДОСТУП К pg18L (порт 5440)

**Для запросов к BTI расчётам (pg18L):**
```bash
PGPASSWORD=postgres /c/"Program Files"/PostgreSQL/18/bin/psql.exe -h 127.0.0.1 -p 5440 -U postgres -d bti -t -c "SQL запрос"
```

**ВАЖНО:**
- Переменная PGPASSWORD=postgres ОБЯЗАТЕЛЬНА в начале команды
- Использовать git bash синтаксис путей (/c/"Program Files"/...)
- Хост: 127.0.0.1 (не localhost — избежать IPv6)
- Порт: 5440
- БД: bti
- Пользователь: postgres

---

## АГЕНТЫ

- **CCL** - Claude Code Local (этот агент)
- **DC** - Desktop Claude
- **DO** - Desktop OpenAI
- **GL** - Gemini Local

---

## КРИТИЧНО

- Женский род, обращение "Вы"
- Не использовать var
- Не изменять код без чтения и разрешения
- Все процедуры требуют ИМЕНОВАННЫЕ параметры (p_name := value)
