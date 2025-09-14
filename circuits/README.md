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
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --name VerifierPaillierDemo \
  --copy contracts/src/generated/Verifier.sol \
  --lib node_modules
```

証明作成（任意）
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --input circuits/input.demo.json \
  --prove \
  --copy contracts/src/generated/Verifier.sol \
  --lib node_modules
```

Solidity への反映
- 生成された `VerifierPaillierDemo.sol` を `contracts/src/generated/Verifier.sol` に配置（`--copy` を使用可能）し、`forge build` / `forge test` で確認してください。

注意
- 小ビット長MVPです。`Poseidon(m)=h_m` は将来置換（現状は恒等 `h_m == m`）。Phase 1 にてハッシュ・大整数最適化を拡張します。
