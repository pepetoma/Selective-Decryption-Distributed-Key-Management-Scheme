// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {VerifierAdapter} from "./VerifierAdapter.sol";

/// @title VerifierRegistry
/// @notice circuitVersion ごとの VerifierAdapter を登録し、sessionID の再利用を防ぎつつ検証を委譲する
/// @dev 公開入力順序は VerifierAdapter により [n, g, c, h_m, circuitVersion, sessionID] で固定される
contract VerifierRegistry {
    // --- Ownable minimal ---
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner=0");
        owner = newOwner;
    }

    // --- Registry and replay protection ---
    mapping(uint256 => VerifierAdapter) public adapters; // circuitVersion => adapter
    mapping(uint256 => bool) private consumed; // sessionID => used?

    event AdapterSet(uint256 indexed circuitVersion, address indexed adapter);
    event Verified(
        uint256 c,
        uint256 h_m,
        uint256 circuitVersion,
        uint256 sessionID
    );

    /// @notice circuitVersion に対応する VerifierAdapter を登録/更新する（上書き可）
    function setAdapter(uint256 circuitVersion, address adapter) external onlyOwner {
        require(adapter != address(0), "adapter=0");
        adapters[circuitVersion] = VerifierAdapter(adapter);
        emit AdapterSet(circuitVersion, adapter);
    }

    /// @notice sessionID が消費済みかを確認するユーティリティ
    function isSessionConsumed(uint256 sessionID) external view returns (bool) {
        return consumed[sessionID];
    }

    /// @notice 指定 circuitVersion の Adapter による検証を行い、成功時に sessionID を消費しイベントを発火
    function verifyAndConsume(
        uint256 n,
        uint256 g,
        uint256 c,
        uint256 h_m,
        uint256 circuitVersion,
        uint256 sessionID,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c_
    ) external returns (bool ok) {
        VerifierAdapter adapter = adapters[circuitVersion];
        require(address(adapter) != address(0), "unregistered version");
        require(!consumed[sessionID], "session used");

        ok = adapter.verify(n, g, c, h_m, circuitVersion, sessionID, a, b, c_);
        require(ok, "verify false");

        consumed[sessionID] = true;
        emit Verified(c, h_m, circuitVersion, sessionID);
        return true;
    }
}

