
local FONT_FUNROUND_TITLE2 = gmcore.Fonts:Get({
	font = "Bebas Neue",
	size = 60,
	weight = 500, -- Bold
	outline = true,
})

local FONT_FUNROUND_DESC2 = gmcore.Fonts:Get({
	font = "Bebas Neue",
	size = 30,
	weight = 0
})

---@class gmcoreFunRoundAlert2 : DPanel
local PANEL = {}

function PANEL:Init()
	self.c_HeaderColor = color_white
	self.c_DescColor = color_white
	self.c_BackgroundColor = FRAME_BACKGROUND_COLOR
	self.i_HeadHeight = 0
	self.i_HeadWidth = 0
	self.i_DescWidth = 0
	self.i_DescHeight = 0
	self.i_Padding = 10
	self.t_DescLineHeights = {}
	self:SetZPos(-500) -- chat renders below this panel for some reason idk
end

function PANEL:SetFunRound(funRoundIndex)
	if not gmcore.FunRounds.RegisteredFunRounds[funRoundIndex] then
		error("Attempted to create glFunRoundAlert panel with fun round index " ..
			funRoundIndex .. " which doesn't exist in registered fun rounds.")
		return
	end

	self.m_FunRound = gmcore.FunRounds.RegisteredFunRounds[funRoundIndex]
	self.m_FunRoundIndex = funRoundIndex

	local infoSettings = self.m_FunRound.InfoSettings
	if infoSettings then
		self.c_HeaderColor = infoSettings.HeaderColor or color_white
		self.c_DescColor = infoSettings.DescriptionColor or color_white
		self.c_BackgroundColor = infoSettings.BackgroundColor or FRAME_BACKGROUND_COLOR
	end

	self.i_HeadWidth, self.i_HeadHeight = self:GetHeaderSize()
	self.i_DescWidth, self.i_DescHeight = self:GetDescriptionSize()

	self:UpdateAlertPanelState("InitialOpening")
end

function PANEL:GetHeaderSize()
	local frInfo = self.m_FunRound

	surface.SetFont(FONT_FUNROUND_TITLE2)
	local lineTextW, lineTextH = surface.GetTextSize(frInfo.sTitle)

	return lineTextW, lineTextH
end

function PANEL:GetDescriptionSize()
	local frInfo = self.m_FunRound

	local height = 0
	local width = 0

	surface.SetFont(FONT_FUNROUND_DESC2)
	for i, line in ipairs(frInfo.tDescription) do
		local lineTextW, lineTextH = surface.GetTextSize(line)

		width = lineTextW > width and lineTextW or width
		height = height + lineTextH -- don't pad last line
		self.t_DescLineHeights[i] = lineTextH
	end

	return width, height
end

-- These are actually scaled in 2560x1440 until i get scaling to work
-- Takes a number and returns what is the proper value for scaling to a display
-- Always insures an even number is returned for nice math calculation in HUD formatting
-- TODO: ACTUALLY DO SCALING
-- Stole this from terrortown/vgui/cl_hud.lua -veri
local function scaledFrom1080(iNumIn1080, bIsWidth)
	if ScrW() > 1 then return iNumIn1080 end

	local iPercOfVal
	local iRetrunVal

	if bIsWidth then -- Are we calculating the width or the height. Needed to determine which direction to scale in
		iPercOfVal = iNumIn1080 / 1920
		iReturnVal = iPercOfVal * ScrW()
	else
		iPercOfVal = iNumIn1080 / 1080
		iReturnVal = iPercOfVal * ScrH()
	end

	if iReturnVal % 2 ~= 0 then   -- If we can't divide by 2 and aren't even, math calculation will be a pain in other parts.
		iRetrunVal = iReturnVal + 1 -- Insure an even number by just adding 1 to the odd number
	end

	return iReturnVal
end

function PANEL:UpdateAlertPanelState(panelState)
	self.PositionSpot = panelState

	if panelState == "InitialOpening" then
		self:SetSize(self.i_DescWidth + self.i_Padding * 2, 0)

		local totalWidth = self.i_DescWidth + (self.i_Padding * 2)
		local totalHeight = self.i_HeadHeight + self.i_DescHeight + (self.i_Padding * 3)

		self:SizeTo(totalWidth, totalHeight, 1, 0, -1, function()
			-- After 2 second delay, expand to show rules
			timer.Simple(2, function()
				self:UpdateAlertPanelState("DescDisplay")
			end)
		end)

	elseif panelState == "DescDisplay" then
		local totalWidth = self.i_DescWidth + (self.i_Padding * 2)
		local totalHeight = self.i_HeadHeight + self.i_DescHeight + (self.i_Padding * 3)
		local xPos = scaledFrom1080(384, true)

		self:SizeTo(totalWidth, totalHeight, 1, 0, -1, function() end)
		self:MoveTo(xPos, ScrH() - totalHeight - 10, 1, 0, -1)
	elseif panelState == "MinimizedTitle" then
		local xPos = scaledFrom1080(384, true)
		self:MoveTo(xPos, ScrH() - self.i_HeadHeight - 20, 1, 0, -1)
		self:SizeTo(self.i_DescWidth + self.i_Padding * 2, self.i_HeadHeight + self.i_Padding, 1, 0, -1)
	elseif panelState == "DisplayWinners" then
		self:MoveTo(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self.i_HeadHeight - 140, 1, 0, -1, -- hard coded height offset
			function()
				gmcore.FunRounds:ShowWinners()
			end)
	end
end

function PANEL:DisplayWinners(winnersTbl, pnl)
	self.t_Winners = winnersTbl
	self.t_WinnerPnl = pnl
	self:UpdateAlertPanelState("DisplayWinners")
end

function PANEL:Paint(w, h)
	local frInfo = self.m_FunRound
	if not frInfo then return end

	draw.RoundedBox(8, 0, 0, w, h, self.c_BackgroundColor)
	draw.DrawText(frInfo.sTitle, FONT_FUNROUND_TITLE2, w / 2, self.i_Padding,
		self.c_HeaderColor, TEXT_ALIGN_CENTER)

	--if self.PositionSpot == "DescDisplay" then
		local descPos = self.i_HeadHeight + (self.i_Padding * 2)
		for i, line in ipairs(frInfo.tDescription) do
			draw.DrawText(line, FONT_FUNROUND_DESC2, self.i_Padding, descPos,
				self.c_DescColor)

			descPos = descPos + self.t_DescLineHeights[i]
		end
	--end

end

function PANEL:Think()
	if self.PositionSpot == "InitialOpening" then
		self:Center()
	end
end

vgui.Register("GmcoreFunRoundAlert", PANEL, "DPanel")
