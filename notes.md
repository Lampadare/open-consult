- finalise behaviour of decision tree for submission handling

- for accepting/declining submissions, funds should be locked until 48hrs after beginning of gate period, so dispute can be called

- make sure to release funds at right time for disputes to be logical (48hrs after gate start)

- lock funds on entry into stage

- functions called within the fixStatus pipeline cannot have lazyUpdater as modifier

- if adding tasks during settled, tasks can't be modified and deadline of task must be between stage start and gate start

- add lazyupdaters where needed

- deadline logic! -> only check for past deadline when about to settle or close and if past campaign deadline, close project

- clear unclosed task workers when going to settled

- calculate rewards when going to stage

- double check all makeSTUFF functions

- make all the getter functions

- funds involved in a dispute are locked until dispute is resolved
