#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Миграция диалогов из claude_dialogs.txt в PostgreSQL mess-log БД
"""
import sys
import os
import requests
import re
from datetime import datetime
import json

# Настройка кодировки для вывода
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach())

def parse_claude_dialogs(file_path):
    """Парсинг файла claude_dialogs.txt на сессии"""
    with open(file_path, 'r', encoding='utf-8-sig') as f:
        content = f.read()

    # Разбиваем на сессии по разделителю
    sessions = re.split(r'=== SESSION.*?===', content)[1:]  # Убираем первый пустой
    headers = re.findall(r'=== SESSION (.*?) ===', content)

    parsed_sessions = []

    for i, session_content in enumerate(sessions):
        if i >= len(headers):
            continue

        session_time = headers[i]

        # Извлекаем HWND и WINDOW
        hwnd_match = re.search(r'HWND: (\w+)', session_content)
        window_match = re.search(r'WINDOW: (.+)', session_content)

        hwnd = hwnd_match.group(1) if hwnd_match else "UNKNOWN"
        # Убираем эмодзи из заголовка окна: "✳ Code Modification" -> "Code Modification"
        window_raw = window_match.group(1) if window_match else "Unknown Window"
        window_title = re.sub(r'^✳\s*', '', window_raw).strip()

        # Определяем проект из window_title или содержимого
        project = extract_project_name(window_title, session_content)
        working_dir = extract_working_directory(session_content)

        # Парсим диалог на сообщения
        messages = parse_dialog_messages(session_content)

        parsed_sessions.append({
            'session_time': session_time,
            'hwnd': hwnd,
            'window_title': window_title,
            'project': project,
            'working_dir': working_dir,
            'messages': messages
        })

    return parsed_sessions

def extract_project_name(window_title, content):
    """Извлечение имени проекта"""
    # Из window title
    if 'BTIdoc' in window_title or 'BTIdoc' in content:
        return 'BTIdoc'
    elif 'BTIman' in window_title or 'BTIman' in content:
        return 'BTIman'
    elif 'BTI_API' in window_title or 'BTI_API' in content:
        return 'BTI_API'
    elif 'ClaudeCodeLogger' in window_title or 'ClaudeCodeLogger' in content:
        return 'ClaudeCodeLogger'

    # Из содержимого - ищем cwd:
    cwd_match = re.search(r'cwd: (.+)', content)
    if cwd_match:
        path = cwd_match.group(1).strip()
        if 'BTIdoc' in path:
            return 'BTIdoc'
        elif 'BTIman' in path:
            return 'BTIman'
        elif 'BTI_API' in path:
            return 'BTI_API'
        elif 'ClaudeCodeLogger' in path:
            return 'ClaudeCodeLogger'

    return 'Unknown Project'

def extract_working_directory(content):
    """Извлечение рабочего каталога"""
    cwd_match = re.search(r'cwd: (.+)', content)
    if cwd_match:
        return cwd_match.group(1).strip()

    # Fallback - пытаемся найти пути в содержимом
    path_patterns = [
        r'C:\\Users\\Gajda\\source\\repos\\(\w+)',
        r'C:/Users/Gajda/source/repos/(\w+)',
    ]

    for pattern in path_patterns:
        match = re.search(pattern, content)
        if match:
            project = match.group(1)
            return f"C:/Users/Gajda/source/repos/{project}"

    return "C:/Users/Gajda/source/repos/Unknown"

def parse_dialog_messages(content):
    """Парсинг диалога на user/assistant сообщения"""
    messages = []

    # Убираем заголовок сессии и разделители
    content = re.sub(r'^.*?WINDOW:.*?\n\n', '', content, flags=re.DOTALL)
    content = re.sub(r'─+', '', content)

    # Разбиваем на блоки по > и ●
    parts = re.split(r'(^> |^● )', content, flags=re.MULTILINE)

    current_type = None
    current_content = []

    for part in parts:
        if part == '> ':
            # Сохраняем предыдущее сообщение
            if current_type and current_content:
                messages.append({
                    'type': current_type,
                    'content': ''.join(current_content).strip()
                })
            current_type = 'user'
            current_content = []
        elif part == '● ':
            # Сохраняем предыдущее сообщение
            if current_type and current_content:
                messages.append({
                    'type': current_type,
                    'content': ''.join(current_content).strip()
                })
            current_type = 'assistant'
            current_content = []
        else:
            if current_type:
                current_content.append(part)

    # Сохраняем последнее сообщение
    if current_type and current_content:
        messages.append({
            'type': current_type,
            'content': ''.join(current_content).strip()
        })

    # Фильтруем пустые сообщения
    return [msg for msg in messages if msg['content']]

def send_to_database(session):
    """Отправка сессии в БД через BTI_API"""
    api_url = "http://62.149.5.16:5080/mcp/tools/log_claude_dialog"

    # Формируем сообщение в формате CCL
    dialog_parts = []
    for msg in session['messages']:
        if msg['type'] == 'user':
            dialog_parts.append(f">{msg['content']}")
        else:
            dialog_parts.append(msg['content'])

    dialog_text = '\n'.join(dialog_parts)

    payload = {
        'sProject': session['project'],
        'sWorkingDirectory': session['working_dir'],
        'sHwnd': session['hwnd'],
        'sWindowTitle': session['window_title'],
        'sMessage': dialog_text
    }

    try:
        response = requests.post(api_url, json=payload, headers={'Content-Type': 'application/json'})

        if response.status_code == 200:
            result = response.json()
            if result.get('bSuccess'):
                return True, result.get('sMessage', 'Success')
            else:
                return False, result.get('sMessage', 'Unknown error')
        else:
            return False, f"HTTP {response.status_code}: {response.text}"

    except Exception as e:
        return False, f"Exception: {str(e)}"

def main():
    file_path = r"c:\Data\BTI\claude_dialogs.txt"

    print("🔍 Парсинг claude_dialogs.txt...")
    sessions = parse_claude_dialogs(file_path)

    print(f"📊 Найдено сессий: {len(sessions)}")

    success_count = 0
    error_count = 0

    for i, session in enumerate(sessions, 1):
        print(f"\n📤 Сессия {i}/{len(sessions)}: {session['session_time']} - {session['project']}")
        print(f"   HWND: {session['hwnd']}, Сообщений: {len(session['messages'])}")

        if not session['messages']:
            print("   ⚠️ Пропускаю - нет сообщений")
            continue

        success, message = send_to_database(session)

        if success:
            print(f"   ✅ {message}")
            success_count += 1
        else:
            print(f"   ❌ Ошибка: {message}")
            error_count += 1

    print(f"\n🎯 ИТОГО:")
    print(f"   ✅ Успешно: {success_count}")
    print(f"   ❌ Ошибки: {error_count}")
    print(f"   📊 Всего: {len(sessions)}")

if __name__ == "__main__":
    main()