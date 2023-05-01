// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract StandardCampaign {
    /// ***
    /// STRUCTS DECLARATIONS
    struct Campaign {
        // Description of the campaign
        string title;
        string metadata;
        CampaignStyle style;
        // Timestamps & status
        uint256 creationTime;
        uint256 deadline;
        CampaignStatus status;
        // Stakeholders
        address payable creator;
        // Stake
        uint256 stake;
        // Funding
        Fundings[] fundings;
        // Child projects
        uint256[] childProjectIDs;
    }

    // Mapping of campaign IDs to campaigns, IDs are numbers starting from 0
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    // Minimum stake required to create a campaign
    uint256 public minStake = 0.0025 ether;

    struct Project {
        // Description of the project
        string title;
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
    mapping(uint256 => Project) public projects;
    uint256 public projectCount = 0;

    struct Task {
        // Description of the task
        string title;
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
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount = 0;

    struct Fundings {
        address payable funder; // The address of the individual who contributed
        uint256 funding; // The amount of tokens the user contributed
        bool refunded; // A boolean storing whether or not the contribution has been refunded yet
    }

    enum CampaignStyle {
        Private,
        PrivateThenOpen,
        Open
    }

    enum CampaignStatus {
        Open,
        Closed
    }

    /// END OF STRUCTS DECLARATIONS
    /// ***

    /// ***
    /// CAMPAIGN WRITE FUNCTIONS
    // Create a new campaign
    function makeCampaign(
        string memory _title,
        string memory _metadata,
        CampaignStyle _style,
        uint256 _deadline,
        CampaignStatus _status,
        uint256 _stake
    ) public payable returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(
            _stake >= minStake,
            "Intended stake must be greater or equal to minStake"
        );
        require(
            msg.value == _stake,
            "Ether sent must be equal to intended stake"
        );

        Campaign storage campaign = campaigns[campaignCount];

        campaign.title = _title;
        campaign.metadata = _metadata;
        campaign.style = _style;
        campaign.creationTime = block.timestamp;
        campaign.deadline = _deadline;
        campaign.status = _status;
        campaign.creator = payable(msg.sender);
        campaign.stake = _stake;

        campaignCount++;

        return campaignCount - 1;
    }

    // Donate to a campaign
    function fundCampaign(uint256 _id, uint256 _funding) public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        require(
            msg.value == _funding,
            "Donation must be equal to intended funding"
        );

        Fundings memory newFunding;
        newFunding.funder = payable(msg.sender);
        newFunding.funding = msg.value;
        newFunding.refunded = false;

        Campaign storage campaign = campaigns[_id];
        campaign.fundings.push(newFunding);
    }

    // Create campaign and fund it
    function createAndFundCampaign(
        string memory _title,
        string memory _metadata,
        CampaignStyle _style,
        uint256 _deadline,
        CampaignStatus _status,
        uint256 _stake,
        uint256 _funding
    ) public payable returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(
            _stake >= minStake,
            "Intended stake must be greater or equal to minStake"
        );
        require(_funding > 0, "Funding must be greater than 0");
        require(
            _stake + _funding == msg.value,
            "Total sent must be equal to intended stake + funding"
        );

        Campaign storage campaign = campaigns[campaignCount];

        campaign.title = _title;
        campaign.metadata = _metadata;
        campaign.style = _style;
        campaign.creationTime = block.timestamp;
        campaign.deadline = _deadline;
        campaign.status = _status;
        campaign.creator = payable(msg.sender);
        campaign.stake = _stake;

        Fundings memory newFunding;
        newFunding.funder = payable(msg.sender);
        newFunding.funding = _funding;
        newFunding.refunded = false;
        campaign.fundings.push(newFunding);

        campaignCount++;
        return campaignCount - 1;
    }

    // Refund campaign funding
    function refundCampaignFunding(uint256 _id, bool _drainContract) public {
        require(_drainContract == true, "Just double checking.");

        Campaign storage campaign = campaigns[_id];

        for (uint256 i = 0; i < campaign.fundings.length; i++) {
            Fundings storage funding = campaign.fundings[i];

            if (funding.funder == msg.sender && funding.refunded == false) {
                funding.refunded = true;
                payable(msg.sender).transfer(funding.funding);
            }
        }
    }

    // Refund campaign stake
    function refundStake(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];
        require(
            msg.sender == campaign.creator,
            "Only the campaign creator can refund the stake"
        );
        require(campaign.stake > 0, "The campaign does not have a stake");

        uint256 stake = campaign.stake;
        campaign.stake = 0;
        campaign.creator.transfer(stake);
    }

    // Update campaign metadata
    function updateMetadata(uint256 _id, string memory _metadata) public {
        Campaign storage campaign = campaigns[_id];

        campaign.metadata = _metadata;
    }

    // Update campaign style
    function updateCampaignStyle(uint256 _id, CampaignStyle _style) public {
        Campaign storage campaign = campaigns[_id];

        campaign.style = _style;
    }

    // Update campaign deadline
    function updateCampaignDeadline(uint256 _id, uint256 _deadline) public {
        Campaign storage campaign = campaigns[_id];

        campaign.deadline = _deadline;
    }

    /// END OF CAMPAIGN WRITE FUNCTIONS
    /// ***

    /// ***
    /// CAMPAIGN READ FUNCTIONS
    // Get all campaigns
    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](campaignCount);

        for (uint256 i = 0; i < campaignCount; i++) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
    }

    // Get campaign donators & contributions
    function getFundingsOfCampaign(
        uint256 _id
    ) public view returns (Fundings[] memory) {
        return campaigns[_id].fundings;
    }

    /// END OF CAMPAIGN READ FUNCTIONS
    /// ***

    /// ***
    /// PROJECT WRITE FUNCTIONS
    // Create a new project
    function makeProject(
        string memory _title,
        string memory _metadata,
        uint256 _deadline,
        uint256 _parentCampaignID
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");

        Project storage project = projects[projectCount];

        project.title = _title;
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

        return projectCount - 1;
    }

    // ??? How can I resolve the single project/ single campaign issue ???
    /// END OF PROJECT WRITE FUNCTIONS
    /// ***

    /// ***
    /// TASK WRITE FUNCTIONS
    // Create a new task
    function makeTask(
        string memory _title,
        string memory _metadata,
        uint256 _deadline,
        uint256 _parentProjectID
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");

        Task storage task = tasks[taskCount];

        task.title = _title;
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

        return taskCount - 1;
    }

    /// END OF TASK WRITE FUNCTIONS
    /// ***

    /// ***
    /// DEVELOPER FUNCTIONS
    address public contractMaster;

    constructor() payable {
        contractMaster = payable(msg.sender);
    }

    function contractMasterDrain() public {
        require(
            msg.sender == contractMaster,
            "Only the contract master can drain the contract"
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    /// END OF DEVELOPER FUNCTIONS
    /// ***

    receive() external payable {}

    fallback() external payable {}
}
