// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IContentMediaToken.sol";
import "./utils/checkRole.sol";
import "./interfaces/ICurateAIPost.sol";

/**
 * @title CurateAIVote
 * @dev Manages voting logic and vote tracking for the CurateAI ecosystem.
 */
contract CurateAIVote is CheckRole {
    uint256 public constant VOTES_PER_DAY_MULTIPLIER = 5;
    IContentMediaToken public token;
    ICurateAIPost public postContract;

    mapping(uint256 => mapping(uint256 => uint256)) public dailyPostVotes;
    mapping(uint256 => uint256) public dailyVoteTotals;
    mapping(address => mapping(uint256 => uint256)) public dailyAuthorVotes;
    mapping(address => uint256[]) public userActiveDays;

    mapping(address => uint256) public lastVoteResetTime;
    mapping(address => uint256) public votesUsedToday;

    event Voted(uint256 indexed postId, address indexed voter, uint256 amount);

    constructor(address _tokenAddress, address _roleManager, address _postContract) 
        CheckRole(_roleManager) 
    {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_postContract != address(0), "Invalid post contract address");
        token = IContentMediaToken(_tokenAddress);
        postContract = ICurateAIPost(_postContract);
    }

    /**
     * @notice Allows users (except AI agents) to vote on a post.
     * @param postId The ID of the post to vote on.
     * @param amount The number of votes to cast.
     */
    function vote(uint256 postId, uint256 amount) 
        external 
        exceptRole(AI_AGENT_ROLE) 
    {
        require(postId <= postContract.postCounter(), "Post does not exist");
        require(amount > 0, "Amount must be greater than 0");

        // Reset voter power after 24 hrs
        if (block.timestamp >= lastVoteResetTime[msg.sender] + 1 days) {
            votesUsedToday[msg.sender] = 0;
            lastVoteResetTime[msg.sender] = block.timestamp;
        }

        // Check if vote limit exceeds maximum
        uint256 maxVotesToday = VOTES_PER_DAY_MULTIPLIER * token.balanceOf(msg.sender);
        require(votesUsedToday[msg.sender] + amount <= maxVotesToday, "Exceeds daily vote limit");

        uint256 currentDay = block.timestamp / 1 days;
        ICurateAIPost.Post memory post = postContract.getPosts(postId);
        address postAuthor = post.author;

        postContract.setPostScore(postId, amount);
        dailyPostVotes[currentDay][postId] += amount;
        dailyVoteTotals[currentDay] += amount;
        dailyAuthorVotes[postAuthor][currentDay] += amount;

        if (dailyAuthorVotes[postAuthor][currentDay] == amount) {
            userActiveDays[postAuthor].push(currentDay);
        }

        votesUsedToday[msg.sender] += amount;
        emit Voted(postId, msg.sender, amount);
    }

    /**
     * @notice Allows AI agents to vote on a post within the first day.
     * @param postId The ID of the post to vote on.
     * @param amount The number of votes to cast.
     */
    function aiVote(uint256 postId, uint256 amount) 
        external 
        onlyRole(AI_AGENT_ROLE) 
    {
        require(postId <= postContract.postCounter(), "Post does not exist");
        require(amount > 0, "Amount must be greater than 0");
        require(!postContract.getPosts(postId).aiVoted, "AI can only vote once per post");
        // require(block.timestamp < postContract.getPosts(postId).createdAt + 1 days, "AI can only vote on the first day");

        uint256 currentDay = block.timestamp / 1 days;
        address postAuthor = postContract.getPosts(postId).author;

        postContract.setPostScore(postId, amount);
        dailyPostVotes[currentDay][postId] += amount;
        dailyVoteTotals[currentDay] += amount;
        dailyAuthorVotes[postAuthor][currentDay] += amount;
        postContract.setAIVoted(postId);

        if (dailyAuthorVotes[postAuthor][currentDay] == amount) {
            userActiveDays[postAuthor].push(currentDay);
        }

        emit Voted(postId, msg.sender, amount);
    }

    /**
     * @notice Retrieves the total votes for an author on a specific day.
     * @param day The day to query.
     * @param author The author’s address.
     * @return The total votes received by the author on that day.
     */
    function getAuthorVotes(uint256 day, address author) external view returns (uint256) {
        return dailyAuthorVotes[author][day];
    }

    /**
     * @notice Retrieves the total votes cast on the current day.
     * @return The total votes for the current day.
     */
    function getTotalVotes() external view returns (uint256) {
        return dailyVoteTotals[block.timestamp / 1 days];
    }

    /**
     * @notice Retrieves the days an author received votes.
     * @param user The author’s address.
     * @return An array of days with voting activity.
     */
    function getUserVoteDays(address user) external view returns (uint256[] memory) {
        return userActiveDays[user];
    }

    /**
     * @notice Clears author's active days.
     * @param user The author’s address.
     */
    function clearUserVoteDays(address user) external onlyRole(SETTLEMENT_ROLE) {
        delete userActiveDays[user];
    }

    /**
     * @notice Retrieves the total votes cast on a specific day.
     * @param day The day to query.
     * @return The total votes for that day.
     */
    function getDailyTotalVotes(uint256 day) external view returns (uint256) {
        return dailyVoteTotals[day];
    }

    // Modifier to exclude a specific role
    modifier exceptRole(bytes32 role) {
        require(!roleManager.hasRole(role, msg.sender), "AI agent can't vote directly");
        _;
    }
}