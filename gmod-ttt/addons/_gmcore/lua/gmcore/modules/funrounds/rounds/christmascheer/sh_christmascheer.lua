local EVENT = {
	sTitle = "Christmas Cheer",
	tDescription = {
		"An elf will be revealed and must spread Christmas cheer!",
		"The elf cannot deal damage; use the Candy Cane to convert others.",
		"Converted players join the elf team and can help convert the rest.",
		"Elves win when everyone has been converted.",
		"",
		"Rewards:",
		"\tLast Team Standing: 50 points",
		"\tMost Conversions: 75 points"
	},
	bPointRewards = true,
	bRadarEnabled = true,
	bRevealTraitors = true,
	bRevealRolesAliveOnly = true,
	Rewards = {
		iPerConversion = 10,
		iMostConversions = 75,
		iLastStanding = 50
	},
	Active = false
}

-- Round config
EVENT.ActivationDelay = 20
EVENT.ConvertDuration = 2
EVENT.ElfScale = 0.85
EVENT.ElfBaseHealth = EVENT.ElfBaseHealth or 350
EVENT.ElfMinHealth = EVENT.ElfMinHealth or 125

gmcore.FunRounds:RegisterFunRound("Christmas Cheer", EVENT)
