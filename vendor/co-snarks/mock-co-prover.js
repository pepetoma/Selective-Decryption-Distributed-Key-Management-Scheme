#!/usr/bin/env node
// Minimal stub: simulate coSNARK by calling snarkjs.groth16.fullProve
const fs = require('fs');
const path = require('path');
const snarkjs = require('snarkjs');

async function main() {
  const outDir = process.argv[2] || 'circuits/build/demo';
  const wasm = path.join(outDir, 'paillier_demo_js/paillier_demo.wasm');
  const zkey = path.join(outDir, 'paillier_demo.zkey');
  const input = JSON.parse(fs.readFileSync('circuits/input.demo.json', 'utf8'));
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, wasm, zkey);
  fs.writeFileSync(path.join(outDir, 'paillier_demo.proof.json'), JSON.stringify(proof));
  fs.writeFileSync(path.join(outDir, 'paillier_demo.public.json'), JSON.stringify(publicSignals));
  console.log('mock coProver: proof generated');
}

main().catch((e) => { console.error(e.stack || e.message); process.exit(1); });

