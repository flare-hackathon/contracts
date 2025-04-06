// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRoleManager.sol";

abstract contract CheckRole {
    IRoleManager public roleManager;
    bytes32 public constant SETTLEMENT_ROLE = keccak256("SETTLEMENT_ROLE");
    bytes32 public constant AI_AGENT_ROLE = keccak256("AI_AGENT_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant VOTING_CONTRACT = keccak256("VOTING_CONTRACT");

    constructor(address _roleManager) {
        require(_roleManager != address(0), "Invalid RoleManager address");
        roleManager = IRoleManager(_roleManager);
    }

    modifier onlyRole(bytes32 role) {
        require(roleManager.hasRole(role, msg.sender), "Caller does not have required role");
        _;
    }

    modifier execeptRole(bytes32 role) {
        require(!roleManager.hasRole(role, msg.sender), "AI agent can't vote directly");
        _;
    }
}