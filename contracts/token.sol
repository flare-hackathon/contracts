// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./utils/checkRole.sol";

contract CurateAIToken is ERC20, ReentrancyGuard, CheckRole {
    
    uint256 public constant DAILY_MINT_AMOUNT = 100_000;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000;
    uint256 public lastMintTime;

    bool private _roleAssigned;

    constructor(address _roleManager) ERC20("CurateAIToken", "CAT") CheckRole(_roleManager) {
        require(_roleManager != address(0), "Invalid RoleManager address");
        _mint(msg.sender, INITIAL_SUPPLY / 2);
        _mint(address(this), INITIAL_SUPPLY / 2);
    }

    function mintDailyRewards() external onlyRole(SETTLEMENT_ROLE) nonReentrant {
        require(block.timestamp >= lastMintTime + 1 days, "Can only mint once per day");
        lastMintTime = block.timestamp;
        _mint(address(this), DAILY_MINT_AMOUNT);
    }

    function distribute(address to, uint256 amount) external onlyRole(SETTLEMENT_ROLE) nonReentrant {
        _transfer(address(this), to, amount);
    }

}