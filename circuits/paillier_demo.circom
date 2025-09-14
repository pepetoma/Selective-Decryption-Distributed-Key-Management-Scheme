pragma circom 2.1.4;

// 最小スケルトン回路（MVPデモ用）
// 公開入力: [n, g, c, h_m, circuitVersion, sessionID]
// ここでは Paillier 復号や Poseidon 検査は未実装（骨格のみ）。

template Main() {
    // public inputs
    signal input n;
    signal input g;
    signal input c;
    signal input h_m;
    signal input circuitVersion;
    signal input sessionID;

    // output: デモのため常に 1 を出力
    signal output ok;
    ok <== 1;
}

component main = Main();

