// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CurateAIRoleManager
 * @dev Manages roles for the CurateAI ecosystem with a hierarchical access control system.
 *      Ensures secure role assignment and immutability for critical roles.
 */
contract CurateAIRoleManager is AccessControl, ReentrancyGuard {

    bytes32 public immutable SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public immutable MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public immutable CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public immutable SETTLEMENT_ROLE = keccak256("SETTLEMENT_ROLE");
    bytes32 public immutable VOTING_CONTRACT = keccak256("VOTING_CONTRACT");
    bytes32 public immutable AI_AGENT_ROLE = keccak256("AI_AGENT_ROLE");

    bool private _contractInit;

    event SettlementContractSet(address indexed settlementContract, address indexed setter);
    event ModeratorAssigned(address indexed account, address indexed assigner);
    event ModeratorRevoked(address indexed account, address indexed revoker);
    event AIAgentAssigned(address indexed account, address indexed assigner);
    event CuratorAssigned(address indexed account, address indexed assigner);

    uint256 public _curator_counter = 0;

    /**
     * @dev Initializes the contract with the deployer as the super admin and initial settlement role holder.
     */
    constructor() {
        address deployer = msg.sender;
        _grantRole(SUPER_ADMIN_ROLE, deployer);
        _grantRole(SETTLEMENT_ROLE, deployer);
        _grantRole(VOTING_CONTRACT, deployer);

        _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(MODERATOR_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(CURATOR_ROLE, MODERATOR_ROLE);
        _setRoleAdmin(SETTLEMENT_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(VOTING_CONTRACT, SUPER_ADMIN_ROLE);
        _setRoleAdmin(AI_AGENT_ROLE, SUPER_ADMIN_ROLE);
    }

    /**
     * @notice Sets the settlement contract address and locks further changes.
     * @dev Only callable by the super admin before the settlement role is locked.
     * @param settlementContract The address to receive the settlement role.
     */
    function setSettlementAndVotingContract(address settlementContract, address votingContract) 
        external 
        onlyRole(SUPER_ADMIN_ROLE) 
        nonReentrant 
    {
        require(!_contractInit, "Contract is already initialized");
        require(settlementContract != address(0), "Settlement address cannot be zero");
        require(votingContract != address(0), "Settlement address cannot be zero");

        address currentSetter = msg.sender;
        _revokeRole(SETTLEMENT_ROLE, currentSetter);
        _revokeRole(VOTING_CONTRACT, currentSetter);
        _grantRole(SETTLEMENT_ROLE, settlementContract);
        _grantRole(VOTING_CONTRACT, votingContract);
        _contractInit = true;

        emit SettlementContractSet(settlementContract, currentSetter);
    }

    /**
     * @notice Assigns the moderator role to an account.
     * @dev Only callable by the super admin.
     * @param account The address to receive the moderator role.
     */
    function assignModerator(address account) 
        external 
        onlyRole(SUPER_ADMIN_ROLE) 
    {
        require(account != address(0), "Moderator address cannot be zero");
        _grantRole(MODERATOR_ROLE, account);
        emit ModeratorAssigned(account, msg.sender);
    }

    /**
     * @notice Revokes the moderator role from an account.
     * @dev Only callable by the super admin.
     * @param account The address to lose the moderator role.
     */
    function revokeModerator(address account) 
        external 
        onlyRole(SUPER_ADMIN_ROLE) 
    {
        require(account != address(0), "Moderator address cannot be zero");
        _revokeRole(MODERATOR_ROLE, account);
        emit ModeratorRevoked(account, msg.sender);
    }

    /**
     * @notice Assigns the AI agent role to an account.
     * @dev Only callable by the super admin.
     * @param account The address to receive the AI agent role.
     */
    function assignAIAgent(address account) 
        external 
        onlyRole(SUPER_ADMIN_ROLE) 
    {
        require(account != address(0), "AI agent address cannot be zero");
        _grantRole(AI_AGENT_ROLE, account);
        emit AIAgentAssigned(account, msg.sender);
    }

    /**
     * @notice Assigns the curator role to an account.
     * @dev Only callable by a moderator.
     * @param account The address to receive the curator role.
     */
    function assignCurator(address account) 
        external 
        onlyRole(MODERATOR_ROLE) 
    {
        require(account != address(0), "Curator address cannot be zero");
        _curator_counter++;
        _grantRole(CURATOR_ROLE, account);
        emit CuratorAssigned(account, msg.sender);
    }

    /**
     * @notice Grants a role to an account, with restrictions on settlement role.
     * @dev Overrides AccessControl.grantRole to enforce settlement role locking.
     * @param role The role to grant.
     * @param account The address to receive the role.
     */
    function grantRole(bytes32 role, address account) 
        public 
        override 
        onlyRole(getRoleAdmin(role)) 
    {
        require(account != address(0), "Account cannot be zero address");
        if (role == SETTLEMENT_ROLE || role == VOTING_CONTRACT) {
            require(!_contractInit, "Contract roles cannot be changed");
        }
        super.grantRole(role, account);
    }

    /**
     * @notice Revokes a role from an account, with restrictions on certain roles.
     * @dev Overrides AccessControl.revokeRole to enforce role immutability.
     * @param role The role to revoke.
     * @param account The address to lose the role.
     */
    function revokeRole(bytes32 role, address account) 
        public 
        override 
        onlyRole(getRoleAdmin(role)) 
    {
        require(account != address(0), "Account cannot be zero address");
        if (role == CURATOR_ROLE) {
            revert("Curator role cannot be revoked");
        }
        if (role == SETTLEMENT_ROLE && _contractInit || role == VOTING_CONTRACT && _contractInit) {
            revert("Contract roles cannot be revoked after locking");
        }
        super.revokeRole(role, account);
    }

    /**
     * @notice Checks if the settlement role is locked.
     * @return True if the settlement role is locked, false otherwise.
     */
    function isSettlementLocked() external view returns (bool) {
        return _contractInit;
    }
}