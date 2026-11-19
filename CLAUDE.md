# BTI Project — Claude Code Bootstrap (минимум, чтобы дойти до БЗ)

Протокол CCL живёт ОДНИМ экземпляром в форме БЗ «правила CCL» (SYSTEM): таблица MCP-тулов, доступ к pg18L,
рабочие корни диска, порядок работы. Сюда его не копировать — две копии = одна протухает молча (#2568).

## Канал к pg18S (БЗ, задачи, диалоги)
Собственный MCP-сервер CCL `bti` (user scope в `~/.claude.json`, HTTP → `https://btiapi.net/mcp/streamable`,
заголовки `Authorization` из `C:\Data\aion_mcp.json`, `X-Agent-Code: CCL`, `X-Agent-Host: <машина>`) — агента сервер
определяет сам, `p_who` не обязателен. Тулы видны как `mcp__bti__*`; если deferred — подгрузить схему через ToolSearch (`select:<имя>`).
Коннекторы аккаунта claude.ai — канал DC: в Claude Code выключены (`ENABLE_CLAUDEAI_MCP_SERVERS=false` в env
`~/.claude/settings.json`, страховка — deny `mcp__claude_ai_bti-api`). Включать их CCL нельзя (#3464).
Подключение на новой машине: `claude mcp add --scope user --transport http bti https://btiapi.net/mcp/streamable`
`--header "Authorization: Bearer <token>" --header "X-Agent-Code: CCL" --header "X-Agent-Host: <машина>"`.
Сырого SQL к pg18S у CCL нет — зона DC. Задачи создавать и закрывать только guarded-тулами
(`create_update_task_guarded` / `complete_task_guarded`, тропа обязательна).

## При старте
1. Правила — `search_forms_semantic` (`p_query='правила CCL'`, `p_context='SYSTEM'`, `p_limit=5`).
2. Задания — `get_tasks` (`p_for='CCL'`, `p_status='new'`, `p_limit=10`). Доложить список и ждать команды «делай / выполни N».

## Базовые правила
- Обращение на «Вы» (пользователь — мужской род); CCL о себе — женский род. Не обращаться по имени.
- UAnotation: `var` запрещён, префиксы типов обязательны. Именованные параметры: `p_name := value`.
- При недостатке информации — сначала поиск в БЗ (`search_forms_semantic`, `p_context=NULL`), потом вопрос.

> Модельные поправки — `O55.md` (основное окно) и `F51.md` (эскалация) в этом репозитории, подключаются ярлыками
> `.claude\O55.cmd` / `F51.cmd` ключом `--append-system-prompt-file`. Здесь не дублировать.
