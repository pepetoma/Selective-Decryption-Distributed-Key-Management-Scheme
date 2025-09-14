# AGENTS.md

本リポジトリでエージェント（自動化ツール/AI）が作業する際のガイドラインです。

## コミットメッセージ運用
- 日本語で記述してください（技術用語・識別子は英語可）。
- タイトルは 50文字程度、本文は箇条書きで要点を簡潔に。
- 重要: 改行は文字列の `\n` ではなく「複数の `-m`」または `-F` を使って渡してください。
  - 例: `git commit -m "feat: タイトル" -m "- 変更点1\n- 変更点2"`
  - あるいは: `git commit -F COMMIT_MSG.txt`（本文をファイルで渡す）
- 1コミット=1責務（小さく、ロールバック容易に）。

## 生成物と大容量ファイル
- `node_modules/`、`tools/ptau/*.ptau`、`circuits/**/build/`（r1cs/wasm/zkey/wtns/proof/public/manifest）等はコミットしない（.gitignore 済）。
- `contracts/src/generated/Verifier.sol` は生成物。必要時は `tools/scripts/compile.js --copy` で再生成してください。

## テスト/ビルド
- Solidity: `cd contracts && forge test -vvv` を実行し、失敗したテストのみを修正対象とする。
- Circom/snarkjs: tools のスクリプト（compile.js / test_public_mutation.js）を使用し、公開入力改変で verify=false を確認する。

## ドキュメント更新
- 実装に影響する仕様変更時は `CIRCUITS_SPEC.md` / `ONCHAIN_VERIFY.md` / `MPC_FLOW.md` も同期。差異が出ないよう注意する。

## セキュリティ/方針
- 本番鍵・秘密値のコミット禁止。CORS の全許可など危険設定は導入しない。


