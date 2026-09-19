@echo off
title CCL F51 (Fable 5.1)
cd /d "C:\Users\Gajda\deck-tube-tracker"
set "CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000"
"C:\Users\Gajda\.local\bin\claude.exe" --model "claude-fable-5-1" --effort medium --append-system-prompt-file "C:\Users\Gajda\source\repos\BTIdoc\F51.md" %*
