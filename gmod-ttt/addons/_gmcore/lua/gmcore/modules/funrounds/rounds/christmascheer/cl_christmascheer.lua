local EVENT = gmcore.FunRounds.RegisteredFunRounds["Christmas Cheer"]
if not EVENT then return end

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	local elvesWon = tobool(tWinners and tWinners.bElvesWon)
	local sImageOfTeam = elvesWon and "vgui/ttt/icon_traitor.png" or "vgui/ttt/icon_inno.png"
	local sWinningTeamNick = elvesWon and "Elves" or "Survivors"

	---------------------------------------------------------
	local lastTeam = vgui.Create("GmcoreFunRoundWinner")
	lastTeam:SetWinner({
		text = string.format("Last Team Standing"),
		name = sWinningTeamNick,
		image = sImageOfTeam
	})
	table.insert(winners, lastTeam)
	---------------------------------------------------------

	---------------------------------------------------------
	local mostConversions = vgui.Create("GmcoreFunRoundWinner")
	local topPly = tWinners and tWinners.eMostConversions or nil
	local topCount = tWinners and tWinners.iConversionCount or 0

	if IsValid(topPly) then
		mostConversions:SetWinner({
			ply = topPly,
			text = string.format("Most Conversions (%i)", topCount)
		})
	else
		mostConversions:SetWinner({
			name = "Nobody",
			text = string.format("Most Conversions (%i)", topCount)
		})
	end

	table.insert(winners, mostConversions)
	---------------------------------------------------------

	return winners
end

function EVENT:RemoveWinners()
	if IsValid(gmcore.FunRounds.funRoundWinnersPnl) then
		gmcore.FunRounds.funRoundWinnersPnl:Remove()
		gmcore.FunRounds.funRoundWinnersPnl = nil
	end
end

hook.Add("HUDPaint", "gmcore.FunRounds.ChristmasCheer.Timer", function()
	if not gmcore or not gmcore.FunRounds or not gmcore.FunRounds.ActiveRound then return end
	if gmcore.FunRounds.ChosenFunRound ~= "Christmas Cheer" then return end

	local t = GetGlobalFloat("gmcore.FR.ChristmasCheer.ActivateAt", 0)
	if t <= 0 then return end

	local remaining = math.max(0, t - CurTime())
	if remaining <= 0 then return end

	draw.SimpleTextOutlined(string.format("Elf reveals in: %.0fs", remaining), "Trebuchet18", ScrW() / 2, 80, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
end)

gmcore.FunRounds:RegisterFunRound("Christmas Cheer", EVENT)
