local EVENT = {
	sTitle = "Harpoon Wars",
	tDescription = {
		"Its a fight to your death! Harpoon anyone you see.",
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
		iLastStanding = 100
	},
	Active = true,
	InfoSettings = {
		HeaderColor = Color(255, 0, 0),
		BackgroundColor = Color(0, 0, 0, 150),
	}
}


gmcore.FunRounds:RegisterFunRound("Harpoonwars", EVENT)
