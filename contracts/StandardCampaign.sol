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
        address payable[] owners;
        address payable[] acceptors;
        address payable[] workers;
        address payable[] allTimeStakeholders;
        // Stake
        uint256 stake;
        // Fundings (contains funders)
        Fundings[] fundings;
        // Child projects & All child projects (contains IDs)
        uint256[] directChildProjects;
        uint256[] allChildProjects;
    }

    // Mapping of campaign IDs to campaigns, IDs are numbers starting from 0
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    struct Project {
        // Description of the project
        string title;
        string metadata;
        // Contribution weight
        uint256 weight;
        // Timestamps
        uint256 creationTime;
        uint256 deadline;
        NextMilestone nextMilestone;
        ProjectStatus status;
        // Workers
        bool applicationRequired;
        uint256[] applications;
        address[] workers;
        address[] pastWorkers;
        // Parent Campaign & Project (contains IDs)
        uint256 parentCampaign;
        uint256 parentProject;
        // Child Tasks & Projects (contains IDs)
        uint256[] childProjects;
        uint256[] childTasks;
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
        address payable worker;
        // Completion
        bool completed;
        // Parent Campaign & Project (contains IDs)
        uint256 parentProject;
    }

    // Mapping of task IDs to tasks, IDs are numbers starting from 0
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount = 0;

    struct Application {
        // Description of the application
        string metadata;
        address applicant;
        bool accepted;
        Fundings enrolStake;
        // Parent Project (contains IDs)
        uint256 parentProject;
    }

    // Mapping of task IDs to tasks, IDs are numbers starting from 0
    mapping(uint256 => Application) public applications;
    uint256 public applicationCount = 0;

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
        Running,
        Closed
    }

    enum ProjectStatus {
        GenesisGate,
        Stage,
        Gate,
        Settled,
        Closed
    }

    struct NextMilestone {
        uint256 stageTimestamp;
        uint256 gateTimestamp;
        uint256 settledTimestamp;
    }

    // Minimum stake required to create a Private campaign
    uint256 public minStake = 0.0025 ether;
    // Minimum stake required to create an Open Campaign
    uint256 public minOpenCampaignStake = 0.025 ether;
    // Minimum stake required to enroll in a Project
    uint256 public enrolStake = 0.0025 ether;
    /// END OF STRUCTS DECLARATIONS
    /// ***

    /// ***
    /// MODIFIERS
    // Timestamps
    modifier isFutureTimestamp(uint256 timestamp) {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        _;
    }
    modifier isPastTimestamp(uint256 timestamp) {
        require(timestamp < block.timestamp, "Timestamp must be in the past");
        _;
    }

    // Does it exist?
    modifier isCampaignExisting(uint256 _id) {
        require(_id > campaignCount, "Campaign does not exist");
        _;
    }
    modifier isProjectExisting(uint256 _id) {
        require(_id > projectCount, "Project does not exist");
        _;
    }
    modifier isTaskExisting(uint256 _id) {
        require(_id > taskCount, "Task does not exist");
        _;
    }

    // Campaign Roles
    modifier isCampaignCreator(uint256 _id) {
        require(
            msg.sender == campaigns[_id].creator,
            "Sender must be the campaign creator"
        );
        _;
    }
    modifier isCampaignOwner(uint256 _id) {
        bool isOwner = false;
        for (uint256 i = 0; i < campaigns[_id].owners.length; i++) {
            if (msg.sender == campaigns[_id].owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Sender must be an owner of the campaign");
        _;
    }
    modifier isCampaignAcceptor(uint256 _id) {
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaigns[_id].acceptors.length; i++) {
            if (msg.sender == campaigns[_id].acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        require(isAcceptor, "Sender must be an acceptor of the campaign");
        _;
    }
    modifier isCampaignWorker(uint256 _id) {
        bool isWorker = false;
        for (uint256 i = 0; i < campaigns[_id].workers.length; i++) {
            if (msg.sender == campaigns[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        require(isWorker, "Sender must be a worker of the campaign");
        _;
    }
    modifier isCampaignStakeholder(uint256 _id) {
        bool isStakeholder = false;
        for (
            uint256 i = 0;
            i < campaigns[_id].allTimeStakeholders.length;
            i++
        ) {
            if (msg.sender == campaigns[_id].allTimeStakeholders[i]) {
                isStakeholder = true;
                break;
            }
        }
        require(isStakeholder, "Sender must be a stakeholder of the campaign");
        _;
    }

    // Campaign Styles
    modifier isCampaignOpen(uint256 _id) {
        require(
            campaigns[_id].style == CampaignStyle.Open,
            "Campaign must be open"
        );
        _;
    }
    modifier isCampaignPrivate(uint256 _id) {
        require(
            campaigns[_id].style == CampaignStyle.Private,
            "Campaign must be private"
        );
        _;
    }

    // Campaign Statuses
    modifier isCampaignRunning(uint256 _id) {
        require(
            campaigns[_id].status == CampaignStatus.Running,
            "Campaign must be running"
        );
        _;
    }
    modifier isCampaignClosed(uint256 _id) {
        require(
            campaigns[_id].status == CampaignStatus.Closed,
            "Campaign must be closed"
        );
        _;
    }

    // Project Statuses
    modifier isProjectGenesisGate(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.GenesisGate,
            "Project must be at genesis gate"
        );
        _;
    }
    modifier isProjectGate(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.Gate,
            "Project must be at gate"
        );
        _;
    }
    modifier isProjectStage(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.Stage,
            "Project must be at stage"
        );
        _;
    }
    modifier isProjectSettled(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.Settled,
            "Project must be settled"
        );
        _;
    }
    modifier isProjectRunning(uint256 _id) {
        require(
            projects[_id].status != ProjectStatus.Closed,
            "Project must be running"
        );
        if (
            campaigns[projects[_id].parentCampaign].style ==
            CampaignStyle.Private
        ) {
            require(
                projects[_id].deadline >= block.timestamp,
                "Private campaign projects must be before deadline to be running"
            );
        }
        _;
    }
    modifier isProjectClosed(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.Closed,
            "Project must be closed"
        );
        _;
    }
    modifier isApplicationExisting(uint256 _id) {
        require(_id < applicationCount, "Application does not exist");
        _;
    }

    // Project Roles
    modifier isWorkerOnProject(uint256 _id) {
        bool isWorker = false;
        for (uint256 i = 0; i < projects[_id].workers.length; i++) {
            if (msg.sender == projects[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        require(isWorker, "Sender must be a worker on the project");
        _;
    }

    // Task Roles
    modifier isWorkerOnTask(uint256 _id) {
        require(
            msg.sender == tasks[_id].worker,
            "Sender must be the task worker"
        );
        _;
    }

    // Stake & Funding
    modifier isMoneyIntended(uint256 _money) {
        require(
            msg.value == _money && _money > 0,
            "Ether sent must be equal to intended funding"
        );
        _;
    }
    modifier isStakeAndFundingIntended(uint256 _stake, uint256 _funding) {
        require(
            msg.value == _stake + _funding,
            "Ether sent must be equal to intended stake"
        );
        _;
    }
    modifier isMoreThanMinStake(uint256 _stake) {
        require(
            _stake >= minStake,
            "Intended stake must be greater or equal to minStake"
        );
        _;
    }
    modifier isMoreThanEnrolStake(uint256 _stake) {
        require(
            _stake >= enrolStake,
            "Intended stake must be greater or equal to enrolStake"
        );
        _;
    }

    /// END OF MODIFIERS
    /// ***

    /// ***
    /// CAMPAIGN WRITE FUNCTIONS

    /// OPEN-PRIVATE DUAL USE FUNCTIONS
    // Create a new campaign, optionally fund it ✅
    function makeCampaign(
        string memory _title,
        string memory _metadata,
        CampaignStyle _style,
        uint256 _deadline,
        address payable[] memory _owners,
        address payable[] memory _acceptors,
        uint256 _stake,
        uint256 _funding
    )
        public
        payable
        isMoreThanMinStake(_stake)
        isStakeAndFundingIntended(_stake, _funding)
        returns (uint256)
    {
        //PRIVATE CAMPAIGN REQ (open campaigns don't have deadlines)
        if (
            _style == CampaignStyle.Private ||
            _style == CampaignStyle.PrivateThenOpen
        ) {
            require(
                _deadline > block.timestamp,
                "Deadline must be in the future"
            );
        }

        Campaign storage campaign = campaigns[campaignCount];

        campaign.title = _title;
        campaign.metadata = _metadata;
        campaign.style = _style;
        campaign.creationTime = block.timestamp;
        campaign.deadline = _deadline;
        campaign.status = CampaignStatus.Running;
        campaign.creator = payable(msg.sender);
        campaign.owners.push(payable(msg.sender));
        for (uint256 i = 0; i < _owners.length; i++) {
            campaign.owners.push((_owners[i]));
            campaign.allTimeStakeholders.push((_owners[i]));
        }
        for (uint256 i = 0; i < _acceptors.length; i++) {
            campaign.acceptors.push((_acceptors[i]));
            campaign.allTimeStakeholders.push((_acceptors[i]));
        }
        campaign.allTimeStakeholders.push(payable(msg.sender));
        campaign.stake = _stake;

        if (_funding > 0) {
            Fundings memory newFunding;
            newFunding.funder = payable(msg.sender);
            newFunding.funding = _funding;
            newFunding.refunded = false;
            campaign.fundings.push(newFunding);
        }

        campaignCount++;
        return campaignCount - 1;
    }

    // Donate to a campaign ✅
    function fundCampaign(
        uint256 _id,
        uint256 _funding
    ) public payable isMoneyIntended(_funding) {
        Fundings memory newFunding;
        newFunding.funder = payable(msg.sender);
        newFunding.funding = _funding;
        newFunding.refunded = false;

        Campaign storage campaign = campaigns[_id];
        campaign.fundings.push(newFunding);
    }

    /// PRIVATE CAMPAIGN FUNCTIONS
    // Refund campaign funding ⚠️ (needs checking for locked funds!!!)
    function refundCampaignFunding(
        uint256 _id,
        bool _drainCampaign
    ) public isCampaignPrivate(_id) isCampaignOwner(_id) {
        require(_drainCampaign == true, "Just double checking.");

        Campaign storage campaign = campaigns[_id];

        for (uint256 i = 0; i < campaign.fundings.length; i++) {
            Fundings storage funding = campaign.fundings[i];

            if (funding.funder == msg.sender && funding.refunded == false) {
                funding.refunded = true;
                payable(msg.sender).transfer(funding.funding);
            }
        }
    }

    // Refund closed campaign stake ✅
    function refundStake(
        uint256 _id
    )
        public
        isCampaignPrivate(_id)
        isCampaignClosed(_id)
        isCampaignCreator(_id)
    {
        Campaign storage campaign = campaigns[_id];
        require(campaign.stake > 0, "The campaign does not have a stake");

        uint256 stake = campaign.stake;
        campaign.stake = 0;
        campaign.creator.transfer(stake);
    }

    // Update Campaign ⚠️
    function updateCampaign(
        uint256 _id,
        string memory _title,
        string memory _metadata,
        CampaignStyle _style,
        uint256 _deadline,
        CampaignStatus _status,
        address payable[] memory _owners,
        address payable[] memory _acceptors
    )
        public
        isCampaignPrivate(_id)
        isCampaignOwner(_id)
        isFutureTimestamp(_deadline)
    {
        require(
            _owners.length > 0,
            "Campaign must have at least one owner at all times"
        );
        if (_status == CampaignStatus.Closed) {
            // require that all projects inside are closed
            for (
                uint256 i = 0;
                i < campaigns[_id].allChildProjects.length;
                i++
            ) {
                require(
                    projects[campaigns[_id].allChildProjects[i]].status ==
                        ProjectStatus.Closed,
                    "Projects must be closed"
                );
            }
        }

        Campaign storage campaign = campaigns[_id];

        campaign.title = _title; //✅
        campaign.metadata = _metadata; //✅
        campaign.style = _style; //❌ (needs all private-to-open effects for transition)
        campaign.deadline = _deadline; //⚠️ (can't be less than maximum settled time of current stage of contained projects)
        campaign.status = _status; //⚠️ (can't be closed if there are open projects)
        campaign.owners = _owners; //✅
        campaign.acceptors = _acceptors; //✅
    }

    /// END OF CAMPAIGN WRITE FUNCTIONS
    /// ***

    /// ***
    /// PROJECT WRITE FUNCTIONS
    // Create a new project ⚠️
    function makeProject(
        string memory _title,
        string memory _metadata,
        uint256 _deadline,
        bool _applicationRequired,
        uint256 _parentCampaign,
        uint256 _parentProject
    )
        public
        isFutureTimestamp(_deadline)
        isCampaignExisting(_parentCampaign)
        returns (uint256)
    {
        Project storage project = projects[projectCount];

        project.title = _title;
        project.metadata = _metadata;
        project.creationTime = block.timestamp;
        project.deadline = _deadline; // warning: deadline can't be earlier than latest task deadline + settling time
        project.status = ProjectStatus.GenesisGate;

        if (campaigns[_parentCampaign].style == CampaignStyle.Open) {
            project.applicationRequired = false;
        } else {
            project.applicationRequired = _applicationRequired;
        }

        // Parent Campaign
        project.parentCampaign = _parentCampaign;
        project.parentProject = _parentProject; // references itself if at the top level

        if (_parentProject != projectCount) {
            // If this is not the top level project, add it to the parent project
            projects[_parentProject].childProjects.push(projectCount);
        } else {
            // If this is a top level project, add it in the parent campaign
            campaigns[_parentCampaign].directChildProjects.push(projectCount);
        }

        campaigns[_parentCampaign].allChildProjects.push(projectCount);

        projectCount++;
        return projectCount - 1;
    }

    // Update project STATUS messy af fixfixfix ⚠️
    function updateProjectStatus(
        uint256 _id,
        ProjectStatus _nextStatus
    )
        public
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        isCampaignOwner(projects[_id].parentCampaign)
    {
        require(
            _nextStatus != ProjectStatus.GenesisGate,
            "Projects cannot be reverted to genesis gate"
        );

        Project storage project = projects[_id];

        if (_nextStatus == ProjectStatus.Stage) {
            require(
                project.status == ProjectStatus.GenesisGate ||
                    project.status == ProjectStatus.Settled,
                "Project must have settled previous stage"
            );
            if (project.status == ProjectStatus.GenesisGate) {
                require(
                    project.workers.length > 0,
                    "Project must have workers"
                );
            }
        } else if (_nextStatus == ProjectStatus.Settled) {
            require(
                project.status == ProjectStatus.Gate,
                "Project must currently be at gate"
            );
        } else if (_nextStatus == ProjectStatus.Gate) {
            require(
                project.status == ProjectStatus.Stage,
                "Project must currently be at stage"
            );
        } else if (_nextStatus == ProjectStatus.Closed) {
            require(
                project.status == ProjectStatus.Settled,
                "Project must currently be settled"
            );
        }
        project.status = _nextStatus;
    }

    // Apply to project ✅
    function applyToProject(
        uint256 _id,
        string memory _metadata,
        uint256 _stake
    )
        public
        payable
        isCampaignRunning(projects[_id].parentCampaign)
        isProjectExisting(_id)
        isProjectRunning(_id)
        isMoneyIntended(_stake)
        isMoreThanEnrolStake(_stake)
        returns (uint256)
    {
        Project storage project = projects[_id];
        require(
            project.applicationRequired,
            "Project does not require applications"
        );

        Application storage application = applications[applicationCount];
        application.metadata = _metadata;
        application.applicant = msg.sender;
        application.accepted = false;
        application.enrolStake.funder = payable(msg.sender);
        application.enrolStake.funding = _stake;
        application.enrolStake.refunded = false;
        application.parentProject = _id;

        project.applications.push(applicationCount);
        applicationCount++;
        return applicationCount - 1;
    }

    // Application decision by acceptors ✅
    function applicationDecision(
        uint256 _applicationID,
        bool _accepted
    )
        public
        isProjectExisting(applications[_applicationID].parentProject)
        isCampaignAcceptor(
            projects[applications[_applicationID].parentProject].parentCampaign
        )
        isApplicationExisting(_applicationID)
    {
        Application storage application = applications[_applicationID];
        Project storage project = projects[application.parentProject];
        Campaign storage campaign = campaigns[project.parentCampaign];
        // if project or campaign is closed, decline or if project is past its deadline, decline
        // also refund stake
        if (
            project.status == ProjectStatus.Closed ||
            project.deadline < block.timestamp ||
            campaigns[project.parentCampaign].status == CampaignStatus.Closed ||
            !_accepted
        ) {
            applications[_applicationID].accepted = false;
            applications[_applicationID].enrolStake.refunded = true;
            deleteItemInUintArray(_applicationID, project.applications);
            payable(msg.sender).transfer(
                applications[_applicationID].enrolStake.funding
            );
            return;
        } else if (_accepted) {
            project.workers.push(application.applicant);
            campaign.allTimeStakeholders.push(payable(application.applicant));
            campaign.workers.push(payable(application.applicant));
            application.accepted = true;
            // deleteItemInUintArray(_applicationID, project.applications); maybe??
        }
    }

    // Pattern for deleting stuff from stuff ✅
    function deleteItemInUintArray(
        uint256 _ItemID,
        uint256[] storage _array
    ) internal {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemID) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
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
        task.parentProject = _parentProjectID;
        projects[_parentProjectID].childTasks.push(taskCount);

        // If this is the only task in the project, give it maximum weight of 1000
        if ((projects[_parentProjectID].childTasks.length) == 0) {
            task.weight = 1000;
        }

        taskCount++;

        return taskCount - 1;
    }

    /// END OF TASK WRITE FUNCTIONS
    /// ***

    /// ***
    /// CAMPAIGN READ FUNCTIONS
    // Get all campaigns ✅
    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](campaignCount);
        for (uint256 i = 0; i < campaignCount; i++) {
            _campaigns[i] = campaigns[i];
        }
        return _campaigns;
    }

    // Get campaign by ID ✅
    function getCampaignByID(
        uint256 _id
    ) public view returns (Campaign memory) {
        return campaigns[_id];
    }

    // Get campaign funders & contributions ❓(is this needed when we have getCampaignByID?)
    function getFundingsOfCampaign(
        uint256 _id
    ) public view returns (Fundings[] memory) {
        return campaigns[_id].fundings;
    }

    /// END OF CAMPAIGN READ FUNCTIONS
    /// ***

    /// ***
    /// DEVELOPER FUNCTIONS (ONLY FOR TESTING) 🧑‍💻🧑‍💻🧑‍💻🧑‍💻🧑‍💻
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
