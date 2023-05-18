// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract StandardCampaign {
    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// STRUCTS DECLARATIONS
    struct Campaign {
        // Description of the campaign
        string title;
        string metadata;
        CampaignStyle style;
        // Timestamps & status
        uint256 creationTime;
        //uint256 deadline;
        CampaignStatus status;
        // Stakeholders
        address payable creator;
        address payable[] owners;
        address payable[] acceptors;
        address payable[] workers;
        address payable[] allTimeStakeholders;
        // Stake
        Fundings stake;
        // Fundings (contains funders)
        Fundings[] fundings;
        uint256 lockedRewards;
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
        Vote[] fastForward;
        NextMilestone nextMilestone;
        ProjectStatus status;
        // Workers & Applications
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
        uint256 reward;
        bool paid;
        // Timestamps
        uint256 creationTime;
        uint256 deadline;
        // Worker
        address payable worker;
        // Completion
        Submission submission;
        bool closed;
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

    struct Submission {
        string metadata;
        SubmissionStatus status;
    }

    struct Fundings {
        address payable funder; // The address of the individual who contributed
        uint256 funding; // The amount of tokens the user contributed
        bool refunded; // A boolean storing whether or not the contribution has been refunded yet
    }

    struct NextMilestone {
        uint256 startStageTimestamp;
        uint256 startGateTimestamp;
        uint256 startSettledTimestamp;
    }

    struct Vote {
        address voter;
        bool vote;
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
        Stage,
        Gate,
        Settled,
        Closed
    }

    enum TaskStatusFilter {
        NotClosed,
        Closed,
        All
    }

    enum SubmissionStatus {
        None,
        Pending,
        Accepted,
        Declined
    }

    // Minimum stake required to create a Private campaign
    uint256 public minStake = 0.0025 ether;
    // Minimum stake required to create an Open Campaign
    uint256 public minOpenCampaignStake = 0.025 ether;
    // Minimum stake required to enroll in a Project
    uint256 public enrolStake = 0.0025 ether;

    // Minimum time to settle a project
    uint256 public minimumSettledTime = 1 days;
    // Minimum time to gate a project
    uint256 public minimumGateTime = 2 days;
    // Within gate, maximum time to decide on submissions
    uint256 public taskSubmissionDecisionTime = 1 days;
    // Within stage, maximum time to dispute a submission decision
    uint256 public taskSubmissionDecisionDisputeTime = 2 days;

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
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
        require(_id < campaignCount, "Campaign does not exist");
        _;
    }
    modifier isProjectExisting(uint256 _id) {
        require(_id < projectCount, "Project does not exist");
        _;
    }
    modifier isTaskExisting(uint256 _id) {
        require(_id < taskCount, "Task does not exist");
        _;
    }
    modifier isApplicationExisting(uint256 _id) {
        require(_id < applicationCount, "Application does not exist");
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
        require(
            checkIsCampaignOwner(_id),
            "Sender must be an owner of the campaign"
        );
        _;
    }
    modifier isCampaignAcceptor(uint256 _id) {
        require(
            checkIsCampaignAcceptor(_id),
            "Sender must be an acceptor of the campaign"
        );
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
        _;
    }
    modifier isProjectClosed(uint256 _id) {
        require(
            projects[_id].status == ProjectStatus.Closed,
            "Project must be closed"
        );
        _;
    }

    // Task Statuses
    modifier isTaskClosed(uint256 _id) {
        require(tasks[_id].closed, "Task must be closed");
        _;
    }
    modifier isTaskNotClosed(uint256 _id) {
        require(!tasks[_id].closed, "Task must not be closed");
        _;
    }

    // Lazy Project Status Updater
    modifier lazyStatusUpdaterStart(uint256 _id) {
        statusFixer(_id);
        _;
    }
    modifier lazyStatusUpdaterEnd(uint256 _id) {
        _;
        statusFixer(_id);
    }

    // Project Roles
    modifier isProjectWorker(uint256 _id) {
        require(
            checkIsProjectWorker(_id),
            "Sender must be a worker on the project"
        );
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

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// CAMPAIGN WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
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
        //campaign.deadline = _deadline;
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
        campaign.stake.funding = _stake;
        campaign.stake.funder = payable(msg.sender);
        campaign.stake.refunded = false;

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
        require(!campaign.stake.refunded, "Stake already refunded");

        uint256 stake = campaign.stake.funding;
        campaign.stake.refunded = true;
        campaign.creator.transfer(stake);
    }

    // Update Campaign ⚠️
    function updateCampaign(
        uint256 _id,
        string memory _title,
        string memory _metadata,
        // CampaignStyle _style,
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
        //campaign.style = _style; //❌ (needs all private-to-open effects for transition)
        //campaign.deadline = _deadline; //⚠️ (can't be less than maximum settled time of current stage of contained projects)
        campaign.status = _status; //⚠️ (can't be closed if there are open projects)
        campaign.owners = _owners; //✅
        campaign.acceptors = _acceptors; //✅
    }

    /// 🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳
    /// CAMPAIGN READ FUNCTIONS 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
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

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// PROJECT WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
    // Create a new project ✅
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
        require(
            _parentProject <= projectCount + 1,
            "Parent project must exist or be the next top-level project to be created"
        );
        Project storage project = projects[projectCount];
        Campaign storage parentCampaign = campaigns[_parentCampaign];

        // Populate project
        project.title = _title;
        project.metadata = _metadata;
        project.creationTime = block.timestamp;
        project.status = ProjectStatus.Gate;
        project.nextMilestone = NextMilestone(0, 0, 0);

        // Open campaigns don't require applications
        if (parentCampaign.style == CampaignStyle.Open) {
            project.applicationRequired = false;
        } else {
            project.applicationRequired = _applicationRequired;
        }

        // In THIS project being created, set the parent campaign and project
        project.parentCampaign = _parentCampaign;
        project.parentProject = _parentProject; // !!! references itself if at the top level

        // In the PARENTS of THIS project being created, add THIS project to the child projects
        if (_parentProject < projectCount) {
            // If this is not the top level project, add it to the parent project
            projects[_parentProject].childProjects.push(projectCount);
        } else {
            // If this is a top level project, add it in the parent campaign
            parentCampaign.directChildProjects.push(projectCount);
        }

        // Reference project in campaign
        campaigns[_parentCampaign].allChildProjects.push(projectCount);

        projectCount++;
        return projectCount - 1;
    }

    // Close project ✅
    function closeProject(
        uint256 _id
    )
        public
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        isCampaignOwner(projects[_id].parentCampaign)
    {
        Project storage project = projects[_id];
        require(
            project.status == ProjectStatus.Gate,
            "Project must currently be at gate"
        );
        require(
            checkIsCampaignOwner(project.parentCampaign),
            "Sender must be an owner of the campaign"
        );

        // Just to clear any loose ends
        goToSettledStatus(_id, 0, 1, 2);

        project.status = ProjectStatus.Closed;

        // Clear fast forward votes
        delete project.fastForward;
    }

    // Go to settled ✅
    function goToSettledStatus(
        uint _id,
        uint256 _nextStageStartTimestamp,
        uint256 _nextGateStartTimestamp,
        uint256 _nextSettledStartTimestamp
    )
        public
        isProjectExisting(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        isProjectRunning(_id)
        isProjectGate(_id)
    {
        Project storage project = projects[_id];

        // Check conditions for going to settled
        require(toSettledConditions(_id), "Project cannot go to settled");
        // Ensure sender is an owner of the campaign
        require(
            checkIsCampaignOwner(project.parentCampaign),
            "Sender must be an owner of the campaign"
        );

        // Ensure timestamps are in order
        require(
            _nextSettledStartTimestamp > _nextGateStartTimestamp &&
                _nextGateStartTimestamp > _nextStageStartTimestamp,
            "_nextGateStartTimestamp must be after _nextStageStartTimestamp"
        );

        // Pay submissions with no decisions
        payLatePendingSubmissions(_id);

        // Get NotClosed tasks
        Task[] memory notClosedTasks = getTasksOfProjectClosedFilter(
            _id,
            TaskStatusFilter.NotClosed
        );

        // Get latest task deadline
        uint256 latestTaskDeadline = 0;
        for (uint256 i = 0; i < project.childTasks.length; i++) {
            if (notClosedTasks[i].deadline > latestTaskDeadline) {
                latestTaskDeadline = notClosedTasks[i].deadline;
            }
        }

        // Update project milestones
        typicalProjectMilestonesUpdate(
            _id,
            _nextStageStartTimestamp,
            _nextGateStartTimestamp,
            _nextSettledStartTimestamp,
            latestTaskDeadline
        );

        // If task deadline is before timestamp of stage start and uncompleted
        // then update deadline of task to be max of stage start and latest task deadline
        // At this point, all deadlines should be between stage start and gate start
        for (uint256 i = 0; i < notClosedTasks.length; i++) {
            if (
                notClosedTasks[i].deadline <
                project.nextMilestone.startStageTimestamp
            ) {
                notClosedTasks[i].deadline = max(
                    project.nextMilestone.startGateTimestamp - 1 seconds,
                    latestTaskDeadline
                );
            }
        }

        // Update project status
        project.status = ProjectStatus.Settled;

        // Clear fast forward votes
        delete project.fastForward;

        // If campaign should be closed then update campaign status and project status
        // if (
        //     parentCampaign.deadline < project.nextMilestone.startStageTimestamp
        // ) {
        //     parentCampaign.status = CampaignStatus.Closed;
        //     project.status = ProjectStatus.Closed;
        // }
    }

    // Update project STATUS ✅
    function updateProjectStatus(
        uint256 _id
    )
        public
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
    {
        Project storage project = projects[_id];

        // GOING INTO STAGE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
        if (project.status == ProjectStatus.Settled) {
            if (toStageFastForwardConditions(_id)) {
                // update project status
                project.status = ProjectStatus.Stage;
                // delete all votes
                delete project.fastForward;

                // LOCK FUNDS HERE ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
                return;
            } else if (toStageConditions(_id)) {
                // adjust lateness
                adjustLatenessBeforeStage(_id);
                // update project status
                project.status = ProjectStatus.Stage;
                // delete all votes
                delete project.fastForward;

                // LOCK FUNDS HERE ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
                return;
            }
        }
        // GOING INTO GATE 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹
        else if (project.status == ProjectStatus.Stage) {
            if (toGateFastForwardConditions(_id)) {
                // update project status
                project.status = ProjectStatus.Gate;
                // delete all votes
                delete project.fastForward;
                return;
            } else if (toGateConditions(_id)) {
                // update project status
                project.status = ProjectStatus.Gate;
                // delete all votes
                delete project.fastForward;
                return;
            }
        }
    }

    // Figure out where we are and where we should be and fix if needed ✅
    function statusFixer(uint256 _id) public {
        Project storage project = projects[_id];
        ProjectStatus shouldBeStatus = whatStatusProjectShouldBeAt(_id);

        // If we are where we should be and votes allow to fast forward, try to fast forward
        // Otherwise, do nothing
        if (shouldBeStatus == project.status && checkFastForwardStatus(_id)) {
            updateProjectStatus(_id);
        } else {
            return;
        }

        // If we should be in settled but are in gate, then return
        // moving to settled needs owner input so we'll just wait here
        if (
            shouldBeStatus == ProjectStatus.Settled &&
            project.status == ProjectStatus.Gate
        ) {
            return;
        } else {
            // Iterate until we get to where we should be
            while (shouldBeStatus != project.status) {
                updateProjectStatus(_id);
                shouldBeStatus = whatStatusProjectShouldBeAt(_id);
            }
        }
    }

    // Adjust lateness of Project before stage ✅
    function adjustLatenessBeforeStage(
        uint256 _id
    )
        internal
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
    {
        Project storage project = projects[_id];
        uint256 lateness = 0;

        // If we are late, add lateness to all tasks and nextmilestone
        if (block.timestamp > project.nextMilestone.startStageTimestamp) {
            lateness =
                block.timestamp -
                project.nextMilestone.startStageTimestamp;
        }

        // Get NotClosed tasks
        Task[] memory notClosedTasks = getTasksOfProjectClosedFilter(
            _id,
            TaskStatusFilter.NotClosed
        );

        // Add lateness to all tasks
        for (uint256 i = 0; i < notClosedTasks.length; i++) {
            notClosedTasks[i].deadline += lateness; // add lateness to deadline
        }

        // add lateness to nextmilestone
        project.nextMilestone.startGateTimestamp += lateness;
        project.nextMilestone.startSettledTimestamp += lateness;
    }

    // Update project milestones ✅
    function typicalProjectMilestonesUpdate(
        uint256 _id,
        uint256 _nextStageStartTimestamp,
        uint256 _nextGateStartTimestamp,
        uint256 _nextSettledStartTimestamp,
        uint256 latestTaskDeadline
    ) private {
        Project storage project = projects[_id];

        // Upcoming milestones based on input
        NextMilestone memory _nextMilestone = NextMilestone(
            // timestamp of stage start must be at least 24 hours from now as grace period
            max(_nextStageStartTimestamp, block.timestamp + minimumSettledTime),
            // timestamp of gate start is at least after latest task deadline
            max(_nextGateStartTimestamp, latestTaskDeadline + 1 seconds),
            // timestamp of settled start must be after latest task deadline + 2 day
            max(
                _nextSettledStartTimestamp,
                max(_nextGateStartTimestamp, latestTaskDeadline + 1 seconds) +
                    minimumGateTime
            )
        );

        project.nextMilestone = _nextMilestone;
    }

    // Automatically accept decisions which have not received a submission and are past the decision time ✅
    function payLatePendingSubmissions(uint256 _id) public {
        Project storage project = projects[_id];
        Campaign storage campaign = campaigns[project.parentCampaign];

        require(
            block.timestamp >=
                project.nextMilestone.startGateTimestamp +
                    taskSubmissionDecisionTime,
            "Past end of max submission decision time, anyone can release funds of tasks missing decisions."
        );

        for (uint256 i = 0; i < project.childTasks.length; i++) {
            if (
                tasks[project.childTasks[i]].submission.status ==
                SubmissionStatus.Pending
            ) {
                tasks[project.childTasks[i]].submission.status ==
                    SubmissionStatus.Accepted;
                tasks[project.childTasks[i]].closed == true;
                tasks[project.childTasks[i]].paid == true;
                tasks[project.childTasks[i]].worker.transfer(
                    tasks[project.childTasks[i]].reward
                );
                campaign.lockedRewards -= tasks[project.childTasks[i]].reward;
            }
        }
    }

    // If sender is owner, acceptor or worker, append vote to fast forward status ✅
    function voteFastForwardStatus(
        uint256 _id,
        bool _vote
    ) public lazyStatusUpdaterStart(_id) lazyStatusUpdaterEnd(_id) {
        require(
            checkIsCampaignAcceptor(projects[_id].parentCampaign) ||
                checkIsCampaignOwner(projects[_id].parentCampaign) ||
                checkIsProjectWorker(_id),
            "Sender must be an acceptor, worker or owner"
        );
        Project storage project = projects[_id];

        bool voterFound = false;

        for (uint256 i = 0; i < project.fastForward.length; i++) {
            if (project.fastForward[i].voter == msg.sender) {
                project.fastForward[i].vote = _vote;
                voterFound = true;
                break;
            }
        }

        if (!voterFound) {
            project.fastForward.push(Vote(msg.sender, _vote));
        }
    }

    // Worker drop out of project ✅
    function workerDropOut(
        uint256 _id
    )
        public
        isProjectExisting(_id)
        isProjectWorker(_id)
        lazyStatusUpdaterStart(_id)
    {
        Project storage project = projects[_id];
        Campaign storage campaign = campaigns[project.parentCampaign];

        // Ensure project status is not stage
        require(
            project.status != ProjectStatus.Stage,
            "Project must currently be at gate or settled or closed"
        );

        // Remove worker from project
        deleteItemInAddressArray(msg.sender, project.workers);
        // Remove worker from campaign
        deleteItemInPayableAddressArray(payable(msg.sender), campaign.workers);

        // Add Worker to pastWorkers in project
        project.pastWorkers.push(msg.sender);

        // Refund stake
        refundWorkerEnrolStake(_id, msg.sender);
    }

    // Remove worker from project by owner ✅
    function fireWorker(
        uint256 _id,
        address _worker
    )
        public
        isProjectExisting(_id)
        isCampaignOwner(projects[_id].parentCampaign)
        lazyStatusUpdaterStart(_id)
    {
        Project storage project = projects[_id];
        Campaign storage campaign = campaigns[project.parentCampaign];

        // Ensure worker is on project
        require(
            checkIsProjectWorker(_id, _worker),
            "Address must be a worker on the project"
        );

        // Ensure project status is not stage
        require(
            project.status != ProjectStatus.Stage,
            "Project must currently be at gate or settled or closed"
        );

        // Remove worker from project
        deleteItemInAddressArray(_worker, project.workers);
        // Remove worker from campaign
        deleteItemInPayableAddressArray(payable(_worker), campaign.workers);

        // Add Worker to pastWorkers in project
        project.pastWorkers.push(_worker);

        // Refund stake
        refundWorkerEnrolStake(_id, _worker);
    }

    // Internal function to refund worker enrol stake and delete appliction ✅
    function refundWorkerEnrolStake(
        uint256 _id,
        address _worker
    )
        internal
        isProjectExisting(_id)
        isCampaignOwner(projects[_id].parentCampaign)
        lazyStatusUpdaterStart(_id)
    {
        Project storage project = projects[_id];

        // Ensure worker is on project
        require(
            checkIsProjectWorker(_id, _worker),
            "Address must be a worker on the project"
        );

        // Ensure project status is not stage
        require(
            project.status != ProjectStatus.Stage,
            "Project must currently be at gate or settled or closed"
        );

        // Refund stake
        for (uint256 i = 0; i < project.applications.length; i++) {
            // Find worker's application, ensure it was accepted and not refunded
            if (
                applications[project.applications[i]].applicant == _worker &&
                !applications[project.applications[i]].enrolStake.refunded &&
                applications[project.applications[i]].accepted
            ) {
                // Refund stake in application
                applications[project.applications[i]]
                    .enrolStake
                    .refunded = true;
                payable(_worker).transfer(
                    applications[project.applications[i]].enrolStake.funding
                );
                deleteItemInUintArray(i, project.applications); //-> Get rid of refunded application
            }
        }
    }

    // Enrol to project as worker when no application is required ✅
    function workerEnrolNoApplication(
        uint256 _id,
        uint256 _stake
    )
        public
        payable
        isCampaignRunning(projects[_id].parentCampaign)
        isProjectExisting(_id)
        isProjectRunning(_id)
        isMoneyIntended(_stake)
        isMoreThanEnrolStake(_stake)
        lazyStatusUpdaterEnd(_id)
    {
        Project storage project = projects[_id];
        Campaign storage campaign = campaigns[project.parentCampaign];

        require(!project.applicationRequired, "Project requires applications");
        require(
            !checkIsProjectWorker(_id),
            "Sender must not already be a worker"
        );

        // Creates application to deal with stake
        Application storage application = applications[applicationCount];
        application.metadata = "No Application Required";
        application.applicant = msg.sender;
        application.accepted = true;
        application.enrolStake.funder = payable(msg.sender);
        application.enrolStake.funding = _stake;
        application.enrolStake.refunded = false;
        application.parentProject = _id;

        project.applications.push(applicationCount);
        applicationCount++;

        project.workers.push(msg.sender);
        campaign.allTimeStakeholders.push(payable(msg.sender));
        campaign.workers.push(payable(msg.sender));
    }

    // Apply to project to become Worker ✅
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
        lazyStatusUpdaterEnd(_id)
        returns (uint256)
    {
        Project storage project = projects[_id];
        require(
            project.applicationRequired,
            "Project does not require applications"
        );

        require(
            !checkIsProjectWorker(_id),
            "Sender must not already be a worker"
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

    // Worker application decision by acceptors ✅
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
        lazyStatusUpdaterEnd(applications[_applicationID].parentProject)
    {
        Application storage application = applications[_applicationID];
        Project storage project = projects[application.parentProject];
        Campaign storage campaign = campaigns[project.parentCampaign];
        // if project or campaign is closed, decline or if project is past its deadline, decline
        // also refund stake
        if (
            project.status == ProjectStatus.Closed ||
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
            // deleteItemInUintArray(_applicationID, project.applications); maybe?? -> only on refund
        }
    }

    /// 🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳
    /// PROJECT READ FUNCTIONS 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹

    // Returns the status corresponding to our current timestamp ✅
    function whatStatusProjectShouldBeAt(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (ProjectStatus)
    {
        Project storage project = projects[_id];
        require(
            project.status != ProjectStatus.Closed,
            "Project must be running"
        );
        if (block.timestamp < project.nextMilestone.startStageTimestamp) {
            return ProjectStatus.Settled;
        } else if (block.timestamp < project.nextMilestone.startGateTimestamp) {
            return ProjectStatus.Stage;
        } else if (
            block.timestamp < project.nextMilestone.startSettledTimestamp
        ) {
            return ProjectStatus.Gate;
        } else {
            return ProjectStatus.Settled;
        }
    }

    // Conditions for going to Stage ✅
    function toStageConditions(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (bool)
    {
        Project storage project = projects[_id];
        Task[] memory notClosedTasks = getTasksOfProjectClosedFilter(
            _id,
            TaskStatusFilter.NotClosed
        );

        bool currentStatusValid = project.status == ProjectStatus.Settled;
        bool projectHasWorkers = project.workers.length > 0;
        bool allTasksHaveWorkers = true;
        bool inStagePeriod = block.timestamp >=
            project.nextMilestone.startStageTimestamp;

        // Ensure all tasks have workers
        for (uint256 i = 0; i < notClosedTasks.length; i++) {
            if (notClosedTasks[i].worker == address(0)) {
                allTasksHaveWorkers = false;
                return false;
            }
        }

        // All conditions must be true to go to stage
        return
            allTasksHaveWorkers &&
            currentStatusValid &&
            projectHasWorkers &&
            inStagePeriod;
    }

    // Conditions for fast forwarding to Stage ✅
    function toStageFastForwardConditions(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (bool)
    {
        Project storage project = projects[_id];
        Task[] memory notClosedTasks = getTasksOfProjectClosedFilter(
            _id,
            TaskStatusFilter.NotClosed
        );

        bool currentStatusValid = project.status == ProjectStatus.Settled;
        bool projectHasWorkers = project.workers.length > 0;
        bool allTasksHaveWorkers = true;
        bool stillInSettledPeriod = block.timestamp <
            project.nextMilestone.startStageTimestamp;

        // Ensure all tasks have workers
        for (uint256 i = 0; i < notClosedTasks.length; i++) {
            if (notClosedTasks[i].worker == address(0)) {
                allTasksHaveWorkers = false;
                return false;
            }
        }

        // All conditions must be true to go to stage
        return
            allTasksHaveWorkers &&
            currentStatusValid &&
            projectHasWorkers &&
            stillInSettledPeriod &&
            checkFastForwardStatus(_id);
    }

    // Conditions for going to Gate ✅
    function toGateConditions(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (bool)
    {
        Project storage project = projects[_id];
        bool currentStatusValid = project.status == ProjectStatus.Stage;
        bool inGatePeriod = block.timestamp >=
            project.nextMilestone.startGateTimestamp;

        return currentStatusValid && inGatePeriod;
    }

    // Conditions for fast forwarding to Gate ✅
    function toGateFastForwardConditions(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (bool)
    {
        Project storage project = projects[_id];
        bool currentStatusValid = project.status == ProjectStatus.Stage;
        bool stillInStagePeriod = block.timestamp <
            project.nextMilestone.startGateTimestamp;
        bool allTasksHaveSubmissions = true;

        // Ensure all NotClosed tasks have submissions
        Task[] memory notClosedTasks = getTasksOfProjectClosedFilter(
            _id,
            TaskStatusFilter.NotClosed
        );
        for (uint256 i = 0; i < notClosedTasks.length; i++) {
            if (notClosedTasks[i].submission.status == SubmissionStatus.None) {
                allTasksHaveSubmissions = false;
                return false;
            }
        }

        return
            currentStatusValid &&
            stillInStagePeriod &&
            allTasksHaveSubmissions &&
            checkFastForwardStatus(_id);
    }

    // Conditions for going to Settled ✅
    function toSettledConditions(
        uint256 _id
    )
        public
        view
        isProjectExisting(_id)
        isProjectRunning(_id)
        isCampaignRunning(projects[_id].parentCampaign)
        returns (bool)
    {
        Project storage project = projects[_id];

        bool currentStatusValid = project.status == ProjectStatus.Gate;
        bool inSettledPeriod = block.timestamp >=
            project.nextMilestone.startSettledTimestamp;

        return currentStatusValid && inSettledPeriod;
    }

    // How many tasks match filter? helper function for getTasksOfProjectClosedFilter() below✅
    function countTasksWithFilter(
        uint256 _id,
        TaskStatusFilter _statusFilter
    ) internal view returns (uint256) {
        uint256 taskCounter = 0;
        uint256[] memory childTasks = projects[_id].childTasks;
        for (uint256 i = 0; i < childTasks.length; i++) {
            if (
                _statusFilter == TaskStatusFilter.Closed &&
                tasks[childTasks[i]].closed
            ) {
                taskCounter++;
            } else if (
                _statusFilter == TaskStatusFilter.NotClosed &&
                !tasks[childTasks[i]].closed
            ) {
                taskCounter++;
            } else if (_statusFilter == TaskStatusFilter.All) {
                taskCounter++;
            }
        }
        return taskCounter;
    }

    // Get tasks in a project based on Closed/NotClosed filter✅
    function getTasksOfProjectClosedFilter(
        uint256 _id,
        TaskStatusFilter _statusFilter
    ) public view returns (Task[] memory) {
        Project memory parentProject = projects[_id];
        if (_statusFilter == TaskStatusFilter.NotClosed) {
            // Get uncompleted tasks
            Task[] memory _tasks = new Task[](
                countTasksWithFilter(_id, _statusFilter)
            );
            uint256 j = 0;
            for (uint256 i = 0; i < parentProject.childTasks.length; i++) {
                if (!tasks[parentProject.childTasks[i]].closed) {
                    _tasks[j] = tasks[parentProject.childTasks[i]];
                    j++;
                }
            }
            return _tasks;
        } else if (_statusFilter == TaskStatusFilter.Closed) {
            // Get completed tasks
            Task[] memory _tasks = new Task[](
                countTasksWithFilter(_id, _statusFilter)
            );
            uint256 j = 0;
            for (uint256 i = 0; i < parentProject.childTasks.length; i++) {
                if (tasks[parentProject.childTasks[i]].closed) {
                    _tasks[j] = tasks[parentProject.childTasks[i]];
                    j++;
                }
            }
            return _tasks;
        } else {
            // Get all tasks
            Task[] memory _tasks = new Task[](parentProject.childTasks.length);
            for (uint256 i = 0; i < parentProject.childTasks.length; i++) {
                _tasks[i] = tasks[parentProject.childTasks[i]];
            }
            return _tasks;
        }
    }

    // Checks that voting conditions are met ✅
    function checkFastForwardStatus(uint256 _id) public view returns (bool) {
        Project storage project = projects[_id];

        // Check for each vote in the fastForward array, if at least 1 owner
        // and all workers voted true, and conditions are fulfilled,
        // then move to next stage/gate/settled
        uint256 ownerVotes = 0;
        uint256 workerVotes = 0;
        uint256 acceptorVotes = 0;

        for (uint256 i = 0; i < project.fastForward.length; i++) {
            if (
                checkIsProjectWorker(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                workerVotes++;
            } else {
                return false;
            }
            if (
                checkIsCampaignOwner(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                ownerVotes++;
            }
            if (
                checkIsCampaignAcceptor(_id, project.fastForward[i].voter) &&
                project.fastForward[i].vote
            ) {
                acceptorVotes++;
            }
        }

        return
            ownerVotes > 0 &&
            acceptorVotes > 0 &&
            project.workers.length <= workerVotes;
    }

    // Check if sender is owner of campaign ✅
    function checkIsCampaignOwner(uint256 _id) public view returns (bool) {
        bool isOwner = false;
        for (uint256 i = 0; i < campaigns[_id].owners.length; i++) {
            if (msg.sender == campaigns[_id].owners[i]) {
                isOwner = true;
                break;
            }
        }
        return isOwner;
    }

    // Overloading: Check if address is owner of campaign ✅
    function checkIsCampaignOwner(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isOwner = false;
        for (uint256 i = 0; i < campaigns[_id].owners.length; i++) {
            if (_address == campaigns[_id].owners[i]) {
                isOwner = true;
                break;
            }
        }
        return isOwner;
    }

    // Check if sender is acceptor of campaign ✅
    function checkIsCampaignAcceptor(uint256 _id) public view returns (bool) {
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaigns[_id].acceptors.length; i++) {
            if (msg.sender == campaigns[_id].acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        return isAcceptor;
    }

    // Overloading: Check if address is acceptor of campaign ✅
    function checkIsCampaignAcceptor(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isAcceptor = false;
        for (uint256 i = 0; i < campaigns[_id].acceptors.length; i++) {
            if (_address == campaigns[_id].acceptors[i]) {
                isAcceptor = true;
                break;
            }
        }
        return isAcceptor;
    }

    // Check if sender is worker of project ✅
    function checkIsProjectWorker(uint256 _id) public view returns (bool) {
        bool isWorker = false;
        for (uint256 i = 0; i < projects[_id].workers.length; i++) {
            if (msg.sender == projects[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        return isWorker;
    }

    // Overloading: Check if address is worker of project ✅
    function checkIsProjectWorker(
        uint256 _id,
        address _address
    ) public view returns (bool) {
        bool isWorker = false;
        for (uint256 i = 0; i < projects[_id].workers.length; i++) {
            if (_address == projects[_id].workers[i]) {
                isWorker = true;
                break;
            }
        }
        return isWorker;
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// TASK WRITE FUNCTIONS 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻
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
        task.closed = false;

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

    // Submit a submission to a task ✅
    function submitSubmission(
        uint256 _id,
        string memory _metadata
    )
        public
        isTaskExisting(_id)
        isProjectExisting(tasks[_id].parentProject)
        lazyStatusUpdaterStart(tasks[_id].parentProject)
        isProjectRunning(tasks[_id].parentProject)
        isWorkerOnTask(_id)
        isTaskNotClosed(_id)
        isProjectStage(tasks[_id].parentProject)
    {
        Task storage task = tasks[_id];
        require(task.deadline > block.timestamp, "Task deadline has passed");

        // Create submission, if it already exists, overwrite it
        Submission storage submission = task.submission;
        // Attach the IPFS hash for metadata
        submission.metadata = _metadata;
        // Submission status is pending after submission
        submission.status = SubmissionStatus.Pending;
    }

    // Submission decision by acceptors ✅
    function submissionDecision(
        uint256 _id,
        bool _accepted
    )
        public
        isTaskExisting(_id)
        isProjectExisting(tasks[_id].parentProject)
        lazyStatusUpdaterStart(tasks[_id].parentProject)
        isProjectRunning(tasks[_id].parentProject)
        isCampaignAcceptor(projects[tasks[_id].parentProject].parentCampaign)
        isTaskNotClosed(_id)
        isProjectGate(tasks[_id].parentProject)
    {
        Project storage project = projects[tasks[_id].parentProject];
        Campaign storage campaign = campaigns[project.parentCampaign];
        Task storage task = tasks[_id];
        Submission storage submission = task.submission;

        require(
            block.timestamp <
                project.nextMilestone.startGateTimestamp +
                    taskSubmissionDecisionTime,
            "Decision must happen during decision window"
        );
        require(
            submission.status == SubmissionStatus.Pending,
            "Submission must not already have decision"
        );

        // If decision is accepted, set submission status to accepted,
        // payout worker, update locked rewards and close task
        if (_accepted) {
            submission.status = SubmissionStatus.Accepted;
            task.paid = true;
            task.closed = true;
            task.worker.transfer(task.reward);
            campaign.lockedRewards -= task.reward;
        } else {
            submission.status = SubmissionStatus.Declined;
        }
    }

    // Raise a dispute on a declined submission ✅
    // ⚠️ -> needs functionality behind it, currently just a placeholder
    // funds locked in a dispute should be locked in the campaign until
    // the dispute is resolved
    function raiseDispute(
        uint256 _id,
        string memory _metadata
    )
        public
        isTaskExisting(_id)
        isProjectExisting(tasks[_id].parentProject)
        lazyStatusUpdaterStart(tasks[_id].parentProject)
        isProjectRunning(tasks[_id].parentProject)
        isWorkerOnTask(_id)
        isTaskNotClosed(_id)
        isProjectGate(tasks[_id].parentProject)
    {
        Task storage task = tasks[_id];
        Project storage project = projects[task.parentProject];
        Submission storage submission = task.submission;

        require(
            submission.status == SubmissionStatus.Declined,
            "Submission must be declined"
        );
        require(
            block.timestamp <
                project.nextMilestone.startGateTimestamp +
                    taskSubmissionDecisionDisputeTime,
            "Dispute must happen during dispute window"
        );

        dispute(_id, _metadata);
    }

    /// 🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳🔳
    /// TASK READ FUNCTIONS 🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
    /// UTILITY FUNCTIONS
    // Returns maximum of two numbers ✅
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    // Pattern for deleting stuff from uint arrays by uint256 ID ✅
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

    // Pattern for deleting stuff from address arrays by address ✅
    function deleteItemInAddressArray(
        address _ItemAddress,
        address[] storage _array
    ) internal {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemAddress) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
    }

    // Pattern for deleting stuff from payable address arrays by address ✅
    function deleteItemInPayableAddressArray(
        address payable _ItemAddress,
        address payable[] storage _array
    ) internal {
        uint256 i = 0;
        while (i < _array.length) {
            if (_array[i] == _ItemAddress) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                return;
            }
            i++;
        }
        // Throw an error if the item was not found.
        revert("Item not found");
    }

    /// ⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
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

    function dispute(
        uint256 _id,
        string memory _metadata
    ) public isCampaignStakeholder(_id) {
        emit Dispute(_id, _metadata);
    }

    event Dispute(uint256 _id, string _metadata);

    receive() external payable {}

    fallback() external payable {}
}
