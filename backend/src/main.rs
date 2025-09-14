use clap::Parser;
use sddkm_lib::{prove_demo_with_tools, verify_offchain, PaillierDemoInput};

#[derive(Parser, Debug)]
#[command(name = "sddkm-demo")] 
#[command(about = "Selective decryption + proof E2E demo", long_about = None)]
struct Args {
    /// Run end-to-end proof generation and verification
    #[arg(long, default_value_t = true)]
    e2e: bool,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let _args = Args::parse();

    // fixed demo input; could be parameterized later
    let input = PaillierDemoInput {
        n: 7, g: 8, c: 22,
        h_m: "6018413527099068561047958932369318610297162528491556075919075208700178480084".to_string(),
        circuitVersion: 1, sessionID: 42,
        lambda: 1, mu: 1, m: 3,
        Lc_t: 3, Lg_t: 1, eqm_k: 0, eqk_k: 0,
    };
    let res = prove_demo_with_tools(&input)?;
    verify_offchain(&res.vkey_json, &res.proof, &res.public_json)?;
    println!("E2E OK: proof verified true. public={} proof={}", res.public_json.display(), res.proof.display());
    Ok(())
}

