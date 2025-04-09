// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurateAIPost {
    event PostCreated(uint256 indexed id, address indexed author, string contentHash, string tags);

    struct Post  {
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

    function createPost(string calldata contentHash, string calldata tags) external;
    function getPostScore(uint256 postId) external view returns (uint256);
    function postCounter() external view returns (uint256);
    function getPosts(uint256 postId) external view returns (Post memory);
    function setPostScore(uint256 postId, uint256 amount) external;
    function setAIVoted(uint256 postId) external;
}