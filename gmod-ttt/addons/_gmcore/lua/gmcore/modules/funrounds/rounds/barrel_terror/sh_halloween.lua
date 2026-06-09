local EVENT = {
	sTitle = "Barrel Terror",
	tDescription = {
		"An Owner, Lead Admin, or Dev has been chosen as a grim reaper!",
		"Everyone must work together to kill the grim reaper.",
		"The last standing team wins a special Halloween event prize!",
		"Hiding is allowed.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tPrize coming soon. All winners will be logged!",
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound(EVENT.sTitle, EVENT)
