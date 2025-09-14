co-snarks (stub)
================

目的
- 将来の共同証明（coSNARK/coCircom）統合ポイント。
- MVP では I/F のみ定義し、実装は単一者（snarkjs）で代用します。

含まれるもの
- `mock-co-prover.js`: witness 分割 I/Fに見せかけて単一者で snarkjs 証明を生成するスタブ。

今後
- 実体の coCircom/co-snarks を vendor として取り込み、`sddkm-lib` の `mpc::CoProver` 実装を差し替える。

