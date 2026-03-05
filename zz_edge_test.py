"""
Задание #1052: Edge test — ZZ тройка 1000/5000/15000, варианты A/B/C/D
BTCUSD, Range1000

Сигнал: i_bar_break_left_extremum ZZ₁ где:
  - break IS NOT NULL
  - P[i].i_type противоположен последнему ZZ₃ raw type
  - ZZ₃ определяется по i_bar_created < signal_bar (пропуск первых 3)

Исход (Success/Fail):
  - P[i-1] и P[i+1] — соседи (одного типа, противоположного P[i])
  - Max break (type=1): success if P[i+1].price > P[i-1].price (Higher Low)
  - Min break (type=-1): success if P[i+1].price < P[i-1].price (Lower High)
  - Длина = |P[i+1].price - P[i-1].price|
"""
import psycopg2
import bisect

# ============================================================
# Загрузка данных
# ============================================================
def load_zz(cur, iDelta):
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol = 'BTCUSD' AND i_delta_zz = %s
        ORDER BY i_bar
    """, (iDelta,))
    return cur.fetchall()  # (0:i_bar, 1:d_price, 2:i_type, 3:i_bar_created, 4:break)


def build_mode_lookup(lZZ, iSkip=3):
    """Построить lookup для mode: последний type по i_bar_created < signal_bar."""
    lValid = lZZ[iSkip:]  # пропуск первых iSkip точек
    lSorted = sorted(lValid, key=lambda x: x[3])
    lBars = [p[3] for p in lSorted]
    return lSorted, lBars


def get_mode(lSorted, lBars, iBarSignal):
    """Последний raw i_type где i_bar_created < iBarSignal."""
    idx = bisect.bisect_left(lBars, iBarSignal) - 1
    if idx < 0:
        return None
    return lSorted[idx][2]


def get_last_point(lSorted, lBars, iBarSignal):
    """Последняя полная точка ZZ (i_bar_created < iBarSignal)."""
    idx = bisect.bisect_left(lBars, iBarSignal) - 1
    if idx < 0:
        return None
    return lSorted[idx]


# ============================================================
# Метрики
# ============================================================
def calc_edge_metrics(lSignals):
    """
    lSignals: list of (bSuccess, dLen, iBarSignal)
    Возвращает dict с метриками.
    """
    if not lSignals:
        return None
    iSig = len(lSignals)
    iSuc = sum(1 for s in lSignals if s[0])
    iFail = iSig - iSuc
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0.0
    dSucLen = sum(s[1] for s in lSignals if s[0])
    dFailLen = sum(s[1] for s in lSignals if not s[0])
    dAvgSuc = dSucLen / iSuc if iSuc > 0 else 0.0
    dAvgFail = dFailLen / iFail if iFail > 0 else 0.0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0.0

    iMaxFail = 0
    iCurFail = 0
    for s in lSignals:
        if not s[0]:
            iCurFail += 1
            if iCurFail > iMaxFail:
                iMaxFail = iCurFail
        else:
            iCurFail = 0

    return {
        'iSignals': iSig,
        'dP1': dP1,
        'dAvgSuc': dAvgSuc,
        'dAvgFail': dAvgFail,
        'dRatio': dRatio,
        'iMaxFail': iMaxFail,
    }


# ============================================================
# Генерация сигналов
# ============================================================
def generate_signals(lZZ1, lZZ3_sorted, lZZ3_bars, lZZ2_sorted, lZZ2_bars, sVariant):
    """
    Генерирует список сигналов (bSuccess, dLen, iBarSignal) для указанного варианта.
    sVariant: 'A', 'B', 'C', 'D'
    """
    lResults = []
    iStartZZ1 = 3  # пропуск первых 3 ZZ₁

    for idx in range(iStartZZ1, len(lZZ1) - 1):
        p = lZZ1[idx]
        if p[4] is None:  # нет break
            continue
        if idx < 1:
            continue

        iBarSignal = p[4]  # signal bar = i_bar_break_left_extremum

        # ZZ₃ mode: raw type последнего сформированного ZZ₃
        iZZ3raw = get_mode(lZZ3_sorted, lZZ3_bars, iBarSignal)
        if iZZ3raw is None:
            continue

        # Условие сигнала: P[i].i_type ПРОТИВОПОЛОЖЕН raw ZZ₃ type
        if p[2] + iZZ3raw != 0:
            continue

        # --- Фильтры по ZZ₂ для вариантов B, C, D ---
        if sVariant in ('B', 'C', 'D'):
            iZZ2raw = get_mode(lZZ2_sorted, lZZ2_bars, iBarSignal)
            if iZZ2raw is None:
                continue

            if sVariant == 'B':
                # ZZ₂ в том же направлении что ZZ₃
                if iZZ2raw != iZZ3raw:
                    continue

            elif sVariant == 'C':
                # ZZ₂ в коррекции (противоположен ZZ₃)
                if iZZ2raw == iZZ3raw:
                    continue

            elif sVariant == 'D':
                # ZZ₂ тоже делает пробой в направлении ZZ₃
                # Последняя точка ZZ₂ должна:
                # 1) i_type совпадает с ZZ₃ raw mode
                # 2) i_bar_break_left_extremum IS NOT NULL
                # 3) i_bar_break_left_extremum <= signal bar
                eLastZZ2 = get_last_point(lZZ2_sorted, lZZ2_bars, iBarSignal)
                if eLastZZ2 is None:
                    continue
                if eLastZZ2[2] != iZZ3raw:
                    continue
                if eLastZZ2[4] is None:
                    continue
                if eLastZZ2[4] > iBarSignal:
                    continue

        # --- Outcome ---
        pm1 = lZZ1[idx - 1]
        p1 = lZZ1[idx + 1]
        dLen = abs(p1[1] - pm1[1])

        # Success: break direction continues
        # Max break (type=1, bullish): success if P[i+1] > P[i-1] (Higher Low)
        # Min break (type=-1, bearish): success if P[i+1] < P[i-1] (Lower High)
        if p[2] == 1:
            bSuccess = p1[1] > pm1[1]
        else:
            bSuccess = p1[1] < pm1[1]

        lResults.append((bSuccess, dLen, iBarSignal))

    return lResults


# ============================================================
# Вывод таблицы
# ============================================================
def print_table(lVariants):
    """Вывести сводную таблицу метрик."""
    print(f"{'Variant':<10} | {'Signals':>8} | {'P1':>7} | {'AvgSuc':>8} | {'AvgFail':>8} | {'Ratio':>6} | {'MaxFail':>7}")
    print("-" * 72)
    for sName, eM in lVariants:
        if eM is None:
            print(f"{sName:<10} | {'N/A':>8} |")
            continue
        print(f"{sName:<10} | {eM['iSignals']:>8} | {eM['dP1']:>6.1f}% | {eM['dAvgSuc']:>8.0f} | {eM['dAvgFail']:>8.0f} | {eM['dRatio']:>6.2f} | {eM['iMaxFail']:>7}")


def print_period_table(sVariant, lPeriodMetrics):
    """Вывести разбивку по подпериодам."""
    print(f"\n  {sVariant} — разбивка по подпериодам:")
    print(f"  {'Period':<10} | {'Signals':>8} | {'P1':>7} | {'AvgSuc':>8} | {'AvgFail':>8} | {'Ratio':>6} | {'MaxFail':>7}")
    print("  " + "-" * 72)
    for sP, eM in lPeriodMetrics:
        if eM is None:
            print(f"  {sP:<10} | {'N/A':>8} |")
            continue
        print(f"  {sP:<10} | {eM['iSignals']:>8} | {eM['dP1']:>6.1f}% | {eM['dAvgSuc']:>8.0f} | {eM['dAvgFail']:>8.0f} | {eM['dRatio']:>6.2f} | {eM['iMaxFail']:>7}")


# ============================================================
# Main
# ============================================================
def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres')
    cur = conn.cursor()

    # Загрузка ZZ
    print("Loading ZZ data...")
    lZZ1 = load_zz(cur, 1000)
    lZZ2 = load_zz(cur, 5000)
    lZZ3 = load_zz(cur, 15000)
    print(f"  ZZ1: {len(lZZ1)}, ZZ2: {len(lZZ2)}, ZZ3: {len(lZZ3)}")

    # Границы подпериодов (по i_bar signal)
    cur.execute("""
        SELECT
          (SELECT min(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm >= '2025-06-03') AS p1s,
          (SELECT max(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm < '2025-10-02') AS p1e,
          (SELECT min(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm >= '2025-10-02') AS p2s,
          (SELECT max(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm < '2025-12-01') AS p2e,
          (SELECT min(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm >= '2025-12-01') AS p3s,
          (SELECT max(i_bar) FROM bti_work.t_bar WHERE s_symbol='BTCUSD' AND s_tf='Range1000' AND tm < '2026-03-01') AS p3e
    """)
    ePeriods = cur.fetchone()
    conn.close()

    lPeriodBounds = [
        ('Period1', ePeriods[0], ePeriods[1]),
        ('Period2', ePeriods[2], ePeriods[3]),
        ('Period3', ePeriods[4], ePeriods[5]),
    ]
    print(f"  Period bounds: {lPeriodBounds}")

    # Построение lookup для ZZ₃ и ZZ₂
    lZZ3_sorted, lZZ3_bars = build_mode_lookup(lZZ3, iSkip=3)
    lZZ2_sorted, lZZ2_bars = build_mode_lookup(lZZ2, iSkip=3)

    print(f"  ZZ3 valid: {len(lZZ3_sorted)} (first created at bar {lZZ3_sorted[0][3]})")
    print(f"  ZZ2 valid: {len(lZZ2_sorted)} (first created at bar {lZZ2_sorted[0][3]})")

    # --- Генерация и вывод ---
    print("\n" + "=" * 72)
    print("EDGE TEST: ZZ ТРОЙКА 1000/5000/15000 — BTCUSD")
    print("=" * 72)

    lAllVariants = []
    for sVar in ['A', 'B', 'C', 'D']:
        lSigs = generate_signals(lZZ1, lZZ3_sorted, lZZ3_bars,
                                 lZZ2_sorted, lZZ2_bars, sVar)
        eMetrics = calc_edge_metrics(lSigs)
        lAllVariants.append((sVar, eMetrics, lSigs))

    # Сводная таблица
    print("\n--- СВОДКА ---")
    print_table([(v[0], v[1]) for v in lAllVariants])

    # Подпериоды
    for sVar, eM, lSigs in lAllVariants:
        lPM = []
        for sPName, iBarFrom, iBarTo in lPeriodBounds:
            lFiltered = [(s[0], s[1], s[2]) for s in lSigs
                         if iBarFrom <= s[2] <= iBarTo]
            ePM = calc_edge_metrics(lFiltered)
            lPM.append((sPName, ePM))
        print_period_table(sVar, lPM)

    print("\nDone.")


if __name__ == '__main__':
    main()
