circuits ディレクトリ
=====================

目的
- Circom 回路とサンプル入力を管理します。MVP では `paillier_demo.circom` を仮の骨格として用意しています。

構成
- `paillier_demo.circom`: 公開入力 `[n, g, c, h_m, circuitVersion, sessionID]` と秘密入力 `[lambda, mu, m]` を受け取り、Paillier復号の整合（小ビット長・MVP）を検査します。
- `input.demo.json`: 生成・検証の動作確認用の最小入力（`n=7, g=8, c=22, lambda=1, mu=1, m=3, h_m=3`）。
- `build/`: `tools/scripts/compile.js` により生成される成果物の配置先。

ビルド例
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_14.ptau \
  --out circuits/build/demo \
  --name VerifierPaillierDemo \
  --copy contracts/src/generated/Verifier.sol \
  --lib node_modules
```

証明作成（任意）
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_14.ptau \
  --out circuits/build/demo \
  --input circuits/input.demo.json \
  --prove \
  --copy contracts/src/generated/Verifier.sol \
  --lib node_modules
```

Solidity への反映
- 生成された `VerifierPaillierDemo.sol` を `contracts/src/generated/Verifier.sol` に配置（`--copy` を使用可能）し、`forge build` / `forge test` で確認してください。

注意
- 小ビット長MVPです。乗算・mod簡約は最小の整合検査のみで、最適化や厳密化は今後の段階で拡張します。
- snarkjs の入力（特に `h_m` のような大きな値）は 64bit を超えるため、JSON では必ず文字列で指定してください（例: `"h_m": "12345..."`）。
