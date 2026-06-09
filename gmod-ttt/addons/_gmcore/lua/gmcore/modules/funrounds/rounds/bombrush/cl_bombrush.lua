local EVENT = gmcore.FunRounds.RegisteredFunRounds["Bomb Rush"]

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		ply = tWinners.plyLastAlive,
		text = string.format("Last Standing")
	})

	table.insert(winners, lastAlive)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

gmcore.FunRounds:RegisterFunRound("Bomb Rush", EVENT)
