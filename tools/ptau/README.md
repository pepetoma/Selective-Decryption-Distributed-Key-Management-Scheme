ptau ファイル配置ガイド
=======================

概要
- Groth16 セットアップに必要な Powers of Tau（推奨: `powersOfTau28_hez_final_14.ptau`。例: `..._10.ptau` でも可）をこのディレクトリに配置してください。
- セキュリティと容量の観点から ptau バイナリはリポジトリにコミットしないでください。

.gitignore への追記を推奨
- 理由: ptau ファイルは非常に大きく（数十〜数百MB）、誤ってコミットするとリポジトリが肥大化します。さらに、ビルド生成物は一般にバージョン管理の対象外とするのがベストプラクティスです。README に追記しておくと、開発者がローカルで適切に無視設定を行いやすくなります。
- 推奨エントリ例（リポジトリルートの .gitignore に追加してください）:
  ```
  # Ignore Powers of Tau binaries stored under tools/ptau
  /tools/ptau/*.ptau
  /tools/ptau/*.ptau.*

  # Keep the README in the ptau directory tracked
  !/tools/ptau/README.md
  ```

取得方法（例）
- 公式配布（iden3/snarkjs のリリースや信頼できるミラー）からダウンロード
- あるいはローカルで ceremony 生成（推奨は既存の well-known ptau を使用）

配置例
```
tools/ptau/powersOfTau28_hez_final_14.ptau
```

使い方
- `tools/scripts/compile.js` の `--ptau` 引数に上記ファイルパスを渡してください。
