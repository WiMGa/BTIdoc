CREATE OR REPLACE FUNCTION log_message(
    p_working_directory VARCHAR,
    p_project_name VARCHAR,
    p_hwnd VARCHAR,
    p_message_type VARCHAR,
    p_content TEXT
) RETURNS INTEGER AS $$
DECLARE
    v_project_id INTEGER;
    v_session_id INTEGER;
    v_message_id INTEGER;
BEGIN
    -- 1. Найти или создать проект
    SELECT iProjectId INTO v_project_id
    FROM CC_Projects WHERE sWorkingDirectory = p_working_directory;

    IF NOT FOUND THEN
        INSERT INTO CC_Projects (sWorkingDirectory, sProject)
        VALUES (p_working_directory, p_project_name)
        RETURNING iProjectId INTO v_project_id;
    END IF;

    -- 2. Найти или создать сессию
    SELECT iSessionId INTO v_session_id
    FROM "CC_Sessions" WHERE iProjectId = v_project_id AND sMainHwnd = p_hwnd;

    IF NOT FOUND THEN
        INSERT INTO "CC_Sessions" (iProjectId, sMainHwnd)
        VALUES (v_project_id, p_hwnd)
        RETURNING iSessionId INTO v_session_id;
    END IF;

    -- 3. Добавить сообщение
    INSERT INTO "CC_Messages" (iSessionId, tmMessage, sType, sContent)
    VALUES (v_session_id, NOW(), p_message_type, p_content)
    RETURNING iMessageId INTO v_message_id;

    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql;