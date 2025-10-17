// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Election
 * @dev A secure decentralized voting system with time-based controls
 * @notice This contract allows one vote per address during a specified time window
 */
contract Election is ReentrancyGuard {
    
    // ============ Structs ============
    
    struct Candidate {
        uint id;
        string name;
        string description;
        uint voteCount;
    }
    
    // ============ State Variables ============
    
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => uint) public voterChoice;
    
    uint public candidatesCount;
    uint public totalVotes;
    uint public electionStartTime;
    uint public electionEndTime;
    
    address public electionCommissioner;
    
    // ============ Events ============
    
    event VoteCast(address indexed voter, uint indexed candidateId, uint timestamp);
    event ElectionEnded(uint indexed winnerId, string winnerName, uint voteCount);
    event ElectionCreated(uint startTime, uint endTime, uint candidatesCount);
    
    // ============ Modifiers ============
    
    modifier onlyDuringElection() {
        require(block.timestamp >= electionStartTime, "Election has not started yet");
        require(block.timestamp <= electionEndTime, "Election has ended");
        _;
    }
    
    modifier onlyAfterElection() {
        require(block.timestamp > electionEndTime, "Election is still ongoing");
        _;
    }
    
    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }
    
    modifier validCandidate(uint _candidateId) {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @dev Initialize election with 5 candidates and time window
     * @param _startTime Unix timestamp for election start
     * @param _endTime Unix timestamp for election end
     */
    constructor(uint _startTime, uint _endTime) {
        require(_startTime < _endTime, "Start time must be before end time");
        require(_endTime > block.timestamp, "End time must be in the future");
        
        electionCommissioner = msg.sender;
        electionStartTime = _startTime;
        electionEndTime = _endTime;
        
        // Initialize 5 candidates
        _addCandidate("Alice Johnson", "Experienced leader with 15 years in public service. Focus on education and healthcare reform.");
        _addCandidate("Bob Smith", "Technology entrepreneur advocating for digital infrastructure and innovation.");
        _addCandidate("Carol Davis", "Environmental activist committed to sustainable development and climate action.");
        _addCandidate("David Wilson", "Former military officer prioritizing national security and veterans' affairs.");
        _addCandidate("Eva Brown", "Social worker dedicated to community development and social welfare programs.");
        
        emit ElectionCreated(_startTime, _endTime, candidatesCount);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Internal function to add a candidate
     * @param _name Candidate's name
     * @param _description Candidate's description
     */
    function _addCandidate(string memory _name, string memory _description) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _description, 0);
    }
    
    // ============ Public Functions ============
    
    /**
     * @dev Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for (1-5)
     */
    function vote(uint _candidateId) 
        public 
        nonReentrant
        onlyDuringElection 
        hasNotVoted 
        validCandidate(_candidateId) 
    {
        // Mark voter as having voted
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateId;
        
        // Increment candidate's vote count
        candidates[_candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCast(msg.sender, _candidateId, block.timestamp);
    }
    
    /**
     * @dev Get all candidates with their vote counts
     * @return Array of all candidates
     */
    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidatesCount);
        
        for (uint i = 1; i <= candidatesCount; i++) {
            allCandidates[i - 1] = candidates[i];
        }
        
        return allCandidates;
    }
    
    /**
     * @dev Get vote counts for all candidates
     * @return Array of vote counts indexed by candidate ID - 1
     */
    function getResults() public view returns (uint[] memory) {
        uint[] memory results = new uint[](candidatesCount);
        
        for (uint i = 1; i <= candidatesCount; i++) {
            results[i - 1] = candidates[i].voteCount;
        }
        
        return results;
    }
    
    /**
     * @dev Get the winning candidate
     * @return winnerId ID of the winning candidate
     * @return winnerName Name of the winning candidate
     * @return winnerVoteCount Vote count of the winner
     */
    function getWinner() public view returns (uint winnerId, string memory winnerName, uint winnerVoteCount) {
        require(totalVotes > 0, "No votes have been cast yet");
        
        uint highestVoteCount = 0;
        uint winningCandidateId = 0;
        
        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        
        return (
            winningCandidateId,
            candidates[winningCandidateId].name,
            highestVoteCount
        );
    }
    
    /**
     * @dev Get current election status
     * @return status String indicating election status
     */
    function getElectionStatus() public view returns (string memory status) {
        if (block.timestamp < electionStartTime) {
            return "Not Started";
        } else if (block.timestamp <= electionEndTime) {
            return "Active";
        } else {
            return "Ended";
        }
    }
    
    /**
     * @dev Get time remaining in the election
     * @return seconds remaining (0 if ended or not started)
     */
    function getTimeRemaining() public view returns (uint) {
        if (block.timestamp < electionStartTime) {
            return 0;
        } else if (block.timestamp > electionEndTime) {
            return 0;
        } else {
            return electionEndTime - block.timestamp;
        }
    }
    
    /**
     * @dev Check if an address has voted
     * @param _voter Address to check
     * @return bool indicating if the address has voted
     */
    function hasAddressVoted(address _voter) public view returns (bool) {
        return hasVoted[_voter];
    }
    
    /**
     * @dev Get candidate details by ID
     * @param _candidateId ID of the candidate
     * @return Candidate struct
     */
    function getCandidate(uint _candidateId) public view validCandidate(_candidateId) returns (Candidate memory) {
        return candidates[_candidateId];
    }
    
    /**
     * @dev Get election information
     * @return start time, end time, total votes, candidates count
     */
    function getElectionInfo() public view returns (uint, uint, uint, uint) {
        return (electionStartTime, electionEndTime, totalVotes, candidatesCount);
    }
}

