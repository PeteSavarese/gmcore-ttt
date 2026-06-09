local EVENT = {
	sTitle = "Gun Game",
	tDescription = {
		"Kill everyone you see. Each kill advances you to the next level weapon.",
		"First person to get a kill with the knife wins",
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
		iMostKills = 75,
		winsGG = 150
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("gungame", EVENT)
