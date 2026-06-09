local EVENT = gmcore.FunRounds.RegisteredFunRounds["Dodgeball"]

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	local sImageOfTeam = tWinners.lastTeam == "D" and "vgui/ttt/icon_det.png" or "vgui/ttt/icon_traitor.png"
	local sWinningTeamNick = tWinners.lastTeam == "D" and "Blue Team" or "Red Team"

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
		ply = tWinners.eMostKills,
		text = string.format("Most Kills (%i)", tWinners.iKillCount)
	})

	table.insert(winners, mostKills)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

gmcore.FunRounds:RegisterFunRound("Dodgeball", EVENT)
