# **P1**

[-] EVERYTHING must be settled at every gate
[-] Remove worker function _>func_

[-] Project status _!infra_
[-] Locked funds entry in the campaign _!infra_
[-] Campaign Worker Proposal _!infra_
[-] Project Worker Proposal _!infra_
[-] Worker enrollment _!infra_
[-] Task submission _!infra_

[-] Application acceptance _>func_
[-] Project update _>func_
[-] Project/Campaign Locked Funds _>func_
[-] Make stage/gate infra _>func_
[-] Locked funds _>func_
[-] Project Worker Proposal _>func_
[-] Acceptance/declining of submissions _>func_
[-] fake ^Dispute with event _>func_
[-] Worker enrollment _>func_
[-] Worker leave function conditional on gate stage _>func_
[-] Task submission _>func_
[-] Task getSubmissions _>func_
[-] Task Value Calculation _>func_

# **P2**

[-] Task reference in project _!infra_
[-] Reopening campaign isn't possible.
[-] Stake can only be recovered when campaignStatus is closed or campaignStyle made open.
[-] Stake gets redistributed post-deadline if campaign isn't closed.

# **P3**

[-] Crowdcheck all campaigns and metadata against harmful content.
[-] Make fundings a mapping for storage gas efficiency.

# **P4**

[-] Dynamically adjust creation stake price to be ~10$.

# **P5**

# **Removed**

[-] Make a "Worker" struct which contains a "IsWorking" entry.
[-] Max workers slot (potentially in metadata if application required to join campaign).

# **Done**

[x] Require stake to prevent spamming of campaigns.
[x] Create a "status" on campaign for closed, open and archived campaigns.
[x] Clean up functions with modifiers.
[X] Assign roles by owner.
[X] UpdateCampaign single function (default values will be placed in front-end)
[x] project nesting _!infra_
[x] Application requirement _!infra_
