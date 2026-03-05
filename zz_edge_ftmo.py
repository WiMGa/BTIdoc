"""
Задание #1052: FTMO-отчёт по ZZ тройке 1000/5000/15000
Варианты A/B/C/D — через bti_metrics.py (FTMO $100K стандарт)
"""
import sys
sys.path.insert(0, r'C:\Users\Gajda')

import psycopg2
import bisect
from bti_metrics import calc_metrics, print_metrics


def load_zz(cur, iDelta):
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol = 'BTCUSD' AND i_delta_zz = %s
        ORDER BY i_bar
    """, (iDelta,))
    return cur.fetchall()


def build_mode_lookup(lZZ, iSkip=3):
    lValid = lZZ[iSkip:]
    lSorted = sorted(lValid, key=lambda x: x[3])
    lBars = [p[3] for p in lSorted]
    return lSorted, lBars


def get_mode(lSorted, lBars, iBarSignal):
    idx = bisect.bisect_left(lBars, iBarSignal) - 1
    if idx < 0:
        return None
    return lSorted[idx][2]


def get_last_point(lSorted, lBars, iBarSignal):
    idx = bisect.bisect_left(lBars, iBarSignal) - 1
    if idx < 0:
        return None
    return lSorted[idx]


def generate_trades(lZZ1, lZZ3_sorted, lZZ3_bars, lZZ2_sorted, lZZ2_bars,
                    dBarToTm, sVariant):
    """
    Генерирует список сделок (dPnlPU, tmExit) для bti_metrics.
    dPnlPU = +dLen (success) или -dLen (fail), БЕЗ спреда.
    tmExit = timestamp бара P[i+1] (момент определения исхода).
    """
    lTrades = []
    iStartZZ1 = 3

    for idx in range(iStartZZ1, len(lZZ1) - 1):
        p = lZZ1[idx]
        if p[4] is None:
            continue
        if idx < 1:
            continue

        iBarSignal = p[4]

        iZZ3raw = get_mode(lZZ3_sorted, lZZ3_bars, iBarSignal)
        if iZZ3raw is None:
            continue

        if p[2] + iZZ3raw != 0:
            continue

        # --- Фильтры ZZ₂ ---
        if sVariant in ('B', 'C', 'D'):
            iZZ2raw = get_mode(lZZ2_sorted, lZZ2_bars, iBarSignal)
            if iZZ2raw is None:
                continue

            if sVariant == 'B':
                if iZZ2raw != iZZ3raw:
                    continue
            elif sVariant == 'C':
                if iZZ2raw == iZZ3raw:
                    continue
            elif sVariant == 'D':
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

        if p[2] == 1:
            bSuccess = p1[1] > pm1[1]
        else:
            bSuccess = p1[1] < pm1[1]

        dPnlPU = dLen if bSuccess else -dLen

        # tmExit = timestamp бара P[i+1].i_bar
        iBarExit = p1[0]
        tmExit = dBarToTm.get(iBarExit)
        if tmExit is None:
            continue

        lTrades.append((dPnlPU, tmExit))

    return lTrades


def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti',
                            user='postgres', password='postgres')
    cur = conn.cursor()

    print("Loading ZZ data...")
    lZZ1 = load_zz(cur, 1000)
    lZZ2 = load_zz(cur, 5000)
    lZZ3 = load_zz(cur, 15000)
    print(f"  ZZ1: {len(lZZ1)}, ZZ2: {len(lZZ2)}, ZZ3: {len(lZZ3)}")

    # Загрузка i_bar -> tm для t_bar
    print("Loading bar timestamps...")
    cur.execute("""
        SELECT i_bar, tm
        FROM bti_work.t_bar
        WHERE s_symbol = 'BTCUSD' AND s_tf = 'Range1000'
    """)
    dBarToTm = {r[0]: r[1] for r in cur.fetchall()}
    print(f"  Bars with timestamps: {len(dBarToTm)}")

    conn.close()

    lZZ3_sorted, lZZ3_bars = build_mode_lookup(lZZ3, iSkip=3)
    lZZ2_sorted, lZZ2_bars = build_mode_lookup(lZZ2, iSkip=3)

    # --- FTMO отчёт ---
    print("\n" + "=" * 80)
    print("FTMO $100K REPORT: ZZ ТРОЙКА 1000/5000/15000 — BTCUSD")
    print("=" * 80)

    lResults = []
    for sVar in ['A', 'B', 'C', 'D']:
        lTrades = generate_trades(lZZ1, lZZ3_sorted, lZZ3_bars,
                                  lZZ2_sorted, lZZ2_bars, dBarToTm, sVar)
        print(f"  Variant {sVar}: {len(lTrades)} trades")
        eRes = calc_metrics(lTrades, dSpreadPU=20.0, sScenario=f'ZZ {sVar}')
        lResults.append(eRes)

    print()
    print_metrics(lResults)
    print("\nDone.")


if __name__ == '__main__':
    main()
