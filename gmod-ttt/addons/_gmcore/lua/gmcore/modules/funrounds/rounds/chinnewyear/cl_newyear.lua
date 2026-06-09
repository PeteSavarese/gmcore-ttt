local EVENT = gmcore.FunRounds.RegisteredFunRounds["ChinNewYear"]

--[[

function EVENT:GetWinnerPanels(tWinners)

	local winners = {}

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		ply = tWinners.eLastAlive,
		text = string.format("Last Alive")
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
end--]]

gmcore.FunRounds:RegisterFunRound("ChinNewYear", EVENT)
