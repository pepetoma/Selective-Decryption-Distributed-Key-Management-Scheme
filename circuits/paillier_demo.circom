pragma circom 2.1.4;
// circomlib の Poseidon を使用（compile 時に -l <path> で circomlib を解決すること）
include "circomlib/circuits/poseidon.circom";

// Paillier 復号検証（小ビット長MVP）。
// 公開入力: [n, g, c, h_m, circuitVersion, sessionID]
// 秘密入力: [lambda, mu, m]
// 成立条件（小ビット長での近似）:
//  - u_c = c^lambda mod n^2, L(u_c) = (u_c - 1)/n = t_c with 0 <= t_c < n
//  - m ≡ t_c * mu (mod n)
//  - u_g = g^lambda mod n^2, L(u_g) = t_g,  mu * t_g ≡ 1 (mod n)
//  - ハッシュはMVPでは恒等: h_m == m （将来Poseidonへ置換）

// 定数（MVP）: 小ビット長で動作確認
// n < 2^N_BITS, n^2 < 2^(2*N_BITS)
// lambda, mu, m も N_BITS 程度
template Consts() {
    signal output N_BITS;      N_BITS <-- 16;   // 16bit
    signal output E_BITS;      E_BITS <-- 16;   // exponent bits
    signal output N2_BITS;     N2_BITS <-- 32;  // 2*N_BITS
    signal output Q_BITS;      Q_BITS <-- 32;   // quotient bits for mul/reduce
}

// --- 基本ガジェット ---
template Num2BitsK(k) {
    // value を kビットに分解
    signal input in;
    signal output bits[k];
    var i;
    var accPow = 1;
    var TWO = 2;
    var sum = 0;
    for (i = 0; i < k; i++) {
        // boolean constraint
        bits[i] * (bits[i] - 1) === 0;
        sum += bits[i] * accPow;
        accPow *= TWO;
    }
    in === sum;
}

template RangeCheckK(k) {
    signal input in;
    component nb = Num2BitsK(k);
    nb.in <== in;
}

// r < mod を保証する: 両者を k ビットに制限し、(mod - 1 - r) を k ビットに分解
template LtBoundVarK(k) {
    signal input r;
    signal input mod;
    component rcR = RangeCheckK(k);
    component rcM = RangeCheckK(k);
    rcR.in <== r;
    rcM.in <== mod;
    // diff = mod - 1 - r >= 0 かつ < 2^k
    signal diff;
    diff <== mod - 1 - r;
    component nb = Num2BitsK(k);
    nb.in <== diff;
}

// 積の mod 簡約: prod = a*b = q*mod + r, 0 <= r < mod
template ModReduceMulK(k, qbits) {
    signal input a;
    signal input b;
    signal input mod;
    signal output r; // a*b mod mod

    signal prod;
    prod <== a * b;

    // q, r をビット分解
    component qnb = Num2BitsK(qbits);
    component rnb = Num2BitsK(k);
    signal q;
    q <== qnb.in;
    r <== rnb.in;

    // 再構成: prod = q*mod + r
    prod === q * mod + r;

    // r < mod を強制
    component lt = LtBoundVarK(k);
    lt.r <== r;
    lt.mod <== mod;
}

// 繰り返し二乗法による a^e mod mod
template ModExpK(k, ebits, qbits) {
    signal input a;
    signal input e;     // ebits に制限
    signal input mod;   // k ビット
    signal output out;

    // 範囲チェック
    component rcA = RangeCheckK(k);
    component rcM = RangeCheckK(k);
    component rcE = RangeCheckK(ebits);
    rcA.in <== a;
    rcM.in <== mod;
    rcE.in <== e;

    // e のビット
    component enb = Num2BitsK(ebits);
    enb.in <== e;

    signal base;
    signal res;
    res <== 1;
    base <== a;

    var i;
    for (i = 0; i < ebits; i++) {
        // if enb.bits[i] == 1 then res = res*base mod mod
        component mul1 = ModReduceMulK(k, qbits);
        mul1.a <== res;
        mul1.b <== base;
        mul1.mod <== mod;

        signal resNext;
        // resNext = enb.bits[i] ? mul1.r : res
        resNext <== mul1.r * enb.bits[i] + res * (1 - enb.bits[i]);
        res <== resNext;

        // base = base*base mod mod
        component sq = ModReduceMulK(k, qbits);
        sq.a <== base;
        sq.b <== base;
        sq.mod <== mod;
        base <== sq.r;
    }
    out <== res;
}

