local EVENT = {
	sTitle = "Stalker",
	tDescription = {
		"Traitors are invisible stalkers!",
		"Traitors have knives and can longjump.",
		"Innocents must cooperate to survive.",
		"Camping is allowed during this fun round.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Team Standing: 50 points",
		"\tPoints per Killing Stalker: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	Rewards = {
		iPerStalkerKill = 75,
		iLastStanding = 100 -- Last team standing (Detective or Traitor). Not single person
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("Stalker", EVENT)
