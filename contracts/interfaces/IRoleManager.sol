// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the Role contract
interface IRoleManager {
    // Events inherited from AccessControl (commonly used for role tracking)
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    // Constant role identifiers
    function SUPER_ADMIN_ROLE() external view returns (bytes32);
    function MODERATOR_ROLE() external view returns (bytes32);
    function CURATOR_ROLE() external view returns (bytes32);
    function SETTLEMENT_ROLE() external view returns (bytes32);

    // External functions from the Role contract
    function setSettlementContract(address settlementContract) external;
    function assignModerator(address account) external;
    function revokeModerator(address account) external;
    function assignCurator(address account) external;

    // Inherited AccessControl functions commonly used
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}