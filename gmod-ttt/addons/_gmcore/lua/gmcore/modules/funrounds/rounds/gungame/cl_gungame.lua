local EVENT = gmcore.FunRounds.RegisteredFunRounds["gungame"]
local FONT_FUNROUND_DESC = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 30,
	weight = 0
})

function EVENT:Begin()
	self:AddHook("HUDPaint", self.HUDDrawLevel)
end


function EVENT:HUDDrawLevel()
	surface.SetFont(FONT_FUNROUND_DESC)

	local levelText = "Level: " .. math.Clamp(LocalPlayer():GetNWInt("gmcore.GunGameLevel", 1), 1, 14) .. "/14"
	local textW, textH = surface.GetTextSize(levelText)
	local panelWidth, panelHeight = textW + 20, textH + 20
	local panelPosX, panelPosY = GAMEMODE.HUD.Pos.x, GAMEMODE.HUD.Pos.y - panelHeight - 10

	-- Background color
	surface.SetDrawColor(FRAME_BACKGROUND_COLOR)
	surface.DrawRect(panelPosX, panelPosY, panelWidth, panelHeight)

	-- Accent coloring on top and bottom
	surface.SetDrawColor(COMMUNITY_PRIMARY_COLOR)
	surface.DrawRect(panelPosX, panelPosY, panelWidth, 5)

	-- Level text
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(panelPosX + 10, panelPosY + 10)
	surface.DrawText(levelText)
end

function EVENT:GetWinnerPanels(tWinners)
	local winners = {}

	-- (2) Create panels for each winner.
	---------------------------------------------------------
	local lastAlive = vgui.Create("GmcoreFunRoundWinner")
	lastAlive:SetWinner({
		ply = tWinners.plyWinGG,
		text = string.format("Winner!")
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

gmcore.FunRounds:RegisterFunRound("gungame", EVENT)
