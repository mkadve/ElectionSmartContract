// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public admin;
    enum ElectionState { NOT_STARTED, ONGOING, ENDED }
    ElectionState public electionState;
    
    struct Candidate {
        string name;
        string proposal;
        uint votes;
    }
    
    struct Voter {
        bool hasVoted;
        bool hasDelegated;
        address delegate;
        uint votedFor; // Candidate ID
        string name; // Voter's name
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => Voter) public voters;
    address[] public voterAddresses; // Array to store voter addresses
    
    uint public numCandidates;
    uint public numVoters;
    uint[] public winningCandidateIds; // Array to store winning candidate IDs
    uint public winningVotes;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyDuringElection() {
        require(electionState == ElectionState.ONGOING, "Election is not ongoing");
        _;
    }

    modifier onlyNotVoted(address _voter) {
        require(!voters[_voter].hasVoted, "Voter has already voted");
        _;
    }

    modifier onlyNotDelegated(address _voter) {
        require(!voters[_voter].hasDelegated, "Voter has already delegated the vote");
        _;
    }

    modifier onlyDelegated(address _voter) {
        require(voters[_voter].hasDelegated, "Voter has not delegated the vote");
        _;
    }

    event ElectionStarted();
    event ElectionEnded();
    event VoteCasted(address indexed voter, uint candidateId);
    event VoteDelegated(address indexed delegator, address indexed delegate);
    event CandidateAdded(uint indexed candidateId, string name, string proposal);
    event NewVoterAdded(address indexed voter);

    constructor() {
        admin = msg.sender;
        electionState = ElectionState.NOT_STARTED;
    }

    function addCandidate(string memory _name, string memory _proposal) external onlyAdmin {
        require(electionState == ElectionState.NOT_STARTED, "Cannot add candidate after the election has started");
        candidates[numCandidates] = Candidate(_name, _proposal, 0);
        emit CandidateAdded(numCandidates, _name, _proposal);
        numCandidates++;
    }

    function addVoter(address _voter, string memory _name) external onlyAdmin {
        require(electionState == ElectionState.NOT_STARTED, "Cannot add a voter after the election has started");
        
        // Check if voter address already exists
        for (uint i = 0; i < numVoters; i++) {
            require(voterAddresses[i] != _voter, "Voter already added");
        }

        voters[_voter] = Voter(false, false, address(0), 0, _name);
        voterAddresses.push(_voter);
        numVoters++;
        
        emit NewVoterAdded(_voter);
    }

    function startElection() external onlyAdmin {
        require(electionState == ElectionState.NOT_STARTED, "Election has already started");
        electionState = ElectionState.ONGOING;
        emit ElectionStarted();
    }

    function castVote(uint _candidateId) external onlyDuringElection onlyNotVoted(msg.sender) {
        require(_candidateId < numCandidates, "Invalid candidate ID");
        candidates[_candidateId].votes++;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedFor = _candidateId;
        emit VoteCasted(msg.sender, _candidateId);
    }

    function delegateVote(address _delegate) external onlyDuringElection onlyNotVoted(msg.sender) onlyNotDelegated(msg.sender) {
        require(_delegate != msg.sender, "Cannot delegate a vote to yourself");
        voters[msg.sender].hasDelegated = true;
        voters[msg.sender].delegate = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    function endElection() external onlyAdmin {
        require(electionState == ElectionState.ONGOING, "Election has not started");
        electionState = ElectionState.ENDED;

        // Calculate the winner(s)
        uint maxVotes = 0;
        for (uint i = 0; i < numCandidates; i++) {
            if (candidates[i].votes > maxVotes) {
                winningVotes = candidates[i].votes;
                delete winningCandidateIds; // Clear previous winners
                winningCandidateIds.push(i);
                maxVotes = candidates[i].votes;
            } else if (candidates[i].votes == maxVotes) {
                winningCandidateIds.push(i);
            }
        }

        emit ElectionEnded();
    }

    function getCandidateDetails(uint _candidateId) external view returns (uint, string memory, string memory) {
        require(_candidateId < numCandidates, "Invalid candidate ID");
        return (_candidateId, candidates[_candidateId].name, candidates[_candidateId].proposal);
    }

    function getWinnerDetails() external view returns (uint[] memory, string[] memory, uint) {
        require(electionState == ElectionState.ENDED, "Election has not ended");

        uint numWinners = winningCandidateIds.length;
        string[] memory winnerNames = new string[](numWinners);

        for (uint i = 0; i < numWinners; i++) {
            winnerNames[i] = candidates[winningCandidateIds[i]].name;
        }

        return (winningCandidateIds, winnerNames, winningVotes);
    }

    function getVoterDetails(address _voter) external view returns (string memory, uint, bool) {
        return (voters[_voter].name, voters[_voter].votedFor, voters[_voter].hasDelegated);
    }

    function viewVoterProfile(address _voter) external view returns (bool, bool, address, uint, string memory) {
        return (voters[_voter].hasVoted, voters[_voter].hasDelegated, voters[_voter].delegate, voters[_voter].votedFor, voters[_voter].name);
    }
}
