-- Создание таблиц для логирования Claude Code диалогов
-- Выполнить когда BTI_API будет доступен

-- Таблица сеансов диалогов
CREATE TABLE CC_Sessions (
    iSessionId SERIAL PRIMARY KEY,
    tmStart TIMESTAMP DEFAULT NOW(),
    tmEnd TIMESTAMP,
    sProject VARCHAR(100),
    sWorkingDirectory VARCHAR(500),
    sMainHwnd VARCHAR(20),
    sTopic VARCHAR(200)
);

-- Таблица сообщений в диалогах
CREATE TABLE CC_Messages (
    iMessageId SERIAL PRIMARY KEY,
    iSessionId INTEGER REFERENCES CC_Sessions(iSessionId),
    tmMessage TIMESTAMP DEFAULT NOW(),
    sType VARCHAR(20), -- 'user', 'assistant'
    sContent TEXT,
    sHwnd VARCHAR(20),
    sCurrentDirectory VARCHAR(500),
    sFiles TEXT -- JSON массив файлов
);

-- Таблица решений и подходов
CREATE TABLE CC_Decisions (
    iDecisionId SERIAL PRIMARY KEY,
    iSessionId INTEGER REFERENCES CC_Sessions(iSessionId),
    tmDecision TIMESTAMP DEFAULT NOW(),
    sProblem TEXT,
    sSolution TEXT,
    sApproach VARCHAR(100),
    bSuccessful BOOLEAN
);

-- Индексы для быстрого поиска
CREATE INDEX idx_cc_sessions_project ON CC_Sessions(sProject);
CREATE INDEX idx_cc_sessions_tmstart ON CC_Sessions(tmStart);
CREATE INDEX idx_cc_messages_session ON CC_Messages(iSessionId);
CREATE INDEX idx_cc_messages_tmessage ON CC_Messages(tmMessage);
CREATE INDEX idx_cc_messages_type ON CC_Messages(sType);
CREATE INDEX idx_cc_decisions_session ON CC_Decisions(iSessionId);

-- Первая тестовая сессия
INSERT INTO CC_Sessions (sProject, sWorkingDirectory, sMainHwnd, sTopic)
VALUES ('BTIdoc', 'C:\Users\Gajda\source\repos\BTIdoc', 'CURRENT', 'CCL logging setup');