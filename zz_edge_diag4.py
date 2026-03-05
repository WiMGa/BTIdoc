"""
Diagnostic v4: Test color-based and mixed interpretations.
"""
import psycopg2
import bisect

def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres')
    cur = conn.cursor()

    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum, s_color
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=1000
        ORDER BY i_bar
    """)
    lZZ1 = cur.fetchall()  # (0:i_bar, 1:d_price, 2:i_type, 3:i_bar_created, 4:break, 5:s_color)

    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum, s_color
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=15000
        ORDER BY i_bar
    """)
    lZZ3 = cur.fetchall()
    conn.close()

    lZZ3_valid = lZZ3[3:]
    lZZ3_created = sorted(lZZ3_valid, key=lambda x: x[3])
    lZZ3_created_bars = [p[3] for p in lZZ3_created]

    def get_zz3_mode(iBarSignal):
        idx = bisect.bisect_left(lZZ3_created_bars, iBarSignal) - 1
        if idx < 0:
            return None
        return lZZ3_created[idx][2]

    def color_dir(sColor):
        """Convert color to direction: 1=Up, -1=Down, 0=unknown"""
        if sColor in ('LightGreen', 'SeaGreen'):
            return 1
        elif sColor in ('Orange', 'Crimson'):
            return -1
        return 0

    def run(sName, fFilter, fOutcome):
        iSig = 0
        iSuc = 0
        dSucLen = 0.0
        dFailLen = 0.0
        iMaxFail = 0
        iCurFail = 0
        for idx in range(3, len(lZZ1)):
            p = lZZ1[idx]
            if p[4] is None:
                continue
            iBarSignal = p[4]
            iZZ3 = get_zz3_mode(iBarSignal)
            if iZZ3 is None:
                continue
            if not fFilter(p, iZZ3):
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

    sig_opp = lambda p, zz3: p[2] + zz3 == 0
    sig_same = lambda p, zz3: p[2] == zz3
    sig_any = lambda p, zz3: True

    # Color-based signal: P[i]'s color matches ZZ3 direction
    def sig_color_match(p, zz3):
        return color_dir(p[5]) == zz3

    # Color-based signal: P[i]'s color OPPOSITE to ZZ3
    def sig_color_opp(p, zz3):
        cd = color_dir(p[5])
        return cd != 0 and cd != zz3

    # ---- Outcomes ----

    # Color outcome: next point's color matches ZZ3
    def out_color_next(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1):
            return None
        nxt = lZZ1[idx + 1]
        bSuc = color_dir(nxt[5]) == zz3
        dLen = abs(nxt[1] - lZZ1[idx][1])
        return (bSuc, dLen)

    # Color outcome: next point's color matches ZZ3, len=|P[i+1]-P[i-1]|
    def out_color_next_lenB(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        nxt = lZZ1[idx + 1]
        bSuc = color_dir(nxt[5]) == zz3
        dLen = abs(nxt[1] - pm1[1])
        return (bSuc, dLen)

    # Price-based: P[i+1] vs P[i-1] (HH/LL), len = |P[i+1] - P[i-1]|
    def out_hl(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        p1 = lZZ1[idx + 1]
        dLen = abs(p1[1] - pm1[1])
        if zz3 == 1:
            bSuc = p1[1] > pm1[1]
        else:
            bSuc = p1[1] < pm1[1]
        return (bSuc, dLen)

    # Mixed: Signal by color, outcome by price HL
    # with length = |P[i+1] - P[i]| (next leg)
    def out_hl_lenA(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        p = lZZ1[idx]
        p1 = lZZ1[idx + 1]
        dLen = abs(p1[1] - p[1])
        if zz3 == 1:
            bSuc = p1[1] > pm1[1]
        else:
            bSuc = p1[1] < pm1[1]
        return (bSuc, dLen)

    print("=== Color-based signal: color matches ZZ3 ===")
    run("color_match + color_next", sig_color_match, out_color_next)
    run("color_match + color_next_lenB", sig_color_match, out_color_next_lenB)
    run("color_match + HL", sig_color_match, out_hl)

    print("\n=== Color-based signal: color opposite ZZ3 ===")
    run("color_opp + color_next", sig_color_opp, out_color_next)
    run("color_opp + HL", sig_color_opp, out_hl)

    print("\n=== Type-based signal: opposite type, color outcome ===")
    run("opp + color_next", sig_opp, out_color_next)
    run("opp + color_next_lenB", sig_opp, out_color_next_lenB)

    print("\n=== Type-based signal: same type, color outcome ===")
    run("same + color_next", sig_same, out_color_next)
    run("same + color_next_lenB", sig_same, out_color_next_lenB)

    print("\n=== ANY break, various outcomes ===")
    run("any + color_next", sig_any, out_color_next)
    run("any + HL", sig_any, out_hl)
    run("any + HL_lenA", sig_any, out_hl_lenA)

    # New interpretation: ZZ3 mode reversed
    # Last ZZ3 type=1 (Max) → mode DOWN (next move after Max is down)
    def get_zz3_mode_inv(iBarSignal):
        idx = bisect.bisect_left(lZZ3_created_bars, iBarSignal) - 1
        if idx < 0:
            return None
        return -lZZ3_created[idx][2]  # INVERTED

    def run_inv(sName, fFilter, fOutcome):
        iSig = 0
        iSuc = 0
        dSucLen = 0.0
        dFailLen = 0.0
        iMaxFail = 0
        iCurFail = 0
        for idx in range(3, len(lZZ1)):
            p = lZZ1[idx]
            if p[4] is None:
                continue
            iBarSignal = p[4]
            iZZ3 = get_zz3_mode_inv(iBarSignal)
            if iZZ3 is None:
                continue
            if not fFilter(p, iZZ3):
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

    # With inverted ZZ3: same = original opposite, opposite = original same
    print("\n=== INVERTED ZZ3 mode ===")
    run_inv("inv_same + HL", sig_same, out_hl)
    run_inv("inv_opp + HL", sig_opp, out_hl)
    run_inv("inv_same + color_next", sig_same, out_color_next)
    run_inv("inv_opp + color_next", sig_opp, out_color_next)

if __name__ == '__main__':
    main()
