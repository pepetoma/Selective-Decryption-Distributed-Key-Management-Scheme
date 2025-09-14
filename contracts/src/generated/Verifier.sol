// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVerifier} from "../interfaces/IVerifier.sol";

/// @notice 生成物プレースホルダ、本ファイルは tools で生成される Verifier.sol を差し替えるまでのダミーです
contract Verifier is IVerifier {
    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[] calldata
    ) external pure returns (bool r) {
        // 生成物差し替え前は常に false とする
        return false;
    }
}

