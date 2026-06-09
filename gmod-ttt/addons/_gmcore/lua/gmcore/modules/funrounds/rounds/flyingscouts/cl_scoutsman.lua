local EVENT = gmcore.FunRounds.RegisteredFunRounds["flyingscouts"]

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)
end

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
end

gmcore.FunRounds:RegisterFunRound("flyingscouts", EVENT)
