# Selective-Decryption-Distributed-Key-Management-Scheme

最小E2E（proof → on-chain verify=true）を最短で通すMVP。

追加（MVP充足のための構成）
- sddkm-lib（Rust）: 選択的復号APIと共同証明I/F（スタブ）、オフチェーン検証I/Fを提供
- backend（Rust CLI）: デモ用に E2E（proof生成→検証）を1コマンドで実行
- vendor/co-snarks（スタブ）: 共同証明の統合ポイント（現状は単一者で snarkjs を呼び出すモック）

クイックスタート（ローカル）
- 依存: Node.js, Foundry(forge), circom/snarkjs（同梱スクリプトでPATH補完済み）, ptauは`tools/ptau`同梱
- 1行でE2E: `npm run e2e`
- Rust側E2E（ライブラリ＋CLI）: `cargo test --all-features` / `cargo run -p sddkm-backend -- --e2e`
- 個別実行: `npm run build:proof` → `npm run test:public-mutation` → `npm run test:contracts`

メモ
- 公開入力順序は `[n, g, c, h_m, circuitVersion, sessionID]`
- Circom回路/ビルド: `tools/scripts/compile.js`（manifest出力、Verifier.sol生成とコピー対応）
- 公開入力1bit改変テスト: `tools/scripts/test_public_mutation.js`

メモ（共同証明/coSNARK）
- MVPでは `vendor/co-snarks` にスタブ実装を置き、将来 coCircom を取り込み `sddkm-lib::mpc::CoProver` 実装を差し替えます。
