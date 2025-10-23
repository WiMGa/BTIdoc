-- Добавление начальных правил и паттернов ошибок в активную БЗ

-- WORKFLOW ПРАВИЛА - принудительные проверки перед действиями
INSERT INTO BTI_Workflow_Rules
(sActionType, sKeywordTriggers, sMandatoryCheck, sFailureAction, sErrorMessage, iPriority)
VALUES

-- КРИТИЧНОЕ ПРАВИЛО 1: Изменение кода
('EDIT_CODE',
 ARRAY['изменить','исправить','Edit','Write','MultiEdit','edit','write','добавить','обновить'],
 'SELECT COUNT(*) FROM BTI_Error_Patterns WHERE sErrorType=''unauthorized_changes'' AND bCritical=true',
 'BLOCK',
 '🚨 ОБЯЗАТЕЛЬНО: Прочтите код файла полностью, спросите разрешение пользователя ПЕРЕД изменением!',
 1),

-- КРИТИЧНОЕ ПРАВИЛО 2: Операции удаления в БД
('DATABASE_DELETE',
 ARRAY['DROP','DELETE','CASCADE','удали','удалить','drop','delete','пересоздай'],
 'SELECT COUNT(*) FROM BTI_Error_Patterns WHERE sErrorType=''cascade_deletion''',
 'BLOCK',
 '🚨 СТОП! Проверьте БЗ на случаи потери данных при DELETE/DROP операциях!',
 1),

-- ПРАВИЛО 3: Curl/API запросы
('CURL_REQUEST',
 ARRAY['curl','POST','API','запрос','api','mcp'],
 'SELECT COUNT(*) FROM BTI_Error_Patterns WHERE sErrorType=''curl_escaping''',
 'WARN',
 '⚠️ ВНИМАНИЕ: Проверьте экранирование JSON в curl! Используйте SQL файлы для длинных запросов.',
 2),

-- ПРАВИЛО 4: Повторение действий
('REPEAT_ACTION',
 ARRAY['снова','опять','ещё раз','повторить','again','повторно'],
 'SELECT MAX(iOccurrenceCount) FROM BTI_Error_Patterns',
 'WARN',
 '⚠️ ПРОВЕРКА: Убедитесь что не повторяете ошибку из debug лога!',
 2);

-- ПАТТЕРНЫ ОШИБОК - из анализа истории диалогов
INSERT INTO BTI_Error_Patterns
(sErrorType, sDescription, sPreventionQuery, iOccurrenceCount, bCritical)
VALUES

('curl_escaping',
 'Проблемы экранирования JSON в curl запросах - повторяющаяся ошибка несколько дней подряд',
 'SELECT * FROM BTI_Master_Tree WHERE sKeywords ILIKE ''%curl%'' OR sKeywords ILIKE ''%json%''',
 5, true),

('unauthorized_changes',
 'Изменение кода без чтения файла и получения разрешения от пользователя',
 'SELECT * FROM BTI_Master_Tree WHERE sSection=''RULES'' AND sKeywords ILIKE ''%разрешение%''',
 3, true),

('cascade_deletion',
 'Случайное удаление таблиц с CASCADE приводящее к потере всех данных',
 'SELECT * FROM BTI_Master_Tree WHERE sKeywords ILIKE ''%cascade%''',
 1, true),

('ignore_documentation',
 'Систематическое игнорирование собственной документации и debug логов',
 'SELECT * FROM BTI_Master_Tree WHERE sSection=''DEBUG'' ORDER BY sPriority DESC',
 7, true),

('architectural_violations',
 'Нарушение архитектурных решений - создание файлов вместо записи в БД',
 'SELECT * FROM BTI_Master_Tree WHERE sKeywords ILIKE ''%единый источник%''',
 4, true),

('lying_about_actions',
 'Ложь и сокрытие своих действий вместо честного признания ошибок',
 'SELECT * FROM BTI_Master_Tree WHERE sKeywords ILIKE ''%честность%''',
 2, true),

('repeat_same_errors',
 'Повторение одних и тех же ошибок в течение нескольких дней/сессий',
 'SELECT * FROM BTI_Error_Patterns ORDER BY iOccurrenceCount DESC',
 8, true);