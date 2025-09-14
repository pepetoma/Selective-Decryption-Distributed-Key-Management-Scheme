// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @notice 固定長（6件）の公開入力を受け取る Verifier インタフェース
interface IVerifier6 {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[6] calldata input
    ) external view returns (bool r);
}

