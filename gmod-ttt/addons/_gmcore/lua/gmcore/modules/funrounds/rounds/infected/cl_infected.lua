local EVENT = gmcore.FunRounds.RegisteredFunRounds["Infected"]

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	local sImageOfTeam = tWinners.lastTeam == "D" and "vgui/ttt/icon_det.png" or "vgui/ttt/icon_traitor.png"
	local sWinningTeamNick = tWinners.lastTeam == "D" and "Humans" or "Zombies"

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		text = string.format("Last Team Standing"),
		name = sWinningTeamNick,
		image = sImageOfTeam
	})
	table.insert(winners, lastAlive)
	---------------------------------------------------------

	---------------------------------------------------------
	local mostKills = vgui.Create("GmcoreFunRoundWinner")
	mostKills:SetWinner({
		ply = tWinners.mostZombKills,
		text = string.format("Most Zombie Kills (%i)", tWinners.iZombieKills)
	})
	table.insert(winners, mostKills)
	---------------------------------------------------------

	------------------------------------------------------------
	local mostInfections = vgui.Create("GmcoreFunRoundWinner")
	mostKills:SetWinner({
		ply = tWinners.mostInfections,
		text = string.format("Most Infections (%i)", tWinners.iInfections)
	})
	table.insert(winners, mostInfections)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

local function updateZombies()
	RunConsoleCommand("_ttt_request_rolelist")
end

gmcore.FunRounds:RegisterFunRound("Infected", EVENT)

net.Receive("gmcore.FunRounds.UpdateZombies", updateZombies)
