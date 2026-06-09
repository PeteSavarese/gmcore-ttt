local EVENT = {
	sTitle = "Deathmatch",
	tDescription = {
		"Its a fight to your death! Kill anyone you see.",
		"You may have to find your own weapon.",
		"Karma is not affected during this round.",
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
		iLastStanding = 50
	},
	Active = true
}


gmcore.FunRounds:RegisterFunRound("Deathmatch", EVENT)
