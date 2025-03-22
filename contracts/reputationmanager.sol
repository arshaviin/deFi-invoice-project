// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ReputationManager is Ownable {
    mapping(address => uint256) public score;

    event ScoreUpdated(address indexed user, uint256 score);

    function setScore(address user, uint256 newScore) external onlyOwner {
        score[user] = newScore;
        emit ScoreUpdated(user, newScore);
    }

    function adjustScore(address user, int256 delta) external onlyOwner {
        uint256 current = score[user];
        if (delta < 0 && current < uint256(-delta)) {
            score[user] = 0;
        } else {
            score[user] = uint256(int256(current) + delta);
        }
        emit ScoreUpdated(user, score[user]);
    }

    function getScore(address user) external view returns (uint256) {
        return score[user];
    }
}