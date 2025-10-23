# ЗАДАНИЕ #139: Поиск паттернов ZigZag по 14 условиям через Python + прямое подключение к PostgreSQL
import psycopg2
import json
import sys
import io

# Настройка кодировки для Windows консоли
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Настройки подключения к PostgreSQL
DB_CONFIG = {
    "host": "62.149.5.16",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "postgres"  # Стандартный пароль, может отличаться
}

def main():
    print("=== ЗАДАНИЕ #139: Поиск паттернов ZigZag ===\n")

    try:
        # Подключение к БД
        print("Шаг 1: Подключение к PostgreSQL...")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        # Получить все экстремумы с нумерацией
        print("Шаг 2: Загрузка экстремумов...")
        sql = """
        SELECT
          ROW_NUMBER() OVER (ORDER BY bar_extremum) AS iNo,
          price AS dPrice
        FROM izzml.zz_extremums
        WHERE bar_confirmed IS NOT NULL
          AND symbol = 'EURUSD'
          AND timeframe = 'Range1'
          AND zz_delta = 1.5
        ORDER BY bar_extremum
        """

        cur.execute(sql)
        rows = cur.fetchall()

        print(f"Загружено экстремумов: {len(rows)}")

        # Преобразовать в список цен
        prices = [float(row[1]) for row in rows]
        n_total = len(prices)

        print(f"\nШаг 3: Проверка паттернов (нужно минимум 17 экстремумов)...")

        # Проверить паттерны
        n_patterns = 0
        first_match = None
        last_match = None
        examples = []

        for i in range(16, n_total):  # Начинаем с iNo=17 (индекс 16)
            # Получаем текущий p0 и 16 предыдущих
            p0 = prices[i]
            p1 = prices[i-1]
            p2 = prices[i-2]
            p3 = prices[i-3]
            p4 = prices[i-4]
            p5 = prices[i-5]
            p6 = prices[i-6]
            p7 = prices[i-7]
            p8 = prices[i-8]
            p9 = prices[i-9]
            p10 = prices[i-10]
            p11 = prices[i-11]
            p12 = prices[i-12]
            p13 = prices[i-13]
            p14 = prices[i-14]
            p15 = prices[i-15]
            p16 = prices[i-16]

            # Проверяем 14 условий
            if (p2 < p0 and
                p3 > p1 and
                p4 > p2 and
                p6 < p4 and
                p7 < p5 and
                p7 < p1 and
                p9 > p7 and
                p10 > p8 and
                p12 < p10 and
                p13 < p11 and
                p13 > p7 and
                p15 > p13 and
                p16 > p14 and
                p16 > p10):

                n_patterns += 1
                iNo = i + 1  # iNo начинается с 1, не с 0

                if first_match is None:
                    first_match = iNo
                last_match = iNo

                # Сохраняем первые 10 примеров
                if len(examples) < 10:
                    examples.append({
                        "iNo": iNo,
                        "p0": p0,
                        "p1": p1,
                        "p2": p2,
                        "p7": p7,
                        "p10": p10,
                        "p13": p13,
                        "p16": p16
                    })

        # Вывод результатов
        print(f"\n=== РЕЗУЛЬТАТЫ ===")
        print(f"Количество найденных паттернов: {n_patterns}")
        print(f"Первое совпадение: iNo = {first_match}")
        print(f"Последнее совпадение: iNo = {last_match}")

        if examples:
            print(f"\nПервые {len(examples)} примеров:")
            print("-" * 80)
            for ex in examples:
                print(f"iNo={ex['iNo']:6d}  p0={ex['p0']:.5f}  p1={ex['p1']:.5f}  p2={ex['p2']:.5f}  " +
                      f"p7={ex['p7']:.5f}  p10={ex['p10']:.5f}  p13={ex['p13']:.5f}  p16={ex['p16']:.5f}")

        # Сохранить результат в файл
        result_file = "task139_result.json"
        result = {
            "task_id": 139,
            "n_patterns": n_patterns,
            "first_match_iNo": first_match,
            "last_match_iNo": last_match,
            "examples": examples
        }

        with open(result_file, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

        print(f"\nРезультаты сохранены в: {result_file}")

        # Закрыть подключение
        cur.close()
        conn.close()

    except Exception as e:
        print(f"\nОШИБКА: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
