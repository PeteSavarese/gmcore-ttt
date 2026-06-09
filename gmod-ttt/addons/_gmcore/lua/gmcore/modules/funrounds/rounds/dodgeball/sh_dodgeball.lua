local EVENT = {
	sTitle = "Dodgeball",
	tDescription = {
		"Its Traitors vs Detectives in dodgeball.",
		"You are all given a dodgeball to throw.",
		"Click to throw your dodgeball at an enemy.",
		"Camping is not allowed during this fun round.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Team Standing: 50 points",
		"\tMost Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
		iPerKill = 10,
		iMostKills = 75,
		iLastStanding = 100 -- Last team standing (Detective or Traitor). Not single person
	},
	Active = true
}


gmcore.FunRounds:RegisterFunRound("Dodgeball", EVENT)
