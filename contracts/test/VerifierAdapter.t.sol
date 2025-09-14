// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVerifier6} from "../src/interfaces/IVerifier6.sol";
import {VerifierAdapter} from "../src/VerifierAdapter.sol";

contract MockVerifier is IVerifier6 {
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
        uint256[6] calldata input
    ) external view returns (bool r) {
        for (uint256 i = 0; i < 6; i++) {
            require(input[i] == expected[i], "bad order");
        }
        return true;
    }
}

contract VerifierAdapterTest {
    function testOrderFixed() public {
        MockVerifier mv = new MockVerifier();
        VerifierAdapter adapter = new VerifierAdapter(address(mv));

        // 入力例
        uint256 n = 1;
        uint256 g = 2;
        uint256 c = 3;
        uint256 h_m = 4;
        uint256 circuitVersion = 5;
        uint256 sessionID = 6;
        mv.setExpected(n, g, c, h_m, circuitVersion, sessionID);

        uint256[2] memory a = [uint256(0), uint256(0)];
        uint256[2][2] memory b = [[uint256(0), uint256(0)], [uint256(0), uint256(0)]];
        uint256[2] memory c_ = [uint256(0), uint256(0)];

        bool ok = adapter.verify(n, g, c, h_m, circuitVersion, sessionID, a, b, c_);
        require(ok, "verify failed");
    }
}
