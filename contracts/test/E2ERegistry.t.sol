// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {VerifierAdapter} from "../src/VerifierAdapter.sol";
import {VerifierRegistry} from "../src/VerifierRegistry.sol";
import {Groth16Verifier} from "../src/generated/Verifier.sol";

/// @notice snarkjs 生成の Groth16Verifier を IVerifier にアダプトするテスト用ラッパ（公開入力は [1] 固定）
contract VerifierWrapper is IVerifier {
    Groth16Verifier public immutable inner;
    constructor(address v) { inner = Groth16Verifier(v); }
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external view returns (bool r) {
        require(input.length == 6, "len");
        uint256[6] memory pub = [input[0], input[1], input[2], input[3], input[4], input[5]];
        return inner.verifyProof(a, b, c, pub);
    }
}

contract E2ERegistryTest {
    function _proofA() internal pure returns (uint256[2] memory a) {
        a = [
            uint256(16071007847294853121833746844882049295258790701695526705917124475678382573070),
            uint256(14497997835018437472305937037748893900493154840488585294439185578216294440088)
        ];
    }
    function _proofB() internal pure returns (uint256[2][2] memory b) {
        b = [
            [
                uint256(3046187812762548151318048941833486440579109467149069769306145177782570458921),
                uint256(13572312982275422053797934369339583734547836142161861822194854514439461426920)
            ],
            [
                uint256(11443730856221177049052279556032092380677449482935990195591403947880882017377),
                uint256(20064120896971716947315285780118773902515184055380598423462903678893922387426)
            ]
        ];
    }
    function _proofC() internal pure returns (uint256[2] memory c_) {
        c_ = [
            uint256(18601368719908723582993567395545369288345194241345706562740717067431021447229),
            uint256(14763031251257963177463642629585366517951264862534768937462120099135624769890)
        ];
    }
    function testRegistryE2ETrueAndConsume() public {
        // 1) 準備: 生成 Verifier とラッパ、Adapter、Registry
        Groth16Verifier v = new Groth16Verifier();
        VerifierWrapper w = new VerifierWrapper(address(v));
        VerifierAdapter adapter = new VerifierAdapter(address(w));
        VerifierRegistry reg = new VerifierRegistry();
        uint256 circuitVersion = 1;
        reg.setAdapter(circuitVersion, address(adapter));

        // 2) 証明（b の順序は EVM 向けに [b01,b00] に入れ替え済み）
        // 3) 公開入力（現状 proof はこれらにバインドされていないが Registry 側の管理は有効）
        uint256 n = 7;
        uint256 g = 8;
        uint256 c = 22;
        uint256 h_m = 6018413527099068561047958932369318610297162528491556075919075208700178480084;
        uint256 sessionID = 42;

        // 4) Registry 経由で検証成功し、sessionID が消費されること
        bool ok = reg.verifyAndConsume(n, g, c, h_m, circuitVersion, sessionID, _proofA(), _proofB(), _proofC());
        require(ok, "registry verify failed");
        require(reg.isSessionConsumed(sessionID), "session not consumed");
    }
}
