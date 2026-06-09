local FONT_FUNROUND_TITLE = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 60,
	weight = 1000 -- Bold
})

local FONT_FUNROUND_DESC = gmcore.Fonts:Get({
	font = "Space Grotesk",
	size = 30,
	weight = 0
})

local FONT_FUNROUND_TITLE2 = gmcore.Fonts:Get({
	font = "Bebas Neue",
	size = 60,
	weight = 500,
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
	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetSize(0, 0)

	self.FunRoundIndex = nil
	self.FunRoundTbl = nil
	self.WinnersTbl = {}
	self.PositionSpot = nil -- Hacky way to specify pos for Think hook.
	self.PreRoundHasMovedToBottom = false -- Have we started our movement to the bottom
	self.HasCompletedMove = false -- Have we actually arrived at the bottom now
	self.HasCondensedRules = false -- Has the round begin and the rules have been hidden?

	-- Sizing
	self.DescTextHeights = {}
	self.FrTitleHeight = 0
	self.FinalWidth = 0
	self.FinalHeight = 0
end

--[[
	Given a string which refers to index of fun round stored in gmcore.FunRounds.RegisteredFunRounds, render title and rules
]]
function PANEL:SetFunRound(funRoundIndex)
	if !gmcore.FunRounds.RegisteredFunRounds[funRoundIndex] then
		error("Attempted to create glFunRoundAlert panel with fun round index " .. funRoundIndex .. " which doesn't exist in registered fun rounds.")

		return
	end

	self.FunRoundIndex = funRoundIndex
	self.FunRoundTbl = gmcore.FunRounds.RegisteredFunRounds[funRoundIndex]

	local activeFrTbl = self.FunRoundTbl

	-- Pre-calculate text heights outside of Paint
	surface.SetFont(FONT_FUNROUND_TITLE2)
	self.FinalWidth, self.FrTitleHeight = surface.GetTextSize(activeFrTbl.sTitle)
	self.FinalHeight = self.FinalHeight + self.FrTitleHeight

	-- Calculate description/rules heights
	for _, lineTxt in ipairs(activeFrTbl.tDescription) do
		surface.SetFont(FONT_FUNROUND_DESC2)

		local lineTextW, lineTextH = surface.GetTextSize(lineTxt)

		self.FinalHeight = self.FinalHeight + lineTextH + 5 -- Insert 5px of padding for each line

		if lineTextW > self.FinalWidth then
			self.FinalWidth = lineTextW
		end

		table.insert(self.DescTextHeights, lineTextH)
	end

	local headerColor = activeFrTbl.InfoSettings and activeFrTbl.InfoSettings.HeaderColor or color_white

	-- Draw fun round title
	self.FrTitleLbl = vgui.Create("DLabel", self)
	self.FrTitleLbl:SetFont(FONT_FUNROUND_TITLE2)
	self.FrTitleLbl:SetText(activeFrTbl.sTitle)
	self.FrTitleLbl:SetTextColor(headerColor)
	self.FrTitleLbl:SizeToContents()
	self.FrTitleLbl:Center()

	self:UpdateAlertPanelState("InitialOpening") -- Call for initial opening since we have all info now
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

--[[
	Sets size and positioning based off of round state
]]
function PANEL:UpdateAlertPanelState(panelState)
	self.PositionSpot = panelState

	if panelState == "InitialOpening" then
		-- Initial opening sequence
		self:SetSize(0, self.FrTitleHeight)

		self:SizeTo(self.FinalWidth + 20, self.FrTitleHeight + 12, 1, 0, -1, function()
			-- After 2 second delay, expand to show rules
			timer.Simple(2, function()
				self:UpdateAlertPanelState("DescDisplay")
			end)
		end)
	elseif panelState == "DescDisplay" then
		local xPos = scaledFrom1080(384, true)
		-- Expand to show rules
		self:MoveTo(xPos, ScrH() - self.FinalHeight - 10, 1, 0, -1)
		self:SizeTo(self.FinalWidth + 20, self.FinalHeight - 10, 1, 0, -1)
	elseif panelState == "MinimizedTitle" then
		-- Minimize to only show title that is ceneter aligned at bottom of screen
		local xPos = scaledFrom1080(384, true)
		self:MoveTo(xPos, ScrH() - (self.FrTitleHeight + 20) - 10, 1, 0, -1)
		self:SizeTo(self.FinalWidth + 20, self.FrTitleHeight + 12, 1, 0, -1)
	elseif panelState == "DisplayWinners" then
		self:MoveTo(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - (self.FrTitleHeight + 15) - 58, 1, 0, -1, function() -- Set height like this since animation in Paint function hasn't started yet; -58 48px for avatar - 10 for padding
			self.FunRoundTbl:DisplayWinners(self.WinnersTbl, self)
		end)
	end
end

--[[
	Updates panel state and calls active fun round's display winners code
]]
function PANEL:DisplayWinners(winnersTbl)
	self.WinnersTbl = winnersTbl
	self:UpdateAlertPanelState("DisplayWinners")
end

--[[
	Hacky fix for initial positioning
]]
function PANEL:Think()
	if self.PositionSpot == "InitialOpening" then
		self:Center()
		self.FrTitleLbl:Center()
	end
end

function PANEL:Paint(w, h)
	if !self.FunRoundIndex then return end

	local frInfo = self.FunRoundTbl.InfoSettings
	local bgColor = frInfo and frInfo.BackgroundColor or FRAME_BACKGROUND_COLOR
	local descColor = frInfo and frInfo.DescriptionColor or color_white

	--surface.SetDrawColor(FRAME_BACKGROUND_COLOR)
	--surface.DrawRect(0, 0 , w, h)
	draw.RoundedBox(8, 0, 0, w, h, bgColor)

	-- Accent coloring on top
	--surface.SetDrawColor(communityPrimaryColor)
	--surface.DrawRect(0, 0, w, 5)

	if self.PositionSpot == "DescDisplay" then
		surface.SetFont(FONT_FUNROUND_DESC)
		surface.SetTextColor(descColor)

		local textPosY = self.FrTitleHeight + 15 -- +10 to move past accent coloring and title padding

		for i, lineTxt in ipairs(self.FunRoundTbl.tDescription) do
			draw.SimpleText(lineTxt, FONT_FUNROUND_DESC2, 10, textPosY, descColor)

			textPosY = textPosY + self.DescTextHeights[i]
		end
	end

	-- Accent coloring on bottom
	--surface.SetDrawColor(communityPrimaryColor)
	--surface.DrawRect(0, h - 5, w, 5)
end

derma.DefineControl("GmcoreFunRoundAlert2", "", PANEL, "DPanel")
