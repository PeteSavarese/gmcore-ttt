local EVENT = {
	sTitle = "Linked Valentine",
	tDescription = {
		"You've found your new lover!",
		"Each person is paired with another person (their lover).",
		"You and your partner share the same health.",
		"You are out to kill a certain group of lovers!",
		"Last pair of lovers standing wins.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Standing Lovers: 100 points",
		"\tLovers with Most Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	Rewards = {
		iMostKills = 75,
		iLastStandingTeam = 100
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("Valentine", EVENT)
