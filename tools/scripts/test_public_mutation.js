#!/usr/bin/env node
/*
 * 公開入力1bit改変テスト
 * - 元の公開入力で verify=true を確認
 * - 各要素を +1 (mod Fr) に変更して verify=false を確認
 */
const fs = require('fs');
const path = require('path');
const snarkjs = require('snarkjs');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      const k = argv[i].slice(2);
      const v = (argv[i + 1] && !argv[i + 1].startsWith('--')) ? argv[++i] : true;
      args[k] = v;
    }
  }
  return args;
}

function readJSON(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function toBigIntStr(x) {
  if (typeof x === 'string') return x;
  if (typeof x === 'number') return BigInt(x).toString();
  throw new Error('Unsupported public signal type');
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.vkey || !args.proof || !args.public) {
    console.error('Usage: node tools/scripts/test_public_mutation.js --vkey <vkey.json> --proof <proof.json> --public <public.json>');
    process.exit(2);
  }
  const vkey = readJSON(args.vkey);
  const proof = readJSON(args.proof);
  const pub = readJSON(args.public);
  let publicSignals = pub;
  if (pub && pub.length === undefined && pub.publicSignals) publicSignals = pub.publicSignals;
  if (!Array.isArray(publicSignals)) {
    console.error('publicSignals not found: expected array');
    process.exit(2);
  }

  // bn128 Fr modulus
  const Fr = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
  const sigStr = publicSignals.map(toBigIntStr);

  // 1) Original should verify true
  const ok = await snarkjs.groth16.verify(vkey, sigStr, proof);
  if (!ok) {
    console.error('Original verification failed (expected true).');
    process.exit(1);
  }

  // 2) Each index mutated should verify false
  let failures = 0;
  for (let i = 0; i < sigStr.length; i++) {
    const arr = sigStr.slice();
    const orig = BigInt(arr[i]);
    const mutated = (orig + 1n) % Fr; // flip by +1 mod Fr
    arr[i] = mutated.toString();
    const res = await snarkjs.groth16.verify(vkey, arr, proof);
    if (res) {
      console.error(`Mutation at index ${i} unexpectedly verified true.`);
      failures++;
    }
  }

  if (failures === 0) {
    console.log(`OK: original=true, and ${sigStr.length} single-index mutations all false.`);
    process.exit(0);
  } else {
    console.error(`FAIL: ${failures} mutated cases verified true.`);
    process.exit(1);
  }
}

main().catch((e) => { console.error(e.stack || e.message); process.exit(1); });

