"""
Diagnostic v2: more interpretations, proper skip of first 3 ZZ3 points.
Target: ~7012 signals, P1~67.2%, Ratio~2.15
"""
import psycopg2
import bisect

def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres')
    cur = conn.cursor()

    # Load ZZ1
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=1000
        ORDER BY i_bar
    """)
    lZZ1 = cur.fetchall()

    # Load ZZ3
    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=15000
        ORDER BY i_bar
    """)
    lZZ3 = cur.fetchall()

    conn.close()

    print(f"ZZ1: {len(lZZ1)} points, ZZ3: {len(lZZ3)} points")

    # ZZ3: skip first 3 points
    lZZ3_valid = lZZ3[3:]  # from 4th point onward
    print(f"ZZ3 valid (after skip 3): {len(lZZ3_valid)} points")
    print(f"  First valid ZZ3: i_bar={lZZ3_valid[0][0]}, type={lZZ3_valid[0][2]}, created={lZZ3_valid[0][3]}")

    # Build sorted list of (i_bar_created, i_type) for ZZ3 valid points
    lZZ3_created = sorted(lZZ3_valid, key=lambda x: x[3])
    lZZ3_created_bars = [p[3] for p in lZZ3_created]

    def get_zz3_mode(iBarSignal):
        """Last valid ZZ3 type where i_bar_created < iBarSignal"""
        idx = bisect.bisect_left(lZZ3_created_bars, iBarSignal) - 1
        if idx < 0:
            return None
        return lZZ3_created[idx][2]

    # ZZ1: skip first 3
    iStartZZ1 = 3

    def run_test(sName, fSignalCond, fOutcome, fLength):
        """
        fSignalCond(p, iZZ3mode) -> bool
        fOutcome(lZZ1, idx, iZZ3mode) -> (bSuccess, dLength) or None
        """
        iSig = 0
        iSuc = 0
        dSucLen = 0.0
        dFailLen = 0.0
        iMaxFail = 0
        iCurFail = 0
        for idx in range(iStartZZ1, len(lZZ1)):
            p = lZZ1[idx]
            if p[4] is None:
                continue
            iBarSignal = p[4]
            iZZ3 = get_zz3_mode(iBarSignal)
            if iZZ3 is None:
                continue
            if not fSignalCond(p, iZZ3):
                continue
            result = fOutcome(lZZ1, idx, iZZ3)
            if result is None:
                continue
            bSuccess, dLen = result
            iSig += 1
            if bSuccess:
                iSuc += 1
                dSucLen += dLen
                iCurFail = 0
            else:
                dFailLen += dLen
                iCurFail += 1
                if iCurFail > iMaxFail:
                    iMaxFail = iCurFail

        iFail = iSig - iSuc
        dP1 = iSuc / iSig * 100 if iSig > 0 else 0
        dAvgSuc = dSucLen / iSuc if iSuc > 0 else 0
        dAvgFail = dFailLen / iFail if iFail > 0 else 0
        dRatio = dAvgSuc / dAvgFail if dAvgFail > 0 else 0
        print(f"  {sName}: Sig={iSig}, P1={dP1:.1f}%, AvgS={dAvgSuc:.0f}, AvgF={dAvgFail:.0f}, R={dRatio:.2f}, MxF={iMaxFail}")

    # ---- Signal conditions ----
    def sig_opposite(p, zz3):
        return p[2] + zz3 == 0  # type opposite to ZZ3

    def sig_same(p, zz3):
        return p[2] == zz3  # type same as ZZ3

    def sig_any(p, zz3):
        return True

    # ---- Outcome functions ----
    # O1: next point P[i+1], success by type match
    def out_next_type(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1):
            return None
        nxt = lZZ1[idx + 1]
        cur = lZZ1[idx]
        bSuc = (nxt[2] == zz3)
        dLen = abs(nxt[1] - cur[1])
        return (bSuc, dLen)

    # O2: P[i+2] price comparison (HH/LL)
    def out_p2_price(lZZ1, idx, zz3):
        if idx + 2 >= len(lZZ1):
            return None
        cur = lZZ1[idx]
        p2 = lZZ1[idx + 2]
        dLen = abs(p2[1] - cur[1])
        if zz3 == 1:
            bSuc = p2[1] > cur[1]
        else:
            bSuc = p2[1] < cur[1]
        return (bSuc, dLen)

    # O3: next break point type matches ZZ3
    def out_next_break_type(lZZ1, idx, zz3):
        cur = lZZ1[idx]
        for j in range(idx + 1, len(lZZ1)):
            if lZZ1[j][4] is not None:
                nxt = lZZ1[j]
                bSuc = (nxt[2] == zz3)
                dLen = abs(nxt[1] - cur[1])
                return (bSuc, dLen)
        return None

    # O4: next break point type OPPOSITE to P[i]'s type (checking if trend changed)
    def out_next_break_opposite(lZZ1, idx, zz3):
        cur = lZZ1[idx]
        for j in range(idx + 1, len(lZZ1)):
            if lZZ1[j][4] is not None:
                nxt = lZZ1[j]
                # Success if next break type matches ZZ3 mode
                bSuc = (nxt[2] == zz3)
                dLen = abs(nxt[1] - cur[1])
                return (bSuc, dLen)
        return None

    # O5: price direction P[i]→P[i+1] matches ZZ3
    def out_price_dir(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1):
            return None
        cur = lZZ1[idx]
        nxt = lZZ1[idx + 1]
        dDir = nxt[1] - cur[1]
        dLen = abs(dDir)
        if zz3 == 1:
            bSuc = dDir > 0
        else:
            bSuc = dDir < 0
        return (bSuc, dLen)

    # O6: "текущий" = P[i+1] (last ZZ1 by i_bar before break bar),
    #     "следующий" = P[i+2] (first ZZ1 by i_bar after break bar)
    #     Success: P[i+2].type matches ZZ3
    #     Length: |P[i+2].price - P[i+1].price|
    def out_window_type(lZZ1, idx, zz3):
        if idx + 2 >= len(lZZ1):
            return None
        p1 = lZZ1[idx + 1]
        p2 = lZZ1[idx + 2]
        bSuc = (p2[2] == zz3)
        dLen = abs(p2[1] - p1[1])
        return (bSuc, dLen)

    # O7: same as O6 but length based on P[i+1] price direction
    #     Success = price from P[i+1] to P[i+2] goes in ZZ3 direction
    def out_window_pricedir(lZZ1, idx, zz3):
        if idx + 2 >= len(lZZ1):
            return None
        p1 = lZZ1[idx + 1]
        p2 = lZZ1[idx + 2]
        dDir = p2[1] - p1[1]
        dLen = abs(dDir)
        if zz3 == 1:
            bSuc = dDir > 0
        else:
            bSuc = dDir < 0
        return (bSuc, dLen)

    # O8: P[i+1] vs P[i-1] (does the correction make a HH/LL?)
    def out_p1_vs_pm1(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        p1 = lZZ1[idx + 1]
        dLen = abs(p1[1] - pm1[1])
        # pm1 and p1 have the same type (both opposite of p[i])
        if zz3 == 1:  # Up: success if p1 (Max) > pm1 (Max) → higher high
            bSuc = p1[1] > pm1[1]
        else:  # Down: success if p1 (Min) < pm1 (Min) → lower low
            bSuc = p1[1] < pm1[1]
        return (bSuc, dLen)

    print("\n=== With first-3-ZZ3 skip ===")
    print("--- Signal: opposite type ---")
    run_test("O1:next_type", sig_opposite, out_next_type, None)
    run_test("O2:P[i+2]_price", sig_opposite, out_p2_price, None)
    run_test("O3:next_brk_type", sig_opposite, out_next_break_type, None)
    run_test("O5:price_dir", sig_opposite, out_price_dir, None)
    run_test("O6:window_type", sig_opposite, out_window_type, None)
    run_test("O7:window_pdir", sig_opposite, out_window_pricedir, None)
    run_test("O8:P1_vs_Pm1", sig_opposite, out_p1_vs_pm1, None)

    print("\n--- Signal: same type ---")
    run_test("O1:next_type", sig_same, out_next_type, None)
    run_test("O2:P[i+2]_price", sig_same, out_p2_price, None)
    run_test("O3:next_brk_type", sig_same, out_next_break_type, None)
    run_test("O5:price_dir", sig_same, out_price_dir, None)
    run_test("O6:window_type", sig_same, out_window_type, None)
    run_test("O7:window_pdir", sig_same, out_window_pricedir, None)
    run_test("O8:P1_vs_Pm1", sig_same, out_p1_vs_pm1, None)

    print("\n--- Signal: any break ---")
    run_test("O1:next_type", sig_any, out_next_type, None)
    run_test("O5:price_dir", sig_any, out_price_dir, None)
    run_test("O3:next_brk_type", sig_any, out_next_break_type, None)
    run_test("O8:P1_vs_Pm1", sig_any, out_p1_vs_pm1, None)

if __name__ == '__main__':
    main()
