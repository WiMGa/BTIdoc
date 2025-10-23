# КАК ПРАВИЛЬНО ЗАВЕРШАТЬ ЗАДАНИЯ

## ОБЯЗАТЕЛЬНЫЙ ПРОТОКОЛ

Когда выполнила задание, использовать **manage_task** с action **complete**:

```bash
curl -s -X POST http://62.149.5.16:5080/mcp/tools/manage_task \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{
    "sAction": "complete",
    "iTaskId": 120,
    "sResult": "Detalnoe opisanie chto sdelano",
    "sCompletedBy": "CC"
  }'
```

## ВАЖНО

1. **sAction** = "complete" (НЕ "update"!)
2. **sResult** = подробное описание выполненной работы
3. **sCompletedBy** = "CC" (Claude Code)
4. Если русский текст превращается в кракозябры - использовать транслит

## НЕПРАВИЛЬНО

❌ UPDATE tasks.dev_tasks SET s_status = 'completed' - ЗАПРЕЩЕНО прямой SQL!
❌ sAction = "update" - это НЕ завершение, а обновление полей

## ПРАВИЛЬНО

✅ manage_task с sAction = "complete"
✅ sResult на транслите если проблемы с UTF-8
✅ После вызова проверить что задание получило tm_completed
