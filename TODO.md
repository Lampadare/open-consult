# **P1**

[-] Assign roles by owner.
[-] UpdateCampaign single function (default values will be placed in front-end)
[-] Make stage/gate infra.
[-] Locked funds entry in the campaign

# **P2**

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
