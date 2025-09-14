// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {VerifierAdapter} from "../src/VerifierAdapter.sol";
import {VerifierRegistry} from "../src/VerifierRegistry.sol";

contract MockVerifier is IVerifier {
    uint256[6] public expected;

    function setExpected(
        uint256 n,
        uint256 g,
        uint256 c,
        uint256 h_m,
        uint256 circuitVersion,
        uint256 sessionID
    ) external {
        expected = [n, g, c, h_m, circuitVersion, sessionID];
    }

    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[] calldata input
    ) external view returns (bool r) {
        require(input.length == 6, "bad len");
        for (uint256 i = 0; i < 6; i++) {
            require(input[i] == expected[i], "bad order");
        }
        return true;
    }
}

contract VerifierRegistryTest {
    function _setup(uint256 circuitVersion)
        internal
        returns (VerifierRegistry registry, MockVerifier mv)
    {
        registry = new VerifierRegistry();
        mv = new MockVerifier();
        VerifierAdapter adapter = new VerifierAdapter(address(mv));
        registry.setAdapter(circuitVersion, address(adapter));
    }

    function testVerifyAndConsumeAndReplay() public {
        (VerifierRegistry registry, MockVerifier mv) = _setup(1);
        // 入力例
        uint256 n = 11;
        uint256 g = 22;
        uint256 c = 33;
        uint256 h_m = 44;
        uint256 circuitVersion = 1;
        uint256 sessionID = 77;
        mv.setExpected(n, g, c, h_m, circuitVersion, sessionID);

        uint256[2] memory a = [uint256(0), uint256(0)];
        uint256[2][2] memory b = [[uint256(0), uint256(0)], [uint256(0), uint256(0)]];
        uint256[2] memory c_ = [uint256(0), uint256(0)];

        // 1回目は成功
        bool ok = registry.verifyAndConsume(n, g, c, h_m, circuitVersion, sessionID, a, b, c_);
        require(ok, "first verify failed");
        require(registry.isSessionConsumed(sessionID), "not consumed");

        // 2回目は revert（try-catch で確認）
        try registry.verifyAndConsume(n, g, c, h_m, circuitVersion, sessionID, a, b, c_) {
            revert("replay should revert");
        } catch {}
    }

    // 未登録 circuitVersion は revert を期待（try-catch で確認）
    function testUnregisteredVersionReverts() public {
        VerifierRegistry registry = new VerifierRegistry();
        uint256[2] memory a = [uint256(0), uint256(0)];
        uint256[2][2] memory b = [[uint256(0), uint256(0)], [uint256(0), uint256(0)]];
        uint256[2] memory c_ = [uint256(0), uint256(0)];

        try registry.verifyAndConsume(1, 2, 3, 4, 999, 6, a, b, c_) {
            revert("should revert");
        } catch {}
    }
}
