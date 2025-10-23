# ЗАДАНИЕ #139: Экспорт данных ZigZag для анализа
import requests
import json
import sys
import io

# Настройка кодировки
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

API_URL = "http://62.149.5.16:5080"

def export_extremums():
    """Экспортировать экстремумы через специальный endpoint"""
    print("=== Экспорт данных ZigZag для задания #139 ===\n")

    # Попробуем просто GET запрос к API
    url = f"{API_URL}/api/izzml/extremums?symbol=EURUSD&timeframe=Range1&zz_delta=1.5"
    print(f"Запрос: {url}")

    response = requests.get(url)
    print(f"Статус: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"Получено записей: {len(data) if isinstance(data, list) else 'unknown'}")

        # Сохраняем в файл
        with open("zz_extremums_export.json", "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print("Данные сохранены в: zz_extremums_export.json")
        return True
    else:
        print(f"Ошибка: {response.text}")
        return False

if __name__ == "__main__":
    export_extremums()
