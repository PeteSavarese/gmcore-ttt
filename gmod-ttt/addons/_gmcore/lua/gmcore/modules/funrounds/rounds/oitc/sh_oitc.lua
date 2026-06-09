local EVENT = {
	sTitle = "One In the Chamber",
	tDescription = {
		"Kill everyone you see. Each kill earns you a bullet.",
		"Miss your shot and it'll be a crowbar fight to the death.",
		"Camping is not allowed during this fun round.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Standing: 50 points",
		"\tMost Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
		iPerKill = 10,
		iMostKills = 75,
		iLastStanding = 100
	},
	Active = true,
	PointshopDisabled = true,
}


gmcore.FunRounds:RegisterFunRound("oitc", EVENT)
