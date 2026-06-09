local EVENT = {
	sTitle = "Bomb Rush",
	tDescription = {
		"People are randomly given a bomb that explodes in 10 seconds.",
		"You must pass the bomb before it explodes while holding it.",
		"Karma is not affected during this round.",
		"Camping is allowed during this fun round.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Standing: 150 points",
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
		lastStanding = 150
	},
	Active = true
}

gmcore.FunRounds:RegisterFunRound("Bomb Rush", EVENT)
