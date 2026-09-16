@echo off
title CCL O5 (Opus 5)
cd /d "C:\Users\Gajda\deck-tube-tracker"
set "CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000"
"C:\Users\Gajda\.local\bin\claude.exe" --model "claude-opus-5" --append-system-prompt-file "C:\Users\Gajda\source\repos\BTIdoc\O5.md" %*
