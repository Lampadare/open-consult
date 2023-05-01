// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract StandardCampaign {

    address public contractMaster;

    constructor() {
        contractMaster = payable(msg.sender);
    }

    //// STRUCTS DECLARATIONS ////
    struct Campaign {
        // Description of the campaign
        string title;
        string description;
        string metadata;
        uint8 campaignStyle; // 0 = public, 1 = semi-private, 2 = private

        // Timestamps
        uint256 creationTime;
        uint256 deadline;

        // Stakeholders
        address payable creator;

        // Funding
        Fundings[] fundings;

        // Child projects
        uint256[] childProjectIDs;
    }

    // Mapping of campaign IDs to campaigns, IDs are numbers starting from 0
    mapping (uint256 => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    struct Project {
        // Description of the project
        string title;
        string description;
        string metadata;
        
        // Contribution weight
        uint256 weight;

        // Timestamps
        uint256 creationTime;
        uint256 deadline;

        // Workers
        address[] workers;

        // Completion Level
        uint256 completionLevel;

        // Child Tasks it contains
        uint256[] childTaskIDs;

        // Parent campaign
        uint256 parentCampaignID;
    }

    // Mapping of project IDs to projects, IDs are numbers starting from 0
    mapping (uint256 => Project) public projects;
    uint256 public projectCount = 0;

    struct Task {
        // Description of the task
        string title;
        string description;
        string metadata;

        // Contribution weight
        uint256 weight;

        // Timestamps
        uint256 creationTime;
        uint256 deadline;

        // Worker
        address payable workerAssigned;

        // Completion
        bool completed;

        // Parent projectOk
        uint256 parentProjectID;
    }

    // Mapping of task IDs to tasks, IDs are numbers starting from 0
    mapping (uint256 => Task) public tasks;
    uint256 public taskCount = 0;

    struct Fundings {
        address payable funder; // The address of the individual who contributed
        uint256 funding; // The amount of tokens the user contributed
        bool refunded; // A boolean storing whether or not the contribution has been refunded yet
    }
    ////========================////

    
    // Create a new campaign
    function makeCampaign(string memory _title, string memory _description, 
    string memory _metadata, uint8 _campaignStyle, uint256 _deadline) public returns (uint256) {

        Campaign storage campaign = campaigns[campaignCount];

        require (_deadline > block.timestamp, "Deadline must be in the future");

        campaign.title = _title;
        campaign.description = _description;
        campaign.metadata = _metadata;
        campaign.campaignStyle = _campaignStyle;
        campaign.creationTime = block.timestamp;
        campaign.deadline = _deadline;
        campaign.creator = payable(msg.sender);

        campaignCount++;

        return campaignCount-1;
    }

    // Create a new project
    function makeProject(string memory _title, string memory _description,
    string memory _metadata, uint256 _deadline, uint256 _parentCampaignID) public returns (uint256) {

        Project storage project = projects[projectCount];

        require (_deadline > block.timestamp, "Deadline must be in the future");

        project.title = _title;
        project.description = _description;
        project.metadata = _metadata;
        project.creationTime = block.timestamp;
        project.deadline = _deadline;

        // Add parent campaign to project and vice versa
        project.parentCampaignID = _parentCampaignID;
        campaigns[_parentCampaignID].childProjectIDs.push(projectCount);

        // If this is the only project in the campaign, give it maximum weight of 1000
        if ((campaigns[_parentCampaignID].childProjectIDs.length) == 0) {
            project.weight = 1000;
        }

        projectCount++;

        return projectCount-1;
    }
    // ??? How can I resolve the single project/ single campaign issue ???

    // Create a new task
    function makeTask(string memory _title, string memory _description,
    string memory _metadata, uint256 _deadline, uint256 _parentProjectID) public returns (uint256) {

        Task storage task = tasks[taskCount];

        require (_deadline > block.timestamp, "Deadline must be in the future");

        task.title = _title;
        task.description = _description;
        task.metadata = _metadata;
        task.creationTime = block.timestamp;
        task.deadline = _deadline;
        task.completed = false;

        // Add parent project to task and vice versa
        task.parentProjectID = _parentProjectID;
        projects[_parentProjectID].childTaskIDs.push(taskCount);

        // If this is the only task in the project, give it maximum weight of 1000
        if ((projects[_parentProjectID].childTaskIDs.length) == 0) {
            task.weight = 1000;
        }

        taskCount++;

        return taskCount-1;
    }

    // Donate to a campaign
    function donateToCampaign(uint256 _id) public payable {
        require(msg.value > 0, "Donation must be greater than 0");

        Fundings memory newFunding;
        newFunding.funder = payable(msg.sender);
        newFunding.funding = msg.value;
        newFunding.refunded = false;

        Campaign storage campaign = campaigns[_id];
        campaign.fundings.push(newFunding);
    }

    // Create campaign and fund it
    function createAndFundCampaign(string memory _title, string memory _description,
    string memory _metadata, uint8 _campaignStyle, uint256 _deadline) public payable returns (uint256) {

        uint256 campaignID = makeCampaign(_title, _description, _metadata, _campaignStyle, _deadline);

        donateToCampaign(campaignID);

        return campaignID;
    }

    // Get campaign donators & contributions
    function getCampaignFundings(uint256 _id) public view returns (Fundings[] memory) {
        return campaigns[_id].fundings;
    }

    // Get all campaigns
    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](campaignCount);

        for (uint256 i = 0; i < campaignCount; i++) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
    }

    // Update campaign metadata
    function updateMetadata(uint256 _id, string memory _metadata) public {
        Campaign storage campaign = campaigns[_id];

        campaign.metadata = _metadata;
    }

    // Refund campaign funding
    function refundCampaignFunding(uint256 _id, bool _drainContract) public {
        require(_drainContract == true, "Just double checking.");
        
        Campaign storage campaign = campaigns[_id];

        for (uint256 i = 0; i < campaign.fundings.length; i++) {
            Fundings memory funding = campaign.fundings[i];

            if (funding.funder == msg.sender && funding.refunded == false) {
                funding.refunded = true;
                payable(msg.sender).transfer(funding.funding);
            }
        }
    }


    // DEVELOPER FUNCTIONS
    function contractMasterDrain() public {
        require(msg.sender == contractMaster, "Only the contract master can drain the contract");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}