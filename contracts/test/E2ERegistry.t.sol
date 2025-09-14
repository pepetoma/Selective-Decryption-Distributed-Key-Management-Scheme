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
        uint256[] calldata /*input*/
    ) external view returns (bool r) {
        uint256[1] memory pub = [uint256(1)];
        return inner.verifyProof(a, b, c, pub);
    }
}

contract E2ERegistryTest {
    function _proofA() internal pure returns (uint256[2] memory a) {
        a = [
            uint256(4006906380904347991489452589655898393771542546264411605242441232362285950967),
            uint256(2600189403753367698212131798798266163348668627089579943703532375473481526410)
        ];
    }
    function _proofB() internal pure returns (uint256[2][2] memory b) {
        b = [
            [
                uint256(20232134007489916393025539200503070125611338601079650333086791519321171076096),
                uint256(15925619721953089361381228318214903519647862411381685738175170376179157307376)
            ],
            [
                uint256(11167605928619213362421875676279091923433795941318395992387265727687778340964),
                uint256(17546067819389265495040162515951594817364753860752699544707620786547480169885)
            ]
        ];
    }
    function _proofC() internal pure returns (uint256[2] memory c_) {
        c_ = [
            uint256(13101509607053952476059658706198293752121223806019097678990985588789243877389),
            uint256(16360474096189712489886512939915109128110731165614327706393189339347047326582)
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
