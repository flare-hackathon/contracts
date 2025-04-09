// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICurateAIVote
 * @dev Interface for the CurateAIVote contract, managing voting logic and vote tracking in the CurateAI ecosystem.
 */
interface ICurateAIVote {

    event Voted(uint256 indexed postId, address indexed voter, uint256 amount);

    function vote(uint256 postId, uint256 amount) external;
    function aiVote(uint256 postId, uint256 amount) external;
    function getAuthorVotes(uint256 day, address author) external view returns (uint256);
    function getTotalVotes() external view returns (uint256);
    function getUserVoteDays(address user) external view returns (uint256[] memory);
    function clearUserVoteDays(address user) external;
    function getDailyTotalVotes(uint256 day) external view returns (uint256);
}