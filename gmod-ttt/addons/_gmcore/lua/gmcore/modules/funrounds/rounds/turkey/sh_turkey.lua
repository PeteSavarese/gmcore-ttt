local EVENT = {
	sTitle = "Turkey",
	tDescription = {
		"Its a fight to your death! Stuff anyone you see.",
		"Thanksgiving food items spawn around the map.",
		"Pick up these items and stuff other players with the food.",
		"Karma is not affected during this round.",
		"Camping is not allowed during this fun round.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Standing: 50 points",
		"\tMost Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	Rewards = {
		iPerStuffing = 10, -- Points awarded everytime a player stuffs someone else
		iMostStuffings = 100,
		iLastStanding = 100
	},

	-- Begin event specific
	iStuffingToKill = 25, -- This changes how many counts of "stuffing" until a player explodes. Turkey leg = 1 stuffing, turkey = 2 stuffings, pumpkin = 3 stuffings
	Active = false
}


gmcore.FunRounds:RegisterFunRound("Turkey", EVENT)
