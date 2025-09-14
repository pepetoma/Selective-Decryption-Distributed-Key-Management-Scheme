// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Groth16Verifier} from "../src/generated/Verifier.sol";

/// @notice circuits/build/demo/paillier_demo.proof.json を取り込み、公開入力なし（0件）で verify=true を確認するE2E
contract E2EVerifyTest {
    function testProofVerifiesTrue() public {
        Groth16Verifier v = new Groth16Verifier();

        // proof from circuits/build/demo/paillier_demo.proof.json
        uint256[2] memory a = [
            16071007847294853121833746844882049295258790701695526705917124475678382573070,
            14497997835018437472305937037748893900493154840488585294439185578216294440088
        ];

        // snarkjs の pi_b は [ [b00, b01], [b10, b11] ] 形式のため、EVM 向けに各ペアを [b01, b00] に入れ替える
        uint256[2][2] memory b = [
            [
                3046187812762548151318048941833486440579109467149069769306145177782570458921,
                13572312982275422053797934369339583734547836142161861822194854514439461426920
            ],
            [
                11443730856221177049052279556032092380677449482935990195591403947880882017377,
                20064120896971716947315285780118773902515184055380598423462903678893922387426
            ]
        ];

        uint256[2] memory c = [
            18601368719908723582993567395545369288345194241345706562740717067431021447229,
            14763031251257963177463642629585366517951264862534768937462120099135624769890
        ];

        // 公開信号: [n, g, c, h_m, circuitVersion, sessionID]
        uint256[6] memory pub = [
            uint256(7),
            uint256(8),
            uint256(22),
            uint256(6018413527099068561047958932369318610297162528491556075919075208700178480084),
            uint256(1),
            uint256(42)
        ];
        bool ok = v.verifyProof(a, b, c, pub);
        require(ok, "groth16 verify should be true");
    }
}
