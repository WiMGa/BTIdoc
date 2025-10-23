-- Добавление описаний всех таблиц mess-log системы в БЗ

INSERT INTO "BTI_Master_Tree"
("sSection", "sTaskType", "sTitle", "sContent", "sKeywords", "sPriority")
VALUES

-- Описание CC_Projects
('DATABASE_SCHEMA', 'TABLE', 'CC_Projects - проекты Claude Code',
'Таблица проектов для mess-log системы.
Столбцы: iProjectId (PK), sWorkingDirectory, sProject.
Связи: один ко многим с CC_Sessions.
Назначение: группировка сессий по проектам (BTIdoc, BTIman, BTI_API).',
'cc_projects,проекты,mess-log,schema', 'HIGH'),

-- Описание CC_Sessions
('DATABASE_SCHEMA', 'TABLE', 'CC_Sessions - сессии диалогов',
'Таблица сессий диалогов Claude Code.
Столбцы: iSessionId (PK), iProjectId (FK), sMainHwnd.
Связи: многие к одному с CC_Projects, один ко многим с CC_Messages.
Назначение: группировка сообщений по сессиям работы.',
'cc_sessions,сессии,диалоги,mess-log', 'HIGH'),

-- Описание CC_Messages
('DATABASE_SCHEMA', 'TABLE', 'CC_Messages - сообщения диалогов',
'Таблица сообщений диалогов Claude Code.
Столбцы: iMessageId (PK), iSessionId (FK), tmMessage, sType (user/assistant), sContent.
Связи: многие к одному с CC_Sessions.
Назначение: полное логирование всех сообщений ИИ и пользователя.',
'cc_messages,сообщения,диалоги,mess-log', 'HIGH'),

-- Описание CC_Stage_Logs
('DATABASE_SCHEMA', 'TABLE', 'CC_Stage_Logs - этапы работы',
'Таблица этапов работы в сессиях.
Столбцы: iStageId (PK), iSessionId (FK), tmStageStart, tmStageEnd, sStageName, sObjectives, sAchievements, sProblems, sLessonsLearned, iMessagesCount, iErrorsCount, sNextSteps.
Связи: многие к одному с CC_Sessions.
Назначение: структурированная память ИИ о выполненных этапах.',
'cc_stage_logs,этапы,память,анализ', 'HIGH'),

-- Описание BTI_Master_Tree
('DATABASE_SCHEMA', 'TABLE', 'BTI_Master_Tree - база знаний',
'Главная таблица базы знаний системы.
Столбцы: sSection, sTaskType, sTitle, sContent, sKeywords, sPriority.
Назначение: единый источник правды для всех знаний, правил, SQL шаблонов.',
'bti_master_tree,база знаний,бз,knowledge', 'HIGH'),

-- Описание BTI_Error_Patterns
('DATABASE_SCHEMA', 'TABLE', 'BTI_Error_Patterns - паттерны ошибок',
'Таблица для отслеживания повторяющихся ошибок ИИ.
Столбцы: iPatternId (PK), sErrorType, sDescription, iOccurrenceCount, bCritical, tmLastOccurrence.
Назначение: предотвращение циклов ошибок через анализ паттернов.',
'bti_error_patterns,ошибки,паттерны,обучение', 'HIGH'),

-- Описание BTI_Workflow_Rules
('DATABASE_SCHEMA', 'TABLE', 'BTI_Workflow_Rules - правила workflow',
'Таблица правил принудительных проверок.
Столбцы: iRuleId (PK), sActionType, sKeywordTriggers, sMandatoryCheck, sFailureAction.
Назначение: активная БЗ с автоматическими проверками перед действиями.',
'bti_workflow_rules,правила,проверки,workflow', 'HIGH'),

-- Описание BTI_Evolution_Log
('DATABASE_SCHEMA', 'TABLE', 'BTI_Evolution_Log - лог эволюции системы',
'Таблица логирования ключевых событий развития системы.
Столбцы: id (PK), tmEvent, sEvent, sDescription.
Назначение: история развития и изменений всей BTI системы.',
'bti_evolution_log,эволюция,история,события', 'HIGH');