// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/checkRole.sol";

/**
 * @title CurateAIPost
 * @dev Manages post creation and storage for the CurateAI ecosystem.
 */
contract CurateAIPost is CheckRole {
    struct Post {
        uint256 id;
        address author;
        string contentHash;
        uint256 totalScore;
        uint256 claimedScore;
        uint256 createdAt;
        string tags;
        bool newVote;
        bool aiVoted;
    }

    uint256 public postCounter;
    mapping(uint256 => Post) public posts;

    event PostCreated(uint256 indexed id, address indexed author, string contentHash, string tags);

    constructor(address _roleManager) CheckRole(_roleManager) {}

    /**
     * @notice Creates a new post, restricted to curators.
     * @param contentHash The hash of the post content (e.g., IPFS hash).
     * @param tags Tags associated with the post.
     */
    function createPost(string calldata contentHash, string calldata tags) 
        external 
        onlyRole(CURATOR_ROLE) 
    {
        postCounter++;
        posts[postCounter] = Post({
            id: postCounter,
            author: msg.sender,
            contentHash: contentHash,
            totalScore: 0,
            claimedScore: 0,
            createdAt: block.timestamp,
            tags: tags,
            newVote: false,
            aiVoted: false
        });
        emit PostCreated(postCounter, msg.sender, contentHash, tags);
    }

    /**
     * @notice Retrieves the total score of a post.
     * @param postId The ID of the post.
     * @return The total score accumulated by the post.
     */
    function getPostScore(uint256 postId) external view returns (uint256) {
        return posts[postId].totalScore;
    }

    /**
     * @notice Updates a post’s score, restricted to the voting contract.
     * @param postId The ID of the post to update.
     * @param amount The amount to add to the total score.
     */
    function setPostScore(uint256 postId, uint256 amount) 
        external 
        onlyRole(VOTING_CONTRACT)
    {
        require(postId > 0 && postId <= postCounter, "Invalid post ID");
        posts[postId].totalScore += amount;
        posts[postId].newVote = true;
    }

    /**
     * @notice Marks a post as AI-voted, restricted to voting contract.
     * @param postId The ID of the post to mark.
     */
    function setAIVoted(uint256 postId) 
        external 
        onlyRole(VOTING_CONTRACT) 
    {
        require(postId > 0 && postId <= postCounter, "Invalid post ID");
        posts[postId].aiVoted = true;
    }

    function getPosts(uint256 postId) external view returns(Post memory post) {
        return posts[postId];
    }
}