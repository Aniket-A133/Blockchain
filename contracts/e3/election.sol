// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VotingSystem {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    address public owner;
    bool public electionActive;
    Candidate[] private candidates;
    mapping(address => bool) public hasVoted;

    event VoteCast(address indexed voter, uint indexed candidateId);
    event ElectionEnded(uint timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier whileActive() {
        require(electionActive, "election not active");
        _;
    }

    constructor(string[] memory candidateNames) {
        owner = msg.sender;
        electionActive = true;
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({id: i, name: candidateNames[i], voteCount: 0}));
        }
    }

    function vote(uint candidateId) external whileActive {
        require(!hasVoted[msg.sender], "already voted");
        require(candidateId < candidates.length, "invalid candidate");
        hasVoted[msg.sender] = true;
        candidates[candidateId].voteCount += 1;
        emit VoteCast(msg.sender, candidateId);
    }

    function endElection() external onlyOwner whileActive {
        electionActive = false;
        emit ElectionEnded(block.timestamp);
    }

    function getCandidate(uint candidateId) external view returns (uint id, string memory name, uint voteCount) {
        require(candidateId < candidates.length, "invalid candidate");
        Candidate storage c = candidates[candidateId];
        return (c.id, c.name, c.voteCount);
    }

    function totalCandidates() external view returns (uint) {
        return candidates.length;
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function winner() external view returns (uint winnerId, string memory winnerName, uint winnerVotes) {
        require(!electionActive, "election still active");
        uint winningId = 0;
        uint highest = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highest) {
                highest = candidates[i].voteCount;
                winningId = candidates[i].id;
            }
        }
        return (winningId, candidates[winningId].name, highest);
    }
}
