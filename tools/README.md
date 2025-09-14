# tools

本ディレクトリは Circom 回路のビルド・鍵生成・（任意で）証明生成・Solidity Verifier エクスポートまでを自動化する補助スクリプトを提供します。

## 前提
- `circom` と `snarkjs` が PATH 上に存在すること（推奨: 固定バージョンを利用）
- Powers of Tau（例: `powersOfTau28_hez_final_10.ptau`）ファイルをローカルに用意すること（`tools/ptau/` 配下。バイナリ自体はコミットしない）

## 主要スクリプト
- `tools/scripts/compile.js`:
  - Circom → R1CS/wasm → Groth16 setup（zkey/vkey）→ 任意で witness/proof → Verifier.sol の生成を一括実行
  - 生成物とハッシュ、公開入力順序（`[n,g,c,h_m,circuitVersion,sessionID]`）を `manifest.json` に記録

## 使い方（例）
```
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --name VerifierPaillierDemo \
  --copy contracts/src/generated/Verifier.sol

# 入力から witness と proof も作る場合
node tools/scripts/compile.js \
  --circuit circuits/paillier_demo.circom \
  --ptau tools/ptau/powersOfTau28_hez_final_10.ptau \
  --out circuits/build/demo \
  --input circuits/input.demo.json \
  --prove \
  --copy contracts/src/generated/Verifier.sol
```

## 出力
- `*.r1cs`, `*.wasm`, `*.zkey`, `*.vkey.json`, `Verifier*.sol`, `manifest.json`（ハッシュと公開入力順序を含む）

## ノート
- 証明体系は MVP として Groth16 固定（PLONK は将来拡張）
- バイナリ/ツールのバージョン固定は CI 側やドキュメントで指定予定
- `manifest.json` の `publicInputsOrder` は `ONCHAIN_VERIFY.md` のABI順序と一致させています

## コントラクトへの反映手順
1. 上記コマンドで `Verifier*.sol` を生成（`--name` でコントラクト名を指定可能）
2. 生成された `Verifier*.sol` を `contracts/src/generated/Verifier.sol` として差し替え
   - 例: `cp circuits/build/demo/VerifierPaillierDemo.sol contracts/src/generated/Verifier.sol`
3. `contracts/` で `forge build` もしくは `forge test` を実行しコンパイル確認
4. オンチェーン側は `VerifierRegistry.setAdapter(circuitVersion, address(new VerifierAdapter(<Verifierアドレス>)))` を実行して登録
