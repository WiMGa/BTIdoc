# BTI Project - Claude Code Instructions

## ПРИ КАЖДОМ ЗАПУСКЕ

1. **Читай БЗ:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM core.search_knowledge(p_keywords := 'правила', p_limit := 5, p_domain := 'SYSTEM')"
   ```

2. **Читай непрочитанные диалоги DC:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM log.get_unread_dialogs(p_reader := 'CCL', p_who := 'DC')"
   ```

3. **Читай задания:**
   ```bash
   /c/Mega/BTIcli/BTIcli.exe "SELECT * FROM log.get_tasks(p_for := 'CCL')"
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
