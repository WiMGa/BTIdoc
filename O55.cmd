@echo off
title CCL O55 (Opus 5.5)
if exist "%USERPROFILE%\deck-tube-tracker" (cd /d "%USERPROFILE%\deck-tube-tracker") else (cd /d "%USERPROFILE%\source\repos\BTIdoc")
set "CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000"
"%USERPROFILE%\.local\bin\claude.exe" --model "claude-opus-5-5" --effort high --append-system-prompt-file "%USERPROFILE%\source\repos\BTIdoc\O55.md" %*
