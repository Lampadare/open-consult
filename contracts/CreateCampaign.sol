// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract CreateCampaign {
    // Campaign struct
    struct Campaign {
        // Description of the project
        string title;
        string description;
        string metadata;

        // Funding goal and deadline
        uint256 goal;
        uint256 deadline;

        // Stakeholders
        address payable creator;
        address payable[] contributors;

        // Funding and contributions
        uint256 totalFunding;
        uint256[] contributions;
    }

    // Mapping of campaign IDs to campaigns
    mapping (uint256 => Campaign) public campaigns;

    // Number of campaigns
    uint256 public campaignCount = 0;

    // Create a new campaign
    function makeCampaign(string memory _title, string memory _description, 
    string memory _metadata, uint256 _goal, uint256 _deadline) public returns (uint256) {

        Campaign storage campaign = campaigns[campaignCount];

        require (_goal > 0, "Goal must be greater than 0");
        require (_deadline > block.timestamp, "Goal must be greater than 0");

        campaign.title = _title;
        campaign.description = _description;
        campaign.metadata = _metadata;
        campaign.goal = _goal;
        campaign.deadline = _deadline;
        campaign.totalFunding = address(this).balance;
    }

    // Donate to a campaign
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.contributors.push(msg.sender);
        campaign.contributions.push(amount);

        campaign.totalFunding += amount;
    }

    // Get campaign donators & contributions
    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].contributors, campaigns[_id].contributions);
    }

    // Get all campaigns
    function getCampaigns() public view returns (Campaign[] memory) {
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

    function drain(uint256 _id, bool _drainContract) public {
        require(msg.sender == campaigns[_id].creator, "Only the creator can drain the contract");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}