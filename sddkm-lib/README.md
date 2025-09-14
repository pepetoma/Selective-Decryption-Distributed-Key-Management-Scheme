SDDKM Library (Rust)
====================

目的
- 選択的復号 API（MVP: 小ビット長 Paillier デモ）
- 共同証明 I/F（coSNARK）に相当する最小 I/F（MVP: 単一者での snarkjs ラップ）
- オフチェーン検証 I/F（snarkjs/groth16.verify の実行）

現状（MVP）
- Circom 回路と `tools/scripts/compile.js` を Rust から呼び出し、witness/proof/public の生成・検証を行います。
- 「共同証明」は `vendor/co-snarks` のスタブ I/F で定義のみ（将来、実装を差し替え可能）。

使い方（例）
- ライブラリテストで E2E を実行: `cargo test -p sddkm-lib --all-features`
- ルートで: `cargo test --all-features`

