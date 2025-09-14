// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVerifier} from "./interfaces/IVerifier.sol";

/// @title VerifierAdapter
/// @notice 公開入力のABI順序を固定し、生成された Verifier に委譲する薄いアダプタ
/// @dev 公開入力の順序を [n, g, c, h_m, circuitVersion, sessionID] に固定する
contract VerifierAdapter {
    IVerifier public immutable verifier;

    constructor(address verifier_) {
        require(verifier_ != address(0), "verifier=0");
        verifier = IVerifier(verifier_);
    }

    /// @notice 公開入力を固定順序で配列化し、Verifier に委譲して真偽を返す
    /// @param n Paillier n
    /// @param g Paillier g
    /// @param c 暗号文 c
    /// @param h_m 平文 m の場上ハッシュ
    /// @param circuitVersion 回路バージョン識別子
    /// @param sessionID セッション識別子
    /// @param a Groth16 proof.a
    /// @param b Groth16 proof.b
    /// @param c_ Groth16 proof.c（変数名衝突回避のため末尾に '_'）
    function verify(
        uint256 n,
        uint256 g,
        uint256 c,
        uint256 h_m,
        uint256 circuitVersion,
        uint256 sessionID,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c_
    ) external view returns (bool ok) {
        uint256[] memory input = new uint256[](6);
        input[0] = n;
        input[1] = g;
        input[2] = c;
        input[3] = h_m;
        input[4] = circuitVersion;
        input[5] = sessionID;
        return verifier.verifyProof(a, b, c_, input);
    }
}

