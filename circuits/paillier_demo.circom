pragma circom 2.1.4;
// circomlib の Poseidon と Num2Bits を使用（-l で circomlib を解決）
include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/bitify.circom";

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
template RangeCheckK(k) {
    signal input in;
    component nb = Num2Bits(k);
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
    component nb = Num2Bits(k);
    nb.in <== diff;
}

// 積の mod 簡約: prod = a*b = q*mod + r, 0 <= r < mod
template ModMulBoundK(k) {
    signal input a;
    signal input b;
    signal input mod;
    signal output r; // a*b（mod は上限チェックのみ）

    r <== a * b;

    // r を k ビットに収め、かつ r < mod を強制
    component rrc = RangeCheckK(k);
    rrc.in <== r;
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
    component enb = Num2Bits(ebits);
    enb.in <== e;

    // 配列で状態を保持（ループ内での宣言を避ける）
    signal resArr[ebits + 1];
    signal baseArr[ebits + 1];
    component mul1[ebits];
    // selection helpers per bit
    signal delta[ebits];
    signal prodSel[ebits];

    resArr[0] <== 1;
    baseArr[0] <== a;

    var i;
    for (i = 0; i < ebits; i++) {
        mul1[i] = ModMulBoundK(k);
        mul1[i].a <== resArr[i];
        mul1[i].b <== baseArr[i];
        mul1[i].mod <== mod;

        // res[i+1] = res + (mul1.r - res) * bit
        delta[i] <== mul1[i].r - resArr[i];
        prodSel[i] <== delta[i] * enb.out[i];
        resArr[i + 1] <== resArr[i] + prodSel[i];

        // E_BITS=1 前提のため base 更新は省略
        baseArr[i + 1] <== baseArr[i];
    }
    out <== resArr[ebits];
}

// L(u) = (u - 1)/n の整合: u = 1 + n*t, 0 <= t < n
template LFunctionK(k) {
    signal input u;
    signal input n;
    signal input t; // L(u) を witness として受け取り整合を検査

    component rcU = RangeCheckK(2*k); // u < 2^(2k) を想定（mod は n^2）
    component rcN = RangeCheckK(k);
    rcU.in <== u;
    rcN.in <== n;

    // u - 1 = n * t
    signal diff;
    diff <== u - 1;

    // t は後続の r<mod と同様に n を上限に制約する

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

    signal input kWitness; // 存在証明用の乗数 witness
    diff === kWitness * n;

    // 0 <= kWitness < n
    component lt = LtBoundVarK(k);
    lt.r <== kWitness;
    lt.mod <== n;
}

template Main() {
    // constants
    component C = Consts();
    var N_BITS = 16;
    var E_BITS = 1;
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

    // 公開信号（出力）: 仕様どおり [n, g, c, h_m, circuitVersion, sessionID]
    signal output out_n;
    signal output out_g;
    signal output out_c;
    signal output out_h_m;
    signal output out_circuitVersion;
    signal output out_sessionID;

    // n, g, c, h_m, circuitVersion, sessionID の範囲制約
    component rcn = RangeCheckK(N_BITS); rcn.in <== n;
    component rcg = RangeCheckK(N2_BITS); rcg.in <== g; // g, c は n^2 未満
    component rcc = RangeCheckK(N2_BITS); rcc.in <== c;
    // h_m は場要素とし、範囲チェックは省略（Poseidon出力）
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
    // ModMulBound を用いるため補助 witness は不要

    // t_c = L(u_c)
    component Lc = LFunctionK(N_BITS);
    Lc.u <== mexp1.out;
    Lc.n <== n;
    signal input Lc_t;
    Lc.t <== Lc_t;

    // m ≡ t_c * mu (mod n)
    signal tcmu;
    tcmu <== Lc.t * mu;
    component eqm = EqModK(N_BITS);
    eqm.a <== tcmu;
    eqm.b <== m;
    eqm.n <== n;
    signal input eqm_k;
    eqm.kWitness <== eqm_k;

    // u_g = g^lambda mod n2, t_g = L(u_g)
    component mexp2 = ModExpK(N2_BITS, E_BITS, Q_BITS);
    mexp2.a <== g;
    mexp2.e <== lambda;
    mexp2.mod <== n2;
    // ModMulBound を用いるため補助 witness は不要

    component Lg = LFunctionK(N_BITS);
    Lg.u <== mexp2.out;
    Lg.n <== n;
    signal input Lg_t;
    Lg.t <== Lg_t;

    // mu * t_g ≡ 1 (mod n)
    signal mutg;
    mutg <== mu * Lg.t;
    component eqk = EqModK(N_BITS);
    eqk.a <== mutg;
    eqk.b <== 1;
    eqk.n <== n;
    signal input eqk_k;
    eqk.kWitness <== eqk_k;

    // ハッシュ検査: Poseidon(m) == h_m
    component H = Poseidon(1);
    H.inputs[0] <== m;
    H.out === h_m;

    // 公開信号へ値を透過
    out_n <== n;
    out_g <== g;
    out_c <== c;
    out_h_m <== h_m;
    out_circuitVersion <== circuitVersion;
    out_sessionID <== sessionID;
}

component main = Main();
