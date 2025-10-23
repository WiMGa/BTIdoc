-- Создание таблицы CC_Stage_Logs для логирования этапов работы

CREATE TABLE "CC_Stage_Logs" (
    "iStageId" SERIAL PRIMARY KEY,
    "iSessionId" INTEGER REFERENCES "CC_Sessions"("iSessionId"),
    "tmStageStart" TIMESTAMP,
    "tmStageEnd" TIMESTAMP DEFAULT NOW(),
    "sStageName" VARCHAR(100),
    "sObjectives" TEXT,
    "sAchievements" TEXT,
    "sProblems" TEXT,
    "sLessonsLearned" TEXT,
    "iMessagesCount" INTEGER,
    "iErrorsCount" INTEGER,
    "sNextSteps" TEXT
);

-- Индекс для быстрого поиска по сессиям
CREATE INDEX idx_stage_logs_session ON "CC_Stage_Logs"("iSessionId", "tmStageEnd" DESC);