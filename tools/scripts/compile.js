#!/usr/bin/env node
/*
 * ZK pipeline helper: circom -> r1cs -> key -> (optional) proof -> Verifier.sol
 * - Groth16 only (MVP)。将来 PLONK 等の拡張余地あり。
 * - 依存: `circom`, `snarkjs` が PATH に存在すること。
 * - 出力: ビルド成果物 + `manifest.json`（ハッシュ/順序/版情報）
 */
const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function sh(cmd, opts = {}) {
  const res = spawnSync(cmd, { shell: true, stdio: 'inherit', ...opts });
  if (res.status !== 0) {
    throw new Error(`Command failed: ${cmd}`);
  }
}

function which(bin) {
  try {
    const out = execSync(process.platform === 'win32' ? `where ${bin}` : `command -v ${bin}`, { stdio: 'pipe' });
    return out.toString().trim();
  } catch (_) {
    return null;
  }
}

function sha256File(p) {
  const h = crypto.createHash('sha256');
  h.update(fs.readFileSync(p));
  return h.digest('hex');
}

function ensureDir(d) {
  fs.mkdirSync(d, { recursive: true });
}

function writeJSON(p, obj) {
  fs.writeFileSync(p, JSON.stringify(obj, null, 2));
}

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.replace(/^--/, '');
      const val = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : true;
      args[key] = val;
    }
  }
  return args;
}

function main() {
  const args = parseArgs(process.argv);
  if (args.help || !args.circuit || !args.ptau) {
    console.log(`Usage: node tools/scripts/compile.js \
      --circuit circuits/example.circom \
      --ptau tools/ptau/powersOfTau28_hez_final_14.ptau \
      --out build/example \
      [--name VerifierExample] \
      [--input input.json] [--prove] [--force] \
      [--copy contracts/src/generated/Verifier.sol] \
      [--lib <dir>[,<dir2>...]]

    必須: --circuit, --ptau
    省略時: --out は circuit と同階層に build/<basename>
    `);
    process.exit(1);
  }

  // 前提チェック
  const circomBin = which('circom');
  const snarkjsBin = which('snarkjs');
  if (!circomBin) {
    console.error('circom が見つかりません。インストールして PATH を通してください。');
    process.exit(2);
  }
  if (!snarkjsBin) {
    console.error('snarkjs が見つかりません。`npm i -g snarkjs` などで導入してください。');
    process.exit(2);
  }

  const circuitPath = path.resolve(args.circuit);
  if (!fs.existsSync(circuitPath)) {
    console.error(`circuit が見つかりません: ${circuitPath}`);
    process.exit(2);
  }
  const ptauPath = path.resolve(args.ptau);
  if (!fs.existsSync(ptauPath)) {
    console.error(`ptau が見つかりません: ${ptauPath}`);
    process.exit(2);
  }

  const base = path.basename(circuitPath, path.extname(circuitPath));
  const outDir = path.resolve(args.out || path.join(path.dirname(circuitPath), 'build', base));
  const name = args.name || `Verifier_${base}`;
  const force = !!args.force;
  const copyDest = args.copy ? path.resolve(args.copy) : null;
  const libDirsRaw = args.lib ? (Array.isArray(args.lib) ? args.lib : [args.lib]) : [];
  const libDirs = libDirsRaw.flatMap(s => s.split(',')).map(s => s.trim()).filter(Boolean);
  ensureDir(outDir);

  const r1cs = path.join(outDir, `${base}.r1cs`);
  let wasm = path.join(outDir, `${base}.wasm`); // circom v1 style
  const zkey = path.join(outDir, `${base}.zkey`);
  const vkey = path.join(outDir, `${base}.vkey.json`);
  const verifier = path.join(outDir, `${name}.sol`);
  const witness = path.join(outDir, `${base}.witness.wtns`);
  const proof = path.join(outDir, `${base}.proof.json`);
  const publicSignals = path.join(outDir, `${base}.public.json`);

  // 1) circom compile
  if (!fs.existsSync(r1cs) || force) {
    console.log('==> Compile circom to r1cs/wasm');
    const libFlags = libDirs.length ? libDirs.map(d => `-l ${d}`).join(' ') : '';
    sh(`circom ${circuitPath} --r1cs --wasm -o ${outDir} ${libFlags}`);
  } else {
    console.log('skip circom compile (found cache)');
  }

  // Resolve wasm path for circom v2 (base_js/base.wasm) if needed
  const wasmV2 = path.join(outDir, `${base}_js`, `${base}.wasm`);
  if (fs.existsSync(wasmV2)) {
    wasm = wasmV2;
  }

  // 2) groth16 setup
  if (!fs.existsSync(zkey) || !fs.existsSync(vkey) || force) {
    console.log('==> Groth16 setup');
    sh(`snarkjs groth16 setup ${r1cs} ${ptauPath} ${zkey}`);
    sh(`snarkjs zkey export verificationkey ${zkey} ${vkey}`);
  } else {
    console.log('skip groth16 setup (found cache)');
  }

  // 3) optional witness + prove
  if (args.input) {
    const input = path.resolve(args.input);
    if (!fs.existsSync(input)) {
      console.error(`input が見つかりません: ${input}`);
      process.exit(2);
    }
    console.log('==> Calculate witness');
    // snarkjs wtns calculate <wasm> <input.json> <witness.wtns>
    sh(`snarkjs wtns calculate ${wasm} ${input} ${witness}`);
  }
  if (args.prove) {
    if (!fs.existsSync(witness)) {
      console.error('prove 指定には witness が必要です。--input で input.json を指定してください。');
      process.exit(2);
    }
    console.log('==> Prove');
    sh(`snarkjs groth16 prove ${zkey} ${witness} ${proof} ${publicSignals}`);
  }

  // 4) export solidity verifier
  if (!fs.existsSync(verifier) || force) {
    console.log('==> Export Solidity Verifier');
    try {
      sh(`snarkjs zkey export solidityverifier ${zkey} ${verifier} --name ${name}`);
    } catch (e) {
      console.log('fallback: export solidityverifier without --name');
      sh(`snarkjs zkey export solidityverifier ${zkey} ${verifier}`);
    }
  } else {
    console.log('skip export verifier (found cache)');
  }

  // 4.5) optional copy to contracts
  if (copyDest) {
    ensureDir(path.dirname(copyDest));
    fs.copyFileSync(verifier, copyDest);
    console.log('==> Copied Verifier to', copyDest);
  }

  // 5) manifest
  console.log('==> Write manifest.json');
  const manifest = {
    circuit: path.relative(process.cwd(), circuitPath),
    ptau: path.relative(process.cwd(), ptauPath),
    outputs: {
      r1cs: path.relative(process.cwd(), r1cs),
      wasm: path.relative(process.cwd(), wasm),
      zkey: path.relative(process.cwd(), zkey),
      vkey: path.relative(process.cwd(), vkey),
      verifier: path.relative(process.cwd(), verifier),
      witness: fs.existsSync(witness) ? path.relative(process.cwd(), witness) : null,
      proof: fs.existsSync(proof) ? path.relative(process.cwd(), proof) : null,
      publicSignals: fs.existsSync(publicSignals) ? path.relative(process.cwd(), publicSignals) : null,
    },
    hashes: {
      circuit_sha256: sha256File(circuitPath),
      ptau_sha256: sha256File(ptauPath),
      r1cs_sha256: fs.existsSync(r1cs) ? sha256File(r1cs) : null,
      zkey_sha256: fs.existsSync(zkey) ? sha256File(zkey) : null,
      verifier_sha256: fs.existsSync(verifier) ? sha256File(verifier) : null,
    },
    publicInputsOrder: [
      'n', 'g', 'c', 'h_m', 'circuitVersion', 'sessionID'
    ],
    proofSystem: 'groth16',
    createdAt: new Date().toISOString(),
  };
  writeJSON(path.join(outDir, 'manifest.json'), manifest);

  console.log('\nDone. Manifest at:', path.join(outDir, 'manifest.json'));
}

if (require.main === module) {
  try { main(); } catch (e) { console.error(e.message); process.exit(1); }
}
