// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @notice snarkjs の Verifier.sol が一般に提供するインタフェース（Groth16想定）
interface IVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external view returns (bool r);
}

