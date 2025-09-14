use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::process::Command;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("utf8: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),
    #[error("serde: {0}")]
    Serde(#[from] serde_json::Error),
    #[error("script failed: {0}")]
    Script(String),
}

pub type Result<T> = std::result::Result<T, Error>;

// --- Demo types ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaillierDemoInput {
    pub n: u64,
    pub g: u64,
    pub c: u64,
    pub h_m: String,
    pub circuitVersion: u64,
    pub sessionID: u64,
    pub lambda: u64,
    pub mu: u64,
    pub m: u64,
    pub Lc_t: u64,
    pub Lg_t: u64,
    pub eqm_k: u64,
    pub eqk_k: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProveResult {
    pub out_dir: PathBuf,
    pub proof: PathBuf,
    pub public_json: PathBuf,
    pub vkey_json: PathBuf,
    pub verifier_sol: PathBuf,
}

/// 簡易に Node スクリプトを実行し、失敗時は標準出力/エラーを含むメッセージを返す
fn run(cmd: &str, cwd: Option<&Path>) -> Result<()> {
    let mut c = Command::new("bash");
    c.arg("-lc").arg(cmd);
    if let Some(d) = cwd { c.current_dir(d); }
    let out = c.output()?;
    if !out.status.success() {
        return Err(Error::Script(format!(
            "cmd failed: {}\nstdout:\n{}\nstderr:\n{}",
            cmd,
            String::from_utf8(out.stdout)?,
            String::from_utf8(out.stderr)?,
        )));
    }
    Ok(())
}

/// Circom/snarkjs パイプラインを呼び出して proof を作成
pub fn prove_demo_with_tools(input: &PaillierDemoInput) -> Result<ProveResult> {
    let repo_root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().to_path_buf();
    let circuits = repo_root.join("circuits");
    let tools = repo_root.join("tools");
    let out_dir = circuits.join("build/demo");
    let circuit = circuits.join("paillier_demo.circom");
    let ptau = tools.join("ptau/powersOfTau28_hez_final_14.ptau");
    let input_path = circuits.join("input.demo.json");

    // 入力をファイルに書き出す（上書き）
    std::fs::write(&input_path, serde_json::to_vec_pretty(input)?)?;

    let script = format!(
        "PATH=$PWD/tools/bin:$PWD/node_modules/.bin:$PATH node tools/scripts/compile.js \
          --circuit {} \
          --ptau {} \
          --out {} \
          --input {} \
          --prove \
          --name VerifierPaillierDemo \
          --copy contracts/src/generated/Verifier.sol \
          --lib node_modules",
        shell_escape::escape(circuit.to_string_lossy()),
        shell_escape::escape(ptau.to_string_lossy()),
        shell_escape::escape(out_dir.to_string_lossy()),
        shell_escape::escape(input_path.to_string_lossy()),
    );
    run(&script, Some(&repo_root))?;

    Ok(ProveResult {
        out_dir: out_dir.clone(),
        proof: out_dir.join("paillier_demo.proof.json"),
        public_json: out_dir.join("paillier_demo.public.json"),
        vkey_json: out_dir.join("paillier_demo.vkey.json"),
        verifier_sol: out_dir.join("VerifierPaillierDemo.sol"),
    })
}

/// オフチェーン検証（snarkjs groth16.verify）
pub fn verify_offchain(vkey: &Path, proof: &Path, public_json: &Path) -> Result<()> {
    let repo_root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().to_path_buf();
    let cmd = format!(
        "node tools/scripts/test_public_mutation.js --vkey {} --proof {} --public {}",
        shell_escape::escape(vkey.to_string_lossy()),
        shell_escape::escape(proof.to_string_lossy()),
        shell_escape::escape(public_json.to_string_lossy()),
    );
    run(&cmd, Some(&repo_root))
}

/// 共同証明 I/F（MVP: スタブ）
pub mod mpc {
    /// 将来 coSNARK 実装と差し替える想定のスタブ I/F
    pub trait CoProver {
        /// witness を参加者に分割し、合同に proof を生成
        fn co_prove(&self) -> anyhow::Result<()>;
    }

    /// ダミー実装（単一者での実行）
    pub struct SinglePartyProver;
    impl CoProver for SinglePartyProver {
        fn co_prove(&self) -> anyhow::Result<()> { Ok(()) }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn e2e_demo_prove_and_verify() -> Result<()> {
        // Circuits のデモ値と整合
        let input = PaillierDemoInput {
            n: 7, g: 8, c: 22,
            h_m: "6018413527099068561047958932369318610297162528491556075919075208700178480084".to_string(),
            circuitVersion: 1, sessionID: 42,
            lambda: 1, mu: 1, m: 3,
            Lc_t: 3, Lg_t: 1, eqm_k: 0, eqk_k: 0,
        };
        let res = prove_demo_with_tools(&input)?;
        verify_offchain(&res.vkey_json, &res.proof, &res.public_json)?;
        Ok(())
    }
}

