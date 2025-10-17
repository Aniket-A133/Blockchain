// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ElectionCommission
 * @dev Indian Election Commission style voting system with multi-phase election management
 * @notice Implements candidate registration, voter registration, and secure voting process
 */
contract ElectionCommission is ReentrancyGuard {
    
    // ============ Enums ============
    
    enum ElectionPhase {
        SETUP,              // Commission setup
        CANDIDATE_REG,      // Candidate registration open
        VOTER_REG,          // Voter registration open
        CAMPAIGN,           // Campaign period
        VOTING,             // Voting period
        COUNTING,           // Vote counting
        RESULTS             // Results declared
    }
    
    // ============ Structs ============
    
    struct Candidate {
        uint256 id;
        string name;
        string party;
        string symbol;
        string manifesto;
        address candidateAddress;
        uint256 securityDeposit;
        bool approved;
        uint256 voteCount;
        uint256 registrationTime;
    }
    
    struct Voter {
        uint256 voterId;
        string name;
        uint256 age;
        string constituency;
        address voterAddress;
        bool verified;
        bool hasVoted;
        uint256 votedFor;
        uint256 registrationTime;
    }
    
    // ============ State Variables ============
    
    address public chiefElectionCommissioner;
    mapping(address => bool) public electionOfficers;
    
    ElectionPhase public currentPhase;
    string public electionName;
    string public constituency;
    
    mapping(uint256 => Candidate) public candidates;
    mapping(address => uint256) public candidateAddressToId;
    
    mapping(uint256 => Voter) public voters;
    mapping(address => uint256) public voterAddressToId;
    
    uint256 public candidateCount;
    uint256 public voterCount;
    uint256 public totalVotes;
    uint256 public notaVotes;
    
    uint256 public constant SECURITY_DEPOSIT = 0.01 ether;
    uint256 public constant MIN_VOTING_AGE = 18;
    
    // Phase timestamps
    uint256 public candidateRegStartTime;
    uint256 public candidateRegEndTime;
    uint256 public voterRegStartTime;
    uint256 public voterRegEndTime;
    uint256 public campaignStartTime;
    uint256 public campaignEndTime;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    
    // ============ Events ============
    
    event ElectionCreated(string electionName, string constituency, uint256 timestamp);
    event PhaseChanged(ElectionPhase oldPhase, ElectionPhase newPhase, uint256 timestamp);
    event ElectionOfficerAdded(address indexed officer, uint256 timestamp);
    event ElectionOfficerRemoved(address indexed officer, uint256 timestamp);
    
    event CandidateRegistered(uint256 indexed candidateId, string name, string party, address candidateAddress, uint256 timestamp);
    event CandidateApproved(uint256 indexed candidateId, address approvedBy, uint256 timestamp);
    event CandidateRejected(uint256 indexed candidateId, address rejectedBy, uint256 timestamp);
    event ManifestoUpdated(uint256 indexed candidateId, uint256 timestamp);
    
    event VoterRegistered(uint256 indexed voterId, string name, address voterAddress, uint256 timestamp);
    event VoterVerified(uint256 indexed voterId, address verifiedBy, uint256 timestamp);
    event VoterRejected(uint256 indexed voterId, address rejectedBy, uint256 timestamp);
    
    event VoteCast(uint256 indexed voterId, uint256 indexed candidateId, uint256 timestamp);
    event NotaVoteCast(uint256 indexed voterId, uint256 timestamp);
    event ResultsDeclared(uint256 winnerId, string winnerName, uint256 voteCount, uint256 timestamp);
    
    // ============ Modifiers ============
    
    modifier onlyCommissioner() {
        require(msg.sender == chiefElectionCommissioner, "Only Chief Election Commissioner");
        _;
    }
    
    modifier onlyElectionOfficer() {
        require(electionOfficers[msg.sender] || msg.sender == chiefElectionCommissioner, "Only Election Officers");
        _;
    }
    
    modifier inPhase(ElectionPhase _phase) {
        require(currentPhase == _phase, "Not in correct election phase");
        _;
    }
    
    modifier validCandidateId(uint256 _candidateId) {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        _;
    }
    
    modifier validVoterId(uint256 _voterId) {
        require(_voterId > 0 && _voterId <= voterCount, "Invalid voter ID");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(string memory _electionName, string memory _constituency) {
        chiefElectionCommissioner = msg.sender;
        electionName = _electionName;
        constituency = _constituency;
        currentPhase = ElectionPhase.SETUP;
        
        emit ElectionCreated(_electionName, _constituency, block.timestamp);
    }
    
    // ============ Admin Functions ============
    
    function addElectionOfficer(address _officer) external onlyCommissioner {
        require(_officer != address(0), "Invalid address");
        require(!electionOfficers[_officer], "Already an officer");
        
        electionOfficers[_officer] = true;
        emit ElectionOfficerAdded(_officer, block.timestamp);
    }
    
    function removeElectionOfficer(address _officer) external onlyCommissioner {
        require(electionOfficers[_officer], "Not an officer");
        
        electionOfficers[_officer] = false;
        emit ElectionOfficerRemoved(_officer, block.timestamp);
    }
    
    function setElectionPhase(ElectionPhase _phase) external onlyCommissioner {
        ElectionPhase oldPhase = currentPhase;
        currentPhase = _phase;
        
        emit PhaseChanged(oldPhase, _phase, block.timestamp);
    }
    
    function setPhaseTimestamps(
        uint256 _candidateRegStart,
        uint256 _candidateRegEnd,
        uint256 _voterRegStart,
        uint256 _voterRegEnd,
        uint256 _campaignStart,
        uint256 _campaignEnd,
        uint256 _votingStart,
        uint256 _votingEnd
    ) external onlyCommissioner {
        candidateRegStartTime = _candidateRegStart;
        candidateRegEndTime = _candidateRegEnd;
        voterRegStartTime = _voterRegStart;
        voterRegEndTime = _voterRegEnd;
        campaignStartTime = _campaignStart;
        campaignEndTime = _campaignEnd;
        votingStartTime = _votingStart;
        votingEndTime = _votingEnd;
    }
    
    // ============ Candidate Functions ============
    
    function registerCandidate(
        string memory _name,
        string memory _party,
        string memory _symbol,
        string memory _manifesto
    ) external payable inPhase(ElectionPhase.CANDIDATE_REG) nonReentrant {
        require(msg.value >= SECURITY_DEPOSIT, "Insufficient security deposit");
        require(candidateAddressToId[msg.sender] == 0, "Already registered as candidate");
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_party).length > 0, "Party required");
        
        candidateCount++;
        
        candidates[candidateCount] = Candidate({
            id: candidateCount,
            name: _name,
            party: _party,
            symbol: _symbol,
            manifesto: _manifesto,
            candidateAddress: msg.sender,
            securityDeposit: msg.value,
            approved: false,
            voteCount: 0,
            registrationTime: block.timestamp
        });
        
        candidateAddressToId[msg.sender] = candidateCount;
        
        emit CandidateRegistered(candidateCount, _name, _party, msg.sender, block.timestamp);
    }
    
    function approveCandidate(uint256 _candidateId) external onlyElectionOfficer validCandidateId(_candidateId) {
        require(!candidates[_candidateId].approved, "Already approved");
        
        candidates[_candidateId].approved = true;
        
        emit CandidateApproved(_candidateId, msg.sender, block.timestamp);
    }
    
    function rejectCandidate(uint256 _candidateId) external onlyElectionOfficer validCandidateId(_candidateId) {
        require(!candidates[_candidateId].approved, "Already approved");
        
        Candidate storage candidate = candidates[_candidateId];
        address candidateAddr = candidate.candidateAddress;
        uint256 deposit = candidate.securityDeposit;
        
        // Return security deposit
        payable(candidateAddr).transfer(deposit);
        
        emit CandidateRejected(_candidateId, msg.sender, block.timestamp);
    }
    
    function updateManifesto(string memory _newManifesto) external inPhase(ElectionPhase.CAMPAIGN) {
        uint256 candidateId = candidateAddressToId[msg.sender];
        require(candidateId > 0, "Not a registered candidate");
        require(candidates[candidateId].approved, "Candidate not approved");
        
        candidates[candidateId].manifesto = _newManifesto;
        
        emit ManifestoUpdated(candidateId, block.timestamp);
    }
    
    // ============ Voter Functions ============
    
    function registerVoter(
        string memory _name,
        uint256 _age,
        string memory _constituency
    ) external inPhase(ElectionPhase.VOTER_REG) {
        require(_age >= MIN_VOTING_AGE, "Below minimum voting age");
        require(voterAddressToId[msg.sender] == 0, "Already registered as voter");
        require(bytes(_name).length > 0, "Name required");
        
        voterCount++;
        
        voters[voterCount] = Voter({
            voterId: voterCount,
            name: _name,
            age: _age,
            constituency: _constituency,
            voterAddress: msg.sender,
            verified: false,
            hasVoted: false,
            votedFor: 0,
            registrationTime: block.timestamp
        });
        
        voterAddressToId[msg.sender] = voterCount;
        
        emit VoterRegistered(voterCount, _name, msg.sender, block.timestamp);
    }

    function verifyVoter(uint256 _voterId) external onlyElectionOfficer validVoterId(_voterId) {
        require(!voters[_voterId].verified, "Already verified");

        voters[_voterId].verified = true;

        emit VoterVerified(_voterId, msg.sender, block.timestamp);
    }

    function rejectVoter(uint256 _voterId) external onlyElectionOfficer validVoterId(_voterId) {
        require(!voters[_voterId].verified, "Already verified");

        emit VoterRejected(_voterId, msg.sender, block.timestamp);
    }

    // ============ Voting Functions ============

    function castVote(uint256 _candidateId) external inPhase(ElectionPhase.VOTING) nonReentrant validCandidateId(_candidateId) {
        uint256 voterId = voterAddressToId[msg.sender];
        require(voterId > 0, "Not a registered voter");

        Voter storage voter = voters[voterId];
        require(voter.verified, "Voter not verified");
        require(!voter.hasVoted, "Already voted");

        Candidate storage candidate = candidates[_candidateId];
        require(candidate.approved, "Candidate not approved");

        voter.hasVoted = true;
        voter.votedFor = _candidateId;
        candidate.voteCount++;
        totalVotes++;

        emit VoteCast(voterId, _candidateId, block.timestamp);
    }

    function castNotaVote() external inPhase(ElectionPhase.VOTING) nonReentrant {
        uint256 voterId = voterAddressToId[msg.sender];
        require(voterId > 0, "Not a registered voter");

        Voter storage voter = voters[voterId];
        require(voter.verified, "Voter not verified");
        require(!voter.hasVoted, "Already voted");

        voter.hasVoted = true;
        voter.votedFor = 0; // 0 represents NOTA
        notaVotes++;
        totalVotes++;

        emit NotaVoteCast(voterId, block.timestamp);
    }

    // ============ View Functions ============

    function getAllCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateCount);

        for (uint256 i = 1; i <= candidateCount; i++) {
            allCandidates[i - 1] = candidates[i];
        }

        return allCandidates;
    }

    function getApprovedCandidates() external view returns (Candidate[] memory) {
        uint256 approvedCount = 0;

        // Count approved candidates
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].approved) {
                approvedCount++;
            }
        }

        Candidate[] memory approvedCandidates = new Candidate[](approvedCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].approved) {
                approvedCandidates[index] = candidates[i];
                index++;
            }
        }

        return approvedCandidates;
    }

    function getCandidate(uint256 _candidateId) external view validCandidateId(_candidateId) returns (Candidate memory) {
        return candidates[_candidateId];
    }

    function getVoter(uint256 _voterId) external view validVoterId(_voterId) returns (Voter memory) {
        return voters[_voterId];
    }

    function getResults() external view returns (Candidate[] memory) {
        return this.getApprovedCandidates();
    }

    function getWinner() external view returns (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) {
        require(totalVotes > 0, "No votes cast yet");

        uint256 highestVotes = 0;
        uint256 winningCandidateId = 0;

        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].approved && candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }

        require(winningCandidateId > 0, "No winner yet");

        return (
            winningCandidateId,
            candidates[winningCandidateId].name,
            highestVotes
        );
    }

    function getElectionStatus() external view returns (string memory) {
        if (currentPhase == ElectionPhase.SETUP) return "Setup";
        if (currentPhase == ElectionPhase.CANDIDATE_REG) return "Candidate Registration";
        if (currentPhase == ElectionPhase.VOTER_REG) return "Voter Registration";
        if (currentPhase == ElectionPhase.CAMPAIGN) return "Campaign Period";
        if (currentPhase == ElectionPhase.VOTING) return "Voting Active";
        if (currentPhase == ElectionPhase.COUNTING) return "Counting Votes";
        if (currentPhase == ElectionPhase.RESULTS) return "Results Declared";
        return "Unknown";
    }

    function getVoterTurnout() external view returns (uint256 percentage) {
        if (voterCount == 0) return 0;
        return (totalVotes * 100) / voterCount;
    }

    function getElectionInfo() external view returns (
        string memory _electionName,
        string memory _constituency,
        ElectionPhase _phase,
        uint256 _candidateCount,
        uint256 _voterCount,
        uint256 _totalVotes,
        uint256 _notaVotes
    ) {
        return (
            electionName,
            constituency,
            currentPhase,
            candidateCount,
            voterCount,
            totalVotes,
            notaVotes
        );
    }

    function hasVoterVoted(address _voterAddress) external view returns (bool) {
        uint256 voterId = voterAddressToId[_voterAddress];
        if (voterId == 0) return false;
        return voters[voterId].hasVoted;
    }

    function isVoterVerified(address _voterAddress) external view returns (bool) {
        uint256 voterId = voterAddressToId[_voterAddress];
        if (voterId == 0) return false;
        return voters[voterId].verified;
    }

    function isCandidateApproved(address _candidateAddress) external view returns (bool) {
        uint256 candidateId = candidateAddressToId[_candidateAddress];
        if (candidateId == 0) return false;
        return candidates[candidateId].approved;
    }

    // ============ Emergency Functions ============

    function declareResults() external onlyCommissioner {
        require(currentPhase == ElectionPhase.COUNTING || currentPhase == ElectionPhase.VOTING, "Cannot declare results yet");

        currentPhase = ElectionPhase.RESULTS;

        if (totalVotes > 0) {
            (uint256 winnerId, string memory winnerName, uint256 voteCount) = this.getWinner();
            emit ResultsDeclared(winnerId, winnerName, voteCount, block.timestamp);
        }
    }

    function withdrawSecurityDeposits() external onlyCommissioner inPhase(ElectionPhase.RESULTS) {
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].approved && candidates[i].securityDeposit > 0) {
                uint256 deposit = candidates[i].securityDeposit;
                address candidateAddr = candidates[i].candidateAddress;
                candidates[i].securityDeposit = 0;

                payable(candidateAddr).transfer(deposit);
            }
        }
    }

    // ============ Fallback Functions ============

    receive() external payable {
        revert("Direct payments not accepted");
    }

    fallback() external payable {
        revert("Invalid function call");
    }
}

