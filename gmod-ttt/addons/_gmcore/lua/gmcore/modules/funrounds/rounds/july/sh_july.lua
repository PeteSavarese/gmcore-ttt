-- Post game end particle
game.AddParticles( "particles/gf2_gigantic_rocket_01.pcf" )

local EVENT = {
	sTitle = "Firework Shots",
	tDescription = {
		"Fireworks are spawned around the map.",
		"Fetch a firework by walking over one.",
		"Click to fire the firework at another player.",
		"Last player standing wins.",
		"", -- Line break to seperate rewards
		"Rewards:",
		"\tLast Player Standing: 50 points",
		"\tMost Kills: 75 points"
	},
	bPointRewards = true, -- Point reward is handled in server file
	bRadarEnabled = true,
	Rewards = {
		iPerKill = 10,
		iMostKills = 75,
		iLastStanding = 100 -- Last team standing (Detective or Traitor). Not single person
	},
	Active = false
}


gmcore.FunRounds:RegisterFunRound("Fireworks", EVENT)
