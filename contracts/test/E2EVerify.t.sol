// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Groth16Verifier} from "../src/generated/Verifier.sol";

/// @notice circuits/build/demo/paillier_demo.proof.json を取り込み、公開入力なし（0件）で verify=true を確認するE2E
contract E2EVerifyTest {
    function testProofVerifiesTrue() public {
        Groth16Verifier v = new Groth16Verifier();

        // proof from circuits/build/demo/paillier_demo.proof.json
        uint256[2] memory a = [
            4006906380904347991489452589655898393771542546264411605242441232362285950967,
            2600189403753367698212131798798266163348668627089579943703532375473481526410
        ];

        // snarkjs の pi_b は [ [b00, b01], [b10, b11] ] 形式のため、EVM 向けに各ペアを [b01, b00] に入れ替える
        uint256[2][2] memory b = [
            [
                20232134007489916393025539200503070125611338601079650333086791519321171076096,
                15925619721953089361381228318214903519647862411381685738175170376179157307376
            ],
            [
                11167605928619213362421875676279091923433795941318395992387265727687778340964,
                17546067819389265495040162515951594817364753860752699544707620786547480169885
            ]
        ];

        uint256[2] memory c = [
            13101509607053952476059658706198293752121223806019097678990985588789243877389,
            16360474096189712489886512939915109128110731165614327706393189339347047326582
        ];

        // 公開信号: ok = 1 のみ（snarkjs 生成Veriferは固定長配列）
        uint256[1] memory pub = [uint256(1)];
        bool ok = v.verifyProof(a, b, c, pub);
        require(ok, "groth16 verify should be true");
    }
}
