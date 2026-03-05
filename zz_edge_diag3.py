"""
Diagnostic v3: Fine-tuning around best candidate (same type + HH/LL outcome).
Target: ~7012 signals, P1~67.2%, Ratio~2.15, MaxFail=7
Best so far: same type + O8(P1_vs_Pm1): Sig=7275, P1=65.2%, R=1.68, MxF=7
"""
import psycopg2
import bisect

def main():
    conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='bti', user='postgres', password='postgres')
    cur = conn.cursor()

    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
        FROM bti_work.t_zz
        WHERE s_symbol='BTCUSD' AND i_delta_zz=1000
        ORDER BY i_bar
    """)
    lZZ1 = cur.fetchall()

    cur.execute("""
        SELECT i_bar, d_price, i_type, i_bar_created, i_bar_break_left_extremum
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

    def run_variant(sName, iStartIdx, fFilter, fOutcome):
        iSig = 0
        iSuc = 0
        dSucLen = 0.0
        dFailLen = 0.0
        iMaxFail = 0
        iCurFail = 0
        for idx in range(iStartIdx, len(lZZ1)):
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

    # ---- Core interpretations around the best candidate ----

    # Sig: P[i].type == ZZ3 (same type)
    sig_same = lambda p, zz3: p[2] == zz3

    # Sig: P[i].type != ZZ3 (opposite type)
    sig_opp = lambda p, zz3: p[2] + zz3 == 0

    # ----- OUTCOME VARIANTS -----

    # A: current=P[i], next=P[i+1]. Success=P[i+1]>P[i-1] (HH/LL). Len=|P[i+1]-P[i]|
    def outA(lZZ1, idx, zz3):
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

    # B: current=P[i], next=P[i+1]. Success=P[i+1]>P[i-1]. Len=|P[i+1]-P[i-1]|
    def outB(lZZ1, idx, zz3):
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

    # C: Success=P[i]>P[i-2] (current Max > prev Max = HH). Len=|P[i]-P[i-2]|
    def outC(lZZ1, idx, zz3):
        if idx < 2:
            return None
        pm2 = lZZ1[idx - 2]
        p = lZZ1[idx]
        dLen = abs(p[1] - pm2[1])
        if zz3 == 1:
            bSuc = p[1] > pm2[1]
        else:
            bSuc = p[1] < pm2[1]
        return (bSuc, dLen)

    # D: Success=P[i+2]>P[i] (next same-type > current). Len=|P[i+1]-P[i]| (next leg)
    def outD(lZZ1, idx, zz3):
        if idx + 2 >= len(lZZ1):
            return None
        p = lZZ1[idx]
        p1 = lZZ1[idx + 1]
        p2 = lZZ1[idx + 2]
        dLen = abs(p1[1] - p[1])
        if zz3 == 1:
            bSuc = p2[1] > p[1]
        else:
            bSuc = p2[1] < p[1]
        return (bSuc, dLen)

    # E: opposite type signal. Success=P[i+1]>P[i-1] (HH/LL of opposite pair). Len=|P[i+1]-P[i]|
    def outE(lZZ1, idx, zz3):
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

    # F: opposite type signal. Success=P[i+1]>P[i-1]. Len=|P[i+1]-P[i-1]|
    def outF(lZZ1, idx, zz3):
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

    print("=== Same type signal ===")
    run_variant("A:P1>Pm1,len=P1-P", 3, sig_same, outA)
    run_variant("B:P1>Pm1,len=P1-Pm1", 3, sig_same, outB)
    run_variant("C:P>Pm2,len=P-Pm2", 3, sig_same, outC)
    run_variant("D:P2>P,len=P1-P", 3, sig_same, outD)

    print("\n=== Opposite type signal ===")
    run_variant("E:P1>Pm1,len=P1-P", 3, sig_opp, outE)
    run_variant("F:P1>Pm1,len=P1-Pm1", 3, sig_opp, outF)

    # G: DIFFERENT INTERPRETATION: signal on P[i], but
    #   "текущий" = P[i] (broken point), "следующий" = P[i+1] (next in sequence)
    #   Success is NOT about type, but about whether the MOVE from P[i] to P[i+1] is:
    #   - larger than the move from P[i-1] to P[i] (impulse > correction)
    def outG(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        p = lZZ1[idx]
        p1 = lZZ1[idx + 1]
        dImpulse = abs(p1[1] - p[1])
        dCorrection = abs(p[1] - pm1[1])
        bSuc = dImpulse > dCorrection
        return (bSuc, abs(p1[1] - p[1]))

    print("\n=== Impulse > Correction ===")
    run_variant("G_same", 3, sig_same, outG)
    run_variant("G_opp", 3, sig_opp, outG)

    # H: what if we use the ACTUAL task definition literally:
    #   Signal: P[i] with break, P[i].type opposite to ZZ3
    #   current = P[i], next = P[i+1]
    #   Success = P[i+1].type matches ZZ3 mode => ALWAYS TRUE (100%)
    #   BUT: what if "matches" means the PRICE DIRECTION (not the type)?
    #   i.e., the move P[i]→P[i+1] is in the ZZ3 direction, compared to
    #   the PREVIOUS move P[i-1]→P[i] (which was against ZZ3)
    #
    #   Actually, let me try: P[i+1] PRICE compared to P[i-1] PRICE
    #   For ZZ3=Up, P[i] is Min(-1), P[i-1] is Max(1), P[i+1] is Max(1)
    #   P[i+1] > P[i-1] means higher high
    def outH(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1) or idx < 1:
            return None
        pm1 = lZZ1[idx - 1]
        p = lZZ1[idx]
        p1 = lZZ1[idx + 1]
        dLen = abs(p1[1] - p[1])  # length = impulse from min to max
        if zz3 == 1:  # Up: p[i] is Min, p[i+1] is Max, p[i-1] is Max
            bSuc = p1[1] > pm1[1]  # Higher High
        else:  # Down: p[i] is Max, p[i+1] is Min, p[i-1] is Min
            bSuc = p1[1] < pm1[1]  # Lower Low
        return (bSuc, dLen)

    print("\n=== Opposite signal: HH/LL of the pair ===")
    run_variant("H:opp,P1>Pm1,len=P1-P", 3, sig_opp, outH)

    # I: FINAL ATTEMPT - what if "следующий i_type ZZ1" means
    #    the i_type of the next ZZ1 extremum WHOSE BREAK FIRES?
    #    Not just any ZZ1 point, but one that also gets broken.
    #    Signal direction: same type as ZZ3
    def outI(lZZ1, idx, zz3):
        p = lZZ1[idx]
        for j in range(idx + 1, len(lZZ1)):
            if lZZ1[j][4] is not None:
                nxt = lZZ1[j]
                bSuc = (nxt[2] == zz3)
                # Length = |nxt.price - p.price|
                dLen = abs(nxt[1] - p[1])
                return (bSuc, dLen)
        return None

    # same but length = |P[i+1].price - P[i].price| (just the next leg, not to break)
    def outJ(lZZ1, idx, zz3):
        if idx + 1 >= len(lZZ1):
            return None
        p = lZZ1[idx]
        p1 = lZZ1[idx + 1]
        # Find next break
        for j in range(idx + 1, len(lZZ1)):
            if lZZ1[j][4] is not None:
                nxt = lZZ1[j]
                bSuc = (nxt[2] == zz3)
                dLen = abs(p1[1] - p[1])
                return (bSuc, dLen)
        return None

    print("\n=== Next break type ===")
    run_variant("I_same:next_brk,len_to_brk", 3, sig_same, outI)
    run_variant("I_opp:next_brk,len_to_brk", 3, sig_opp, outI)
    run_variant("J_same:next_brk,len_next_leg", 3, sig_same, outJ)

if __name__ == '__main__':
    main()
