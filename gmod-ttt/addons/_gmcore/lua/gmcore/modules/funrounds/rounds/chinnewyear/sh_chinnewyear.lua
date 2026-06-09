local EVENT = {
	sTitle = "Year of the Ox",
	tDescription = {
		"Its the year of the Ox!",
		"Chinese lanterns are spawned around the map.",
		"The lanterns have a surprise in each of them.",
		"Get a special weapon, a powerup, or you explode!",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Standing: 50 points",
		"\tMost Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	Rewards = {
		iPerKill = 10,
		iMostKills = 75,
		iLastStanding = 100
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("ChinNewYear", EVENT)
