"""
Diagnostic: test different interpretations of ZZ edge signal/outcome.
Goal: find which interpretation gives ~7012 signals, P1~67%, Ratio~2.15
"""
import psycopg2

def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres')
    cur = conn.cursor()

    # Load ZZ1 (delta=1000)
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=1000
        ORDER BY i_bar
    """)
    lZZ1 = cur.fetchall()  # (i_bar, d_price, i_type, i_bar_created, i_bar_break)

    # Load ZZ3 (delta=15000)
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=15000
        ORDER BY i_bar
    """)
    lZZ3 = cur.fetchall()

    conn.close()

    print(f"ZZ1: {len(lZZ1)} points, ZZ3: {len(lZZ3)} points")

    # Build ZZ3 lookup: sorted by i_bar_created for binary search
    lZZ3_by_created = sorted(lZZ3, key=lambda x: x[3])  # sort by i_bar_created

    def get_zz3_mode(iBarSignal):
        """Last ZZ3 type where i_bar_created < iBarSignal"""
        iResult = None
        for p in lZZ3_by_created:
            if p[3] < iBarSignal:
                iResult = p[2]  # i_type
            else:
                break
        return iResult

    # Skip first 3 points of ZZ1
    iStart = 3

    # ============================================================
    # Interpretation 1: signal = P[i].i_type OPPOSITE to ZZ3 mode
    #                   outcome = P[i+2].d_price vs P[i].d_price
    #                   (next same-type extremum: HH or LL test)
    # ============================================================
    print("\n=== Interp 1: opposite type, outcome by P[i+2] price (HH/LL) ===")
    iSig = 0
    iSuc = 0
    dSucLen = 0.0
    dFailLen = 0.0
    iSucN = 0
    iFaiN = 0
    for idx in range(iStart, len(lZZ1) - 2):
        p = lZZ1[idx]
        if p[4] is None:  # no break
            continue
        iBarSignal = p[4]
        iZZ3 = get_zz3_mode(iBarSignal)
        if iZZ3 is None:
            continue
        # Signal condition: P[i].i_type opposite to ZZ3
        if p[2] + iZZ3 != 0:
            continue
        iSig += 1
        # Outcome: P[i+2] (next same-type)
        p2 = lZZ1[idx + 2]
        dLen = abs(p2[1] - p[1])
        if iZZ3 == 1:  # Up: success if higher low (P[i+2].price > P[i].price)
            bSuccess = p2[1] > p[1]
        else:  # Down: success if lower high
            bSuccess = p2[1] < p[1]
        if bSuccess:
            iSuc += 1
            dSucLen += dLen
            iSucN += 1
        else:
            dFailLen += dLen
            iFaiN += 1
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0
    dAvgSuc = dSucLen / iSucN if iSucN > 0 else 0
    dAvgFail = dFailLen / iFaiN if iFaiN > 0 else 0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
    print(f"  Signals={iSig}, P1={dP1:.1f}%, AvgSuc={dAvgSuc:.0f}, AvgFail={dAvgFail:.0f}, Ratio={dRatio:.2f}")

    # ============================================================
    # Interpretation 2: signal = P[i].i_type SAME as ZZ3 mode
    #                   outcome = P[i+2].d_price vs P[i].d_price
    # ============================================================
    print("\n=== Interp 2: same type, outcome by P[i+2] price (HH/LL) ===")
    iSig = 0
    iSuc = 0
    dSucLen = 0.0
    dFailLen = 0.0
    iSucN = 0
    iFaiN = 0
    for idx in range(iStart, len(lZZ1) - 2):
        p = lZZ1[idx]
        if p[4] is None:
            continue
        iBarSignal = p[4]
        iZZ3 = get_zz3_mode(iBarSignal)
        if iZZ3 is None:
            continue
        # Signal condition: P[i].i_type SAME as ZZ3
        if p[2] != iZZ3:
            continue
        iSig += 1
        p2 = lZZ1[idx + 2]
        dLen = abs(p2[1] - p[1])
        if iZZ3 == 1:  # Up: success if higher high
            bSuccess = p2[1] > p[1]
        else:  # Down: success if lower low
            bSuccess = p2[1] < p[1]
        if bSuccess:
            iSuc += 1
            dSucLen += dLen
            iSucN += 1
        else:
            dFailLen += dLen
            iFaiN += 1
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0
    dAvgSuc = dSucLen / iSucN if iSucN > 0 else 0
    dAvgFail = dFailLen / iFaiN if iFaiN > 0 else 0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
    print(f"  Signals={iSig}, P1={dP1:.1f}%, AvgSuc={dAvgSuc:.0f}, AvgFail={dAvgFail:.0f}, Ratio={dRatio:.2f}")

    # ============================================================
    # Interpretation 3: signal = P[i].i_type OPPOSITE to ZZ3
    #                   outcome = P[i+1] price favorable?
    #                   ZZ3=Up: P[i+1].price - P[i].price > 0 (price went up)
    #                   (since P[i] is Min and P[i+1] is Max, this is always true)
    #                   ... so use LENGTH comparison or threshold
    # ============================================================
    # Skip this — always 100% as analyzed

    # ============================================================
    # Interpretation 4: signal = P[i].i_type OPPOSITE to ZZ3
    #                   "next" determined by i_bar_created order
    #                   next = first ZZ1 with i_bar_created > signal_bar
    # ============================================================
    print("\n=== Interp 4: opposite type, next by i_bar_created order ===")
    # Build index: i_bar_created -> (i_bar, d_price, i_type)
    lZZ1_by_created = sorted(range(len(lZZ1)), key=lambda k: lZZ1[k][3])
    iSig = 0
    iSuc = 0
    dSucLen = 0.0
    dFailLen = 0.0
    iSucN = 0
    iFaiN = 0
    for idx in range(iStart, len(lZZ1)):
        p = lZZ1[idx]
        if p[4] is None:
            continue
        iBarSignal = p[4]
        iZZ3 = get_zz3_mode(iBarSignal)
        if iZZ3 is None:
            continue
        if p[2] + iZZ3 != 0:  # opposite
            continue
        # Find "current" = last ZZ1 with i_bar_created < signal
        # Find "next" = first ZZ1 with i_bar_created > signal
        eCurrent = None
        eNext = None
        for k in lZZ1_by_created:
            pt = lZZ1[k]
            if pt[3] < iBarSignal:
                eCurrent = pt
            elif pt[3] > iBarSignal and eNext is None:
                eNext = pt
                break
        if eCurrent is None or eNext is None:
            continue
        iSig += 1
        dLen = abs(eNext[1] - eCurrent[1])
        bSuccess = (eNext[2] == iZZ3)
        if bSuccess:
            iSuc += 1
            dSucLen += dLen
            iSucN += 1
        else:
            dFailLen += dLen
            iFaiN += 1
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0
    dAvgSuc = dSucLen / iSucN if iSucN > 0 else 0
    dAvgFail = dFailLen / iFaiN if iFaiN > 0 else 0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
    print(f"  Signals={iSig}, P1={dP1:.1f}%, AvgSuc={dAvgSuc:.0f}, AvgFail={dAvgFail:.0f}, Ratio={dRatio:.2f}")

    # ============================================================
    # Interpretation 5: signal = P[i].i_type SAME as ZZ3
    #                   next by i_bar_created
    # ============================================================
    print("\n=== Interp 5: same type, next by i_bar_created order ===")
    iSig = 0
    iSuc = 0
    dSucLen = 0.0
    dFailLen = 0.0
    iSucN = 0
    iFaiN = 0
    for idx in range(iStart, len(lZZ1)):
        p = lZZ1[idx]
        if p[4] is None:
            continue
        iBarSignal = p[4]
        iZZ3 = get_zz3_mode(iBarSignal)
        if iZZ3 is None:
            continue
        if p[2] != iZZ3:
            continue
        eCurrent = None
        eNext = None
        for k in lZZ1_by_created:
            pt = lZZ1[k]
            if pt[3] < iBarSignal:
                eCurrent = pt
            elif pt[3] > iBarSignal and eNext is None:
                eNext = pt
                break
        if eCurrent is None or eNext is None:
            continue
        iSig += 1
        dLen = abs(eNext[1] - eCurrent[1])
        bSuccess = (eNext[2] == iZZ3)
        if bSuccess:
            iSuc += 1
            dSucLen += dLen
            iSucN += 1
        else:
            dFailLen += dLen
            iFaiN += 1
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0
    dAvgSuc = dSucLen / iSucN if iSucN > 0 else 0
    dAvgFail = dFailLen / iFaiN if iFaiN > 0 else 0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
    print(f"  Signals={iSig}, P1={dP1:.1f}%, AvgSuc={dAvgSuc:.0f}, AvgFail={dAvgFail:.0f}, Ratio={dRatio:.2f}")

    # ============================================================
    # Interpretation 6: signal = P[i].i_type OPPOSITE to ZZ3
    #                   outcome based on P[i+1] but comparing PRICE direction
    #                   ZZ3=Up, P[i] is Min: next P[i+1] is Max
    #                     length = P[i+1].price - P[i].price (always positive)
    #                   ... hmm always success. Skip.
    # ============================================================

    # ============================================================
    # Interpretation 7: The signal fires for EACH break, regardless of direction.
    #   Outcome = does the "next leg" go in ZZ3 direction?
    #   Next leg from P[i] to P[i+1]:
    #     direction = sign(P[i+1].price - P[i].price)
    #     ZZ3=Up: success if direction > 0
    #     ZZ3=Down: success if direction < 0
    # ============================================================
    print("\n=== Interp 7: any break, outcome by price direction P[i]->P[i+1] ===")
    iSig = 0
    iSuc = 0
    dSucLen = 0.0
    dFailLen = 0.0
    iSucN = 0
    iFaiN = 0
    for idx in range(iStart, len(lZZ1) - 1):
        p = lZZ1[idx]
        if p[4] is None:
            continue
        iBarSignal = p[4]
        iZZ3 = get_zz3_mode(iBarSignal)
        if iZZ3 is None:
            continue
        iSig += 1
        p1 = lZZ1[idx + 1]
        dDir = p1[1] - p[1]
        dLen = abs(dDir)
        if iZZ3 == 1:
            bSuccess = dDir > 0
        else:
            bSuccess = dDir < 0
        if bSuccess:
            iSuc += 1
            dSucLen += dLen
            iSucN += 1
        else:
            dFailLen += dLen
            iFaiN += 1
    dP1 = iSuc / iSig * 100 if iSig > 0 else 0
    dAvgSuc = dSucLen / iSucN if iSucN > 0 else 0
    dAvgFail = dFailLen / iFaiN if iFaiN > 0 else 0
    dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
    print(f"  Signals={iSig}, P1={dP1:.1f}%, AvgSuc={dAvgSuc:.0f}, AvgFail={dAvgFail:.0f}, Ratio={dRatio:.2f}")

if __name__ == '__main__':
    main()