// L(u) = (u - 1)/n の整合: u = 1 + n*t, 0 <= t < n
template LFunctionK(k) {
    signal input u;
    signal input n;
    signal output t; // L(u)

    component rcU = RangeCheckK(2*k); // u < 2^(2k) を想定（mod は n^2）
    component rcN = RangeCheckK(k);
    rcU.in <== u;
    rcN.in <== n;

    // u - 1 = n * t
    signal diff;
    diff <== u - 1;

    // t を k ビットに制限
    component tnb = Num2BitsK(k);
    t <== tnb.in;

    diff === n * t;

    // 0 <= t < n を強制
    component lt = LtBoundVarK(k);
    lt.r <== t;
    lt.mod <== n;
}

// a ≡ b (mod n): a - b = k*n, 0 <= k < n
template EqModK(k) {
    signal input a;
    signal input b;
    signal input n;

    signal diff;
    diff <== a - b;

    component knb = Num2BitsK(k);
    signal kk;
    kk <== knb.in;

    diff === kk * n;

    // 0 <= kk < n
    component lt = LtBoundVarK(k);
    lt.r <== kk;
    lt.mod <== n;
}

template Main() {
    // constants
    component C = Consts();
    var N_BITS = 16;
    var E_BITS = 16;
    var N2_BITS = 32;
    var Q_BITS = 32;

    // public inputs
    signal input n;
    signal input g;
    signal input c;
    signal input h_m;
    signal input circuitVersion;
    signal input sessionID;

    // witnesses
    signal input lambda;
    signal input mu;
    signal input m;

    // 出力
    signal output ok;

    // n, g, c, h_m, circuitVersion, sessionID の範囲制約
    component rcn = RangeCheckK(N_BITS); rcn.in <== n;
    component rcg = RangeCheckK(N2_BITS); rcg.in <== g; // g, c は n^2 未満
    component rcc = RangeCheckK(N2_BITS); rcc.in <== c;
    component rch = RangeCheckK(N_BITS); rch.in <== h_m;
    component rcver = RangeCheckK(32); rcver.in <== circuitVersion;
    component rcsid = RangeCheckK(64); rcsid.in <== sessionID;
    component rcm = RangeCheckK(N_BITS); rcm.in <== m;

    // n2 = n*n （範囲チェックのみ）
    signal n2;
    n2 <== n * n;
    component rcn2 = RangeCheckK(N2_BITS); rcn2.in <== n2;

    // u_c = c^lambda mod n2
    component mexp1 = ModExpK(N2_BITS, E_BITS, Q_BITS);
    mexp1.a <== c;
    mexp1.e <== lambda;
    mexp1.mod <== n2;

    // t_c = L(u_c)
    component Lc = LFunctionK(N_BITS);
    Lc.u <== mexp1.out;
    Lc.n <== n;

    // m ≡ t_c * mu (mod n)
    signal tcmu;
    tcmu <== Lc.t * mu;
    component eqm = EqModK(N_BITS);
    eqm.a <== tcmu;
    eqm.b <== m;
    eqm.n <== n;

    // u_g = g^lambda mod n2, t_g = L(u_g)
    component mexp2 = ModExpK(N2_BITS, E_BITS, Q_BITS);
    mexp2.a <== g;
    mexp2.e <== lambda;
    mexp2.mod <== n2;

    component Lg = LFunctionK(N_BITS);
    Lg.u <== mexp2.out;
    Lg.n <== n;

    // mu * t_g ≡ 1 (mod n)
    signal mutg;
    mutg <== mu * Lg.t;
    component eqk = EqModK(N_BITS);
    eqk.a <== mutg;
    eqk.b <== 1;
    eqk.n <== n;

    // ハッシュ検査: Poseidon(m) == h_m
    component H = Poseidon(1);
    H.inputs[0] <== m;
    H.out === h_m;

    // 全条件を満たすなら ok=1 とする（恒等チェック）
    ok <== 1;
}

component main = Main();
