circuits ディレクトリ
=====================

目的
- Circom 回路とサンプル入力を管理します。MVP では `paillier_demo.circom` を仮の骨格として用意しています。

構成
- `paillier_demo.circom`: 公開入力 `[n, g, c, h_m, circuitVersion, sessionID]` を受け取り、デモとして `ok=1` を出力する最小回路。
- `input.demo.json`: 生成・検証の動作確認用の最小入力。
- `build/`: `tools/scripts/compile.js` により生成される成果物の配置先。

ビルド例
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --name VerifierPaillierDemo
```

証明作成（任意）
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --input circuits/input.demo.json \
  --prove
```

Solidity への反映
- 生成された `VerifierPaillierDemo.sol` を `contracts/src/generated/Verifier.sol` に配置し、`forge build` / `forge test` で確認してください。

注意
- 本回路は骨格のみで、Paillier 復号や Poseidon などの制約は未実装です。Phase 1 の実装で順次拡張します。

