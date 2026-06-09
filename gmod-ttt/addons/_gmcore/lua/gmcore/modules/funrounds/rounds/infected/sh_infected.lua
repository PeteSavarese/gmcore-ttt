local EVENT = {
	sTitle = "Infected",
	tDescription = {
		"It's Zombies vs. Humans!",
		"Humans are armed with a shared random loadout. Zombies have knives.",
		"Zombies must get close and infect humans by killing them. Humans must survive the round for 3 minutes!",
		"Camping is allowed during this fun round. Stick together!",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Team Standing: 50 points",
		"\tMost Infections: 75 points",
		"\tMost Zombie Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
		iPerKill = 10,
		mostInfections = 75,
		mostZombieKills = 75,
		iLastStanding = 50 -- Last team standing (Detective or Traitor). Not single person
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("Infected", EVENT)
