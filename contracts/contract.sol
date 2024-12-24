// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransparentFundingPlatform {

    // Struct to represent a project
    struct Project {
        address payable owner;      // The project owner's address
        string name;                // The name of the project
        string description;         // A description of the project
        uint256 fundingGoal;        // The goal amount of funding (in wei)
        uint256 totalFunds;         // Total funds collected (in wei)
        uint256 deadline;           // Timestamp when funding ends
        bool goalReached;           // Flag to check if the goal is reached
    }

    // Mapping of project ID to Project
    mapping(uint256 => Project) public projects;
    uint256 public projectCount; // Counter for the number of projects

    // Event to log when a project is created
    event ProjectCreated(uint256 projectId, address owner, string name, uint256 fundingGoal, uint256 deadline);

    // Event to log when a donation is made to a project
    event FundsDonated(uint256 projectId, address donor, uint256 amount);

    // Event to log when funds are withdrawn by the project owner
    event FundsWithdrawn(uint256 projectId, address owner, uint256 amount);

    // Modifier to ensure that the caller is the project owner
    modifier onlyOwner(uint256 projectId) {
        require(msg.sender == projects[projectId].owner, "Only the project owner can call this.");
        _;
    }

    // Modifier to ensure that the funding goal has been reached
    modifier goalReached(uint256 projectId) {
        require(projects[projectId].goalReached, "Funding goal has not been reached.");
        _;
    }

    // Modifier to check if the funding deadline has passed
    modifier isFundingOpen(uint256 projectId) {
        require(block.timestamp < projects[projectId].deadline, "The funding deadline has passed.");
        _;
    }

    // Modifier to check if the funding period has ended
    modifier isFundingClosed(uint256 projectId) {
        require(block.timestamp >= projects[projectId].deadline, "Funding is still open.");
        _;
    }

    // Function to create a new project
    function createProject(string memory name, string memory description, uint256 fundingGoal, uint256 duration) public {
        require(fundingGoal > 0, "Funding goal must be greater than zero.");
        require(duration > 0, "Duration must be greater than zero.");

        uint256 projectId = projectCount++; // Increment project count and get the ID

        // Create the project
        projects[projectId] = Project({
            owner: payable(msg.sender),
            name: name,
            description: description,
            fundingGoal: fundingGoal,
            totalFunds: 0,
            deadline: block.timestamp + duration,
            goalReached: false
        });

        // Emit an event for project creation
        emit ProjectCreated(projectId, msg.sender, name, fundingGoal, block.timestamp + duration);
    }

    // Function to donate funds to a project
    function donate(uint256 projectId) public payable isFundingOpen(projectId) {
        Project storage project = projects[projectId];
        require(msg.value > 0, "Donation must be greater than zero.");

        // Increase the total funds of the project
        project.totalFunds += msg.value;

        // Check if the goal is reached
        if (project.totalFunds >= project.fundingGoal && !project.goalReached) {
            project.goalReached = true;
        }

        // Emit an event for the donation
        emit FundsDonated(projectId, msg.sender, msg.value);
    }

    // Function to withdraw funds (only if the goal is reached)
    function withdrawFunds(uint256 projectId) public onlyOwner(projectId) goalReached(projectId) isFundingClosed(projectId) {
        Project storage project = projects[projectId];
        uint256 amount = project.totalFunds;

        // Reset the project funds to 0
        project.totalFunds = 0;

        // Transfer the funds to the owner
        project.owner.transfer(amount);

        // Emit an event for the withdrawal
        emit FundsWithdrawn(projectId, project.owner, amount);
    }

    // Function to get the current funding status of a project
    function getProjectStatus(uint256 projectId) public view returns (
        string memory name,
        string memory description,
        uint256 fundingGoal,
        uint256 totalFunds,
        uint256 remainingTime,
        bool goalReached
    ) {
        Project storage project = projects[projectId];
        uint256 remainingTime = project.deadline > block.timestamp ? project.deadline - block.timestamp : 0;
        return (
            project.name,
            project.description,
            project.fundingGoal,
            project.totalFunds,
            remainingTime,
            project.goalReached
        );
    }
}
