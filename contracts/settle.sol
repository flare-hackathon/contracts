// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IContentMediaToken.sol";
import "./interfaces/ICurateAIVote.sol";
import "./utils/checkRole.sol";

/**
 * @title CurateAISettlement
 * @dev Handles daily reward settlement and claiming for the CurateAI ecosystem.
 */
contract CurateAISettlement is CheckRole {
    IContentMediaToken public token;
    ICurateAIVote public voting;

    struct DailyReward {
        uint256 totalReward;
        uint256 rewardPerVote;
        bool settled;
    }

    mapping(uint256 => DailyReward) public dailyRewards;

    event DailySettlement(uint256 indexed day, uint256 totalReward);
    event RewardsClaimed(address indexed user, uint256 totalAmount);

    /**
     * @notice Constructs the settlement contract with references to token and voting contracts.
     * @param _tokenAddress Address of the CurateAIToken contract.
     * @param _votingAddress Address of the CurateAIVote contract.
     * @param _roleManager Address of the role manager contract.
     */
    constructor(address _tokenAddress, address _votingAddress, address _roleManager) 
        CheckRole(_roleManager) 
    {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_votingAddress != address(0), "Invalid voting address");
        token = IContentMediaToken(_tokenAddress);
        voting = ICurateAIVote(_votingAddress);
    }

    /**
     * @notice Settles rewards for a past day, minting and distributing tokens based on votes.
     * @param day The day to settle (must be in the past).
     */
    function settleDay(uint256 day) public {
        uint256 currentDay = getCurrentDay();
        require(currentDay > day, "Can only settle past days");
        require(!dailyRewards[day].settled, "Day already settled");

        token.mintDailyRewards();
        uint256 totalVotes = voting.getDailyTotalVotes(day);

        uint256 PRECISION = 10**18;
        uint256 adjustedRewardPerVote = totalVotes > 0 
            ? (token.DAILY_MINT_AMOUNT() * PRECISION) / totalVotes 
            : 0;

        dailyRewards[day] = DailyReward({
            totalReward: token.DAILY_MINT_AMOUNT(),
            rewardPerVote: adjustedRewardPerVote,
            settled: true
        });

        emit DailySettlement(day, token.DAILY_MINT_AMOUNT());
    }

    /**
     * @notice Allows curators to claim their accumulated rewards.
     */
    function claimRewards() external onlyRole(CURATOR_ROLE) {
        uint256 totalAmount = getClaimableAmount(msg.sender);
        require(totalAmount > 0, "No rewards to claim");

        uint256 PRECISION = 10**18;
        uint256 adjustedAmount = totalAmount / PRECISION;

        voting.clearUserVoteDays(msg.sender);
        token.distribute(msg.sender, adjustedAmount);
        emit RewardsClaimed(msg.sender, adjustedAmount);
    }

    /**
     * @notice Calculates the claimable reward amount for a user across all active days.
     * @param user The address of the user to query.
     * @return The total claimable amount in wei-scale precision.
     */
    function getClaimableAmount(address user) public view returns (uint256) {
        uint256[] memory activeDays = voting.getUserVoteDays(user);
        uint256 totalAmount;

        for (uint256 i = 0; i < activeDays.length; i++) {
            uint256 day = activeDays[i];
            DailyReward storage dr = dailyRewards[day];

            if (dr.settled) {
                uint256 userVotes = voting.getAuthorVotes(day, user);
                totalAmount += userVotes * dr.rewardPerVote;
            }
        }

        return totalAmount;
    }

    /**
     * @notice Returns the current day number based on the blockchain timestamp.
     * @return The current day.
     */
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
}