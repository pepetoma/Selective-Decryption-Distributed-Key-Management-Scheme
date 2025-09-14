ptau ファイル配置ガイド
=======================

概要
- Groth16 セットアップに必要な Powers of Tau（例: `powersOfTau28_hez_final_10.ptau`）をこのディレクトリに配置してください。
- セキュリティと容量の観点から ptau バイナリはリポジトリにコミットしないでください。

取得方法（例）
- 公式配布（iden3/snarkjs のリリースや信頼できるミラー）からダウンロード
- あるいはローカルで ceremony 生成（推奨は既存の well-known ptau を使用）

配置例
```
tools/ptau/powersOfTau28_hez_final_10.ptau
```

使い方
- `tools/scripts/compile.js` の `--ptau` 引数に上記ファイルパスを渡してください。

