---Creates a new ticker element for marquee-style text.
---@param x number? Origin X position (default 4)
---@param y number? Origin Y position (default 2)
---@param delay number? Initial delay before scrolling (default 0)
---@return {dir: integer, delay: number, origin: number, x: number, y: number}
local function NewTicker(x, y, delay)
	return {
		dir = 1,
		delay = CurTime() + (delay or 0),
		origin = x or 4,
		x = x or 4,
		y = y or 2
	}
end

---Draws a marquee-style text within a specified width.
---@param text string The text to display in the marquee
---@param font string The font to render the text with
---@param color Color? The text color, defaults to white
---@param ticker {dir: integer, delay: number, origin: number, x: number, y: number}
---@param width number The maximum width of the marquee area
---@param speed number? The scroll speed of the ticker
---@param delay number? The delay before scrolling begins
---@return {dir: integer, delay: number, origin: number, x: number, y: number}
local function TickerText(text, font, color, ticker, width, speed, delay)
	color = color or Color(255, 255, 255, 255)
	surface.SetFont(font)
	surface.SetTextColor(color.r, color.g, color.b, color.a)
	local w, h = surface.GetTextSize(text)

	if w > width and ticker.delay < CurTime() then
		--Right
		if ticker.dir == 1 then
			local pos = width - w - 2

			if ticker.x != pos then
				ticker.x = math.Approach(ticker.x, pos, FrameTime() * (speed or 10))
			else
				ticker.dir = 0
				ticker.delay = CurTime() + delay
			end
		else --Left
			local pos = ticker.origin

			if ticker.x != pos then
				ticker.x = math.Approach(ticker.x, pos, FrameTime() * (speed or 10))
			else
				ticker.dir = 1
				ticker.delay = CurTime() + delay
			end
		end
	end

	surface.SetTextPos(ticker.x, ticker.y)
	surface.DrawText(text)

	return ticker
end

gmcore.MapVote = {}
gmcore.MapVote.VoteButtons = {} -- This is edited when the map vote buttons are created. Used for flashing the map
gmcore.MapVote.Maps = {}

--[[
	Calculate font sizing for scaling down and up:
	Formula (All scaling done in 1440px height): fontSize{px}/ScrH()
]]
--local gridMarkerSize = math.floor(ScrH() * (90 / 1440))
local mapHeaderSize = math.floor(ScrH() * (75 / 1440))
local mapButtonTitleSize = math.floor(ScrH() * (30 / 1440))
local mapVoteCountSize = math.floor(ScrH() * (40 / 1440))
local mapPlayerBalletCount = math.floor(ScrH() * (30 / 1440))
local inHiddenPhase = true
local voteCueY = 70

local sWinningMapID = nil -- This changes when the winning map is found. Used for flashing the map
local mapVotePanel = nil

surface.CreateFont("gmcore.MapVote.VoteTime", {
	font = "Bebas Neue",
	italic = true,
	size = mapHeaderSize,
	weight = 700
})

surface.CreateFont("gmcore.MapVote.MapTitle", {
	font = "Bebas Neue",
	size = mapButtonTitleSize,
	weight = 300
})

surface.CreateFont("gmcore.MapVote.VoteCount", {
	font = "Bebas Neue",
	size = mapVoteCountSize,
	weight = 300
})

surface.CreateFont("gmcore.MapVote.GridMarker", {
	font = "Bebas Neue",
	size = 60,
	weight = 500
})

surface.CreateFont("gmcore.MapVote.WinningMapHeader", {
	font = "Bebas Neue",
	size = 85,
	weight = 500
})

surface.CreateFont("gmcore.MapVote.AvatarVoterMultiplier", {
	font = "Bebas Neue",
	size = mapPlayerBalletCount,
	weight = 500
})

surface.CreateFont("gmcore.MapVote.AvatarVoterMultiplierSmall", {
	font = "Bebas Neue",
	size = mapPlayerBalletCount,
	weight = 500
})


surface.CreateFont("gmcore.MapVote.RemainingTime", {
	font = "Bebas Neue",
	size = 35,
	weight = 300
})

local blur = Material("pp/blurscreen")

local function DrawBlur(p, a, d)
	local x, y = p:LocalToScreen(0, 0)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(blur)

	for i = 1, d do
		blur:SetFloat("$blur", (i / d) * a)
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
	end
end

---@class gmcoreMapVoteMenu : DPanel
local PANEL = {}

function PANEL:Init()
	mapVotePanel = self

	-- Cache these since we override to have voice boxes drawn ontop
	self.OldShow = DFrame.Show
	self.OldHide = DFrame.Hide

	self.startTime = nil -- Used for time remaining
	self.mapButtonW = ScrH() * .12
	self.mapButtonH = ScrH() * .12

	-- So below scales to 1920, is it trash, yes but does it work? Also yes. I'll make it dynamic later

	self:SetSize(ScrW(), ScrH())
	self:Center()

	if ScrH() < 860 then
		voteCueY = 10
	end

	self:BuildMenu()
	gui.EnableScreenClicker(true)
end

---Trims map name suffixes (_gl, _ahg, optionally _fix and version suffixes).
---@param mapName string The raw map name to trim
---@param removeAllSuffixes boolean? Also remove _fix and version suffixes
---@return string trimmedName The map name with matching suffixes removed
local function trimMapName(mapName, removeAllSuffixes)
	local name = mapName

	-- Remove _gl and _ahg suffixes
	local patterns = { "_gl", "_ahg" }
	for _, pattern in ipairs(patterns) do
		local first = string.find(name, pattern)
		if first ~= nil then
			name = string.sub(name, 1, first - 1)
		end
	end

	if not removeAllSuffixes then return name end

	-- Remove _fix suffix
	local first = string.find(name, "_fix")
	if first ~= nil then
		name = string.sub(name, 1, first - 1)
	end

	-- Remove version suffixes e.g. _v4, _a3, _b5, etc.
	local versionPattern = "_[avbro0]%d+"
	first = string.find(name, versionPattern)
	if first ~= nil then
		name = string.sub(name, 1, first - 1)
	end

	return name
end

---Builds base elements like the icon layout, grid labels, and phase label.
function PANEL:BuildMenu()
	self.closeButton = vgui.Create("DButton", self)
	self.closeButton:SetPos(ScrW() - 100, 0)
	self.closeButton:SetSize(100, 50)
	self.closeButton:SetFont("gmcore.MapVote.MapTitle") -- Reuse the font cuz it looks good
	self.closeButton:SetText("X")
	self.closeButton.Paint = function(s, w, h)
		surface.SetDrawColor(185, 37, 37, 25)
		surface.DrawRect(0, 0, w, h)

		if s:IsVisible() then
			gui.EnableScreenClicker(true)
		end
	end

	self.closeButton.DoClick = function()
		self:Hide()
		gui.EnableScreenClicker(false)
	end

	self.voteTime = vgui.Create("DLabel", self)
	self.voteTime:SetFont("gmcore.MapVote.VoteTime")
	self.voteTime:SetTextColor(Color(255, 0, 0))
	self.voteTime:SetText("SELECT YOUR MAP!")
	self.voteTime:SizeToContents()
	self.voteTime:SetWide(self.voteTime:GetWide() + 20) -- Fix because italicized text get's cut off
	self.voteTime:SetPos((self:GetWide() / 2) - (self.voteTime:GetWide() / 2), voteCueY)	-- Centers the Vote time label


	local _oldSetTextFunc = self.voteTime.SetText

	self.voteTime.SetText = function(s, ...)
		_oldSetTextFunc(s, ...)
		s:SizeToContents()
		s:SetPos((self:GetWide() / 2) - (s:GetWide() / 2), 10)
	end

	self.mapIconLayout = vgui.Create("DIconLayout", self)

	--self.mapIconLayout:SetSize(self.mapButtonW * 5 + iSpaceX * 2, ScrH() - 150)
	self.mapIconLayout:SetSize(self.mapButtonW * 5 + 80, (self.mapButtonH * 5) + (15 * 5))
	self.mapIconLayout:SetSpaceX(15)
	self.mapIconLayout:SetSpaceY(15)
	self.mapIconLayout:SetPos(ScrW() / 2 - self.mapIconLayout:GetWide() / 2, ScrH() / 2 - self.mapIconLayout:GetTall() / 2)

	-- Initialize grid labels table for centralized management
	self.gridLabels = {}

	-- Create row labels (A-E)
	local rowLabels = {"A", "B", "C", "D", "E"}
	for i, label in ipairs(rowLabels) do
		self.gridLabels[label] = self:CreateGridLabel(label)
	end

	-- Create column labels (1-5)
	for i = 1, 5 do
		self.gridLabels[tostring(i)] = self:CreateGridLabel(tostring(i))
	end

	-- Maintain backward compatibility with existing references
	self.gridA, self.gridB, self.gridC, self.gridD, self.gridE = self.gridLabels["A"], self.gridLabels["B"], self.gridLabels["C"], self.gridLabels["D"], self.gridLabels["E"]
	self.grid1, self.grid2, self.grid3, self.grid4, self.grid5 = self.gridLabels["1"], self.gridLabels["2"], self.gridLabels["3"], self.gridLabels["4"], self.gridLabels["5"]

	-- Position all grid labels
	self:PositionGridLabels()

	self.phaseLabel = vgui.Create("DLabel", self)
	self.phaseLabel:SetFont("gmcore.MapVote.RemainingTime")
	self.phaseLabel:SetText("HIDDEN PHASE | VOTES ARE HIDDEN")
	self.phaseLabel:SetTextColor(Color(255, 255, 0))
	self.phaseLabel:SizeToContents()
	self.phaseLabel:SetPos(ScrW() / 2 + self.mapIconLayout:GetWide() / 2 - self.phaseLabel:GetWide(), (mapVotePanel.mapIconLayout.y + mapVotePanel.mapIconLayout:GetTall() + 20) - self.phaseLabel:GetTall() / 2)

end

---Creates a single grid label with standard properties.
---@param text string The label text to display
---@return DLabel label The styled grid label for the map vote panel
function PANEL:CreateGridLabel(text)
	local label = vgui.Create("DLabel", self)
	label:SetTextColor(color_white)
	label:SetFont("gmcore.MapVote.GridMarker")
	label:SetText(text)
	label:SizeToContents()

	return label
end

---Positions all grid labels based on current layout.
function PANEL:PositionGridLabels()
	local xSpacing = math.floor(self.mapIconLayout.x / 1.166)
	local offsetX = self.mapButtonW + 15
	local offsetY = self.mapButtonH + 15

	-- Position row labels (A-E)
	local rowLabels = {"A", "B", "C", "D", "E"}
	for i, label in ipairs(rowLabels) do
		if self.gridLabels[label] then
			local yPos = (self.mapIconLayout.y + (self.mapButtonH / 2)) - (self.gridLabels[label]:GetTall() / 2) + (offsetY * (i - 1))
			self.gridLabels[label]:SetPos(xSpacing, yPos)
		end
	end

	-- Position column labels (1-5)
	for i = 1, 5 do
		local label = tostring(i)
		if self.gridLabels[label] then
			local xPos = (self.mapIconLayout.x + (self.mapButtonW / 2)) - (self.gridLabels[label]:GetWide() / 2) + (offsetX * (i - 1))
			local yPos = (self.mapIconLayout.y + 5) - (self.gridLabels[label]:GetTall())
			self.gridLabels[label]:SetPos(xPos, yPos)
		end
	end
end

---Shows or hides specific grid labels by their keys.
---@param labels string[] The grid label keys to update
---@param visible boolean Whether the labels should be visible
function PANEL:SetGridLabelsVisible(labels, visible)
	for _, label in ipairs(labels) do
		if self.gridLabels[label] then
			self.gridLabels[label]:SetVisible(visible)
		end
	end
end

--Temp function for halloween event/small map pool periods.
function convertTo3by3()
	mapVotePanel.mapButtonW = ScrH() * .20
	mapVotePanel.mapButtonH = ScrH() * .20

	mapVotePanel.mapIconLayout:SetSize(mapVotePanel.mapButtonW * 3 + (mapVotePanel.mapIconLayout:GetSpaceX() * 3), mapVotePanel.mapButtonH * 3 + (mapVotePanel.mapIconLayout:GetSpaceY() * 3))
	mapVotePanel.mapIconLayout:SetPos((mapVotePanel:GetWide() / 2) - (mapVotePanel.mapIconLayout:GetWide() / 2), ScrH() / 2 - mapVotePanel.mapIconLayout:GetTall() / 2)

	-- Reposition all grid labels for 3x3 layout
	mapVotePanel:PositionGridLabels()
end

---Begins the map vote with the given maps and start time.
---@param maps table The table of maps available for voting
---@param iStartTime number The timestamp when voting started
function PANEL:BeginVote(maps, iStartTime)
	self.startTime = iStartTime

	self:RenderMapButtons(maps)

	if g_VoicePanelList then
		g_VoicePanelList:SetDrawOnTop(true)
	end
end

---Renders the map vote buttons from the given maps table.
---@param maps table The table of maps to create vote buttons for
function PANEL:RenderMapButtons(maps)
	-- First remove any children inside DIconLayout if there are any
	gmcore.MapVote.VoteButtons = {}

	for k, pnl in pairs(self.mapIconLayout:GetChildren()) do
		pnl:Remove()
	end

	-- New add maps that exist in function
	for mapId, map in SortedPairsByMemberValue(maps.mapList, "order") do
		if maps.mapList[mapId] == nil then continue end

		-- TODO: Move this vote button to it's own independent VGUI Element for better organization
		map.voteButton = self.mapIconLayout:Add("DButton")
		map.voteButton:SetSize(self.mapButtonW, self.mapButtonH)
		map.voteButton:SetText("")
		map.voteButton:SetEnabled(true)
		map.voteButton.Ticker = NewTicker(4, 2)
		map.voteButton.MapID = mapId
		if !gmcore.MapVote.VoteButtons[mapId] then
			gmcore.MapVote.VoteButtons[mapId] = map.voteButton
		end

		map.voteButton.DoClick  = function ()
			if sWinningMapID != nil then return end -- Winning map has been chosen

			surface.PlaySound("buttons/button3.wav")

			if gmcore.MapVote.SelectedMapVote == nil and gmcore.MapVote.SelectionMade == nil then
				gmcore.MapVote.SelectionMade = true
			end

			gmcore.MapVote.SelectedMapVote = mapId

			self.voteTime:SetTextColor(Color(0, 255, 0))
			self.voteTime:SetText("Map Selected!")
			self.voteTime:SizeToContents()
			self.voteTime:SetWide(self.voteTime:GetWide() + 20)
			self.voteTime:SetPos((self:GetWide() / 2) - (self.voteTime:GetWide() / 2), voteCueY)

			net.Start("gmcore.MapVote.MapVoteSelection")
			net.WriteString(mapId)
			net.SendToServer()
		end

		map.voteButton.Paint = function(s, w, h)
			if gmcore.MapVote.Maps.mapList[mapId] == nil then s:Remove() return end

			surface.SetFont("gmcore.MapVote.MapTitle")
			local iTextW, iTextH = surface.GetTextSize(mapId)

			surface.SetDrawColor(color_white)
			--print(string.GetFileFromFilename("materials/gl/mapvote/" .. string.lower(mapId) .. ".png"))
			surface.SetMaterial(Material("materials/gl/mapvote/" .. trimMapName(string.lower(mapId), false) .. ".png"))
			surface.DrawTexturedRect(0, 0, s:GetWide(), s:GetTall())

			surface.SetDrawColor(Color(0, 0, 0, 235))
			surface.DrawRect(0, 3, s:GetWide(), iTextH - 3)

			if !s.isFlashed and gmcore.MapVote.SelectedMapVote == mapId then
				surface.SetDrawColor(255, 0, 0, 255) -- Top border
				surface.DrawRect(0, 0, w, h * 0.10)

				surface.SetDrawColor(255, 0, 0, 255) -- Left border
				surface.DrawRect(0, 0, h * 0.10, h)

				surface.SetDrawColor(255, 0, 0, 255) -- Bottom border
				surface.DrawRect(0, h - math.floor(h * 0.10), w, h * 0.10)

				surface.SetDrawColor(255, 0, 0, 255) -- Right border
				surface.DrawRect(math.ceil(w - h * 0.10), 0, h * 0.10, h)
			end

			if s.isFlashed then
				surface.SetDrawColor(0, 255, 0, 255) -- Top border
				surface.DrawRect(0, 0, w, h * 0.10)

				surface.SetDrawColor(0, 255, 0, 255) -- Left border
				surface.DrawRect(0, 0, h * 0.10, h)

				surface.SetDrawColor(0, 255, 0, 255) -- Bottom border
				surface.DrawRect(0, h - math.floor(h * 0.10), w, h * 0.10)

				surface.SetDrawColor(0, 255, 0, 255) -- Right border
				surface.DrawRect(math.ceil(w - h * 0.10), 0, h * 0.10, h)
			end

			-- TODO: Get this trimMapName out of the paint loop to prevent duplicate work.
			TickerText(trimMapName(mapId, true), "gmcore.MapVote.MapTitle", color_white, s.Ticker, s:GetWide() - 4, 25, 1)

			if !inHiddenPhase then
				local iNumVotes = gmcore.MapVote.Maps.mapList[mapId].totalVotes

				surface.SetFont("gmcore.MapVote.VoteCount")
				surface.SetTextPos(5, 2 + select(2, surface.GetTextSize(mapId)))
				surface.DrawText(tostring(iNumVotes))

				local perWin = iNumVotes / gmcore.MapVote.Maps.totalVotes * 100
				if iNumVotes == 0 and gmcore.MapVote.Maps.totalVotes == 0 then -- Is this a hacky way to fix nan percent error. Yes. Does it work though, yes
					perWin = 0
				end

				perWin = math.Round(perWin)
				iTextW, iTextH = surface.GetTextSize(perWin .. "%")

				surface.SetTextPos(w - iTextW - 5, 2 + iTextH)
				surface.DrawText(tostring(perWin) .. "%")
			else
				surface.SetTextPos(5, 2 + select(2, surface.GetTextSize(mapId)))
				surface.DrawText("?")

				iTextW, iTextH = surface.GetTextSize("???")

				surface.SetTextPos(w - iTextW - 5, 2 + iTextH)
				surface.DrawText("???")
			end

			if sWinningMapID != nil and sWinningMapID == mapId then
				surface.SetFont("gmcore.MapVote.WinningMapHeader")
				iTextW, iTextH = surface.GetTextSize("WINNER")

				DisableClipping(true)
					surface.SetTextColor(0, 0, 0)
					surface.SetTextPos(w / 2 - iTextW / 2 + 2, -iTextH * 0.75 + 2) -- Cheap way to get text outlined so contrast is nice
					surface.DrawText("WINNER")

					surface.SetTextColor(255, 255, 255)
					surface.SetTextPos(w / 2 - iTextW / 2, -iTextH * 0.75)
					surface.DrawText("WINNER")
					DisableClipping(false)
				end
			end

			map.votersContainer = vgui.Create("DIconLayout", map.voteButton)
			map.votersContainer:SetSize(map.voteButton:GetWide(), map.voteButton:GetTall() * .25)
			map.votersContainer:SetPos(5, map.voteButton:GetTall() - map.votersContainer:GetTall())
			map.votersContainer:SetSpaceX(5)
			map.votersContainer:SetSpaceY(5)
		end
end

---Updates voter avatar icons on each map button.
function PANEL:UpdateVoters()
	for mapId, map in pairs(gmcore.MapVote.Maps.mapList) do
		if gmcore.MapVote.Maps.mapList[mapId] == nil then continue	end

		map.votersContainer:Clear() -- Remove old voters and update with new

		for k, v in pairs(map.voters) do
			v = player.GetBySteamID64(k)
			if !IsValid(v) then continue end

			local iPlyVoteCount = v:IsStoreRank() and gmcore.StoreRank.Ranks[v:GetStoreRank()].vcount or 1

			local av = map.votersContainer:Add("AvatarImage")
			av:SetSize(24, 24)
			av:SetPlayer(v, 24)
			av:SetVisible(true)
			av:SetTooltip(v:Nick() .. " | Ballet Count: " .. iPlyVoteCount)
		end
	end
end

function PANEL:Paint(w, h)
	DrawBlur(self, 3, 5)

	surface.SetDrawColor(20, 20, 20, 200)
	surface.DrawRect(0, 0, w, h)

	-- Vote time bar
	local iBelowMapList = self.mapIconLayout.y + self.mapIconLayout:GetTall() + 20
	local timeUntilFinish = self.startTime + 20 - CurTime()
	local timeRemainingDelta =  math.TimeFraction(self.startTime, self.startTime + 20, CurTime()) * self.mapIconLayout:GetWide()
	local timeRemainingFormatted = string.FormattedTime(math.max(self.startTime + 20 - CurTime(), 0), "%02i:%02i:%02i")

	-- Flash yellow when the timer is below 5 seconds.
	surface.SetTextColor(color_white)
	if timeUntilFinish <= 5 and timeUntilFinish >= 0 and math.ceil(timeUntilFinish) % 2 == 1  then
		surface.SetTextColor(Color(255, 255, 0))
	end

	surface.SetTextPos(ScrW() / 2 - self.mapIconLayout:GetWide() / 2, iBelowMapList)
	surface.SetFont("gmcore.MapVote.RemainingTime")
	surface.DrawText(timeRemainingFormatted)

	local _iTextW, iTextH = surface.GetTextSize(timeRemainingFormatted)

	if timeUntilFinish >= 10 then
		surface.SetDrawColor(Color(255, 0, 0))
	else
		surface.SetDrawColor(color_white)
	end

	surface.DrawRect(ScrW() / 2 - self.mapIconLayout:GetWide() / 2, iBelowMapList + iTextH, self.mapIconLayout:GetWide() - timeRemainingDelta, 35)
end

-- Have voice boxes drawn ontop of everything when reappearing
function PANEL:Show()
	self.OldShow(self)

	g_VoicePanelList:SetDrawOnTop(true)
end

-- Stop voiceboxes being drawn ontop of everything when we hide the mapvote ("X" btn clicked)
function PANEL:Hide()
	self.OldHide(self)

	g_VoicePanelList:SetDrawOnTop(false)
end

vgui.Register("glMapVoteMenu", PANEL, "DPanel")

---Toggles the flash overlay on the winning map's vote button.
local function flashWinningMapButton()
	local panel = gmcore.MapVote.VoteButtons[sWinningMapID]
	if !IsValid(panel) then ErrorNoHalt("Attempt to flash winning map votebutton. Panel is invalid or doesn't exist") return end -- Did the player really want to close the map vote panel?

	if !panel.isFlashed or panel.isFlashed == false then
		surface.PlaySound("hl1/fvox/blip.wav")
		panel.isFlashed = true
	elseif panel.isFlashed then
		panel.isFlashed = false
	end
end

---After hidden phase, ensures the random map choice is in the center of the grid.
local function putRandomInMiddle()
	local iterationNum = 1

		for mapName, mapData in SortedPairsByMemberValue(gmcore.MapVote.Maps.mapList, "order") do
			if gmcore.MapVote.Maps.mapList[mapName] == nil then continue end

			if iterationNum == 5 then
				local temp = mapData.order
				mapData.order = gmcore.MapVote.Maps.mapList["random"].order
				gmcore.MapVote.Maps.mapList["random"].order = temp
			end

			iterationNum = iterationNum + 1
		end
	end

net.Receive("gmcore.MapVote.SendWinningMap", function(len)
	sWinningMapID = net.ReadString()

	if sWinningMapID != "random" then
		gmcore.chatprint("The votes have been counted. The winning map is ", Color(0, 255, 0), sWinningMapID)

		mapVotePanel.voteTime:SetText("VOTES COUNTED: " .. string.upper(trimMapName(sWinningMapID)) .. " WINS!")
		mapVotePanel.voteTime:SizeToContents()
		mapVotePanel.voteTime:SetSize(mapVotePanel.voteTime:GetWide() + 20, mapVotePanel.voteTime:GetTall()) -- Add extra 20px to width since SizeToContents doesn't work with italics

		timer.Create("gmcore.MapVote.WinnerFlash", 0.2 , 5, flashWinningMapButton)
		timer.Start("gmcore.MapVote.WinnerFlash")
	else
		gmcore.chatprint("Choosing a", Color(0, 255, 0), " random map", color_white, "!")
		mapVotePanel.voteTime:SetText("RANDOM MAP!")
		mapVotePanel.voteTime:SizeToContents()
		mapVotePanel.voteTime:SetWide(mapVotePanel.voteTime:GetWide() + 20) -- Fix because italicized text get's cut off
	end
end)

local pMenu = nil

net.Receive("gmcore.MapVote.StartVoting", function(len)
	if pMenu == nil then
		local iTimeStart = net.ReadFloat()
		gmcore.MapVote.Maps = net.ReadTable()

		pMenu = vgui.Create("glMapVoteMenu")
		pMenu:BeginVote(gmcore.MapVote.Maps, iTimeStart)
	else
		pMenu:Show()
	end
end)

net.Receive("gmcore.MapVote.UpdateVotingTable", function()
	local sentTable = net.ReadTable()

	for mapID, map in pairs(gmcore.MapVote.Maps.mapList) do -- A hacky way to prevent our votersContainers and other panels from being removed
		if sentTable.mapList[mapID] == nil then
			gmcore.MapVote.Maps.mapList[mapID] = nil
			continue
		end

		map.voters = sentTable.mapList[mapID].voters
		map.totalVotes = sentTable.mapList[mapID].totalVotes

	end

	gmcore.MapVote.Maps.totalVotes = sentTable.totalVotes

	mapVotePanel:UpdateVoters()
end)

net.Receive("gmcore.MapVote.PhaseChangeNotice", function()
	mapVotePanel.mapButtonW = ScrH() * .20
	mapVotePanel.mapButtonH = ScrH() * .20

	mapVotePanel.mapIconLayout:SetSize(mapVotePanel.mapButtonW * 3 + (mapVotePanel.mapIconLayout:GetSpaceX() * 3), mapVotePanel.mapButtonH * 3 + (mapVotePanel.mapIconLayout:GetSpaceY() * 3))
	mapVotePanel.mapIconLayout:SetPos((mapVotePanel:GetWide() / 2) - (mapVotePanel.mapIconLayout:GetWide() / 2), ScrH() / 2 - mapVotePanel.mapIconLayout:GetTall() / 2)

	-- Hide grids not needed for 3x3 layout
	mapVotePanel:SetGridLabelsVisible({"D", "E", "4", "5"}, false)

	-- Reposition all remaining grid labels for 3x3 layout
	mapVotePanel:PositionGridLabels()

	mapVotePanel.phaseLabel:SetText("VOTES REVEALED!")
	mapVotePanel.phaseLabel:SizeToContents()
	mapVotePanel.phaseLabel:SetPos(ScrW() / 2 + mapVotePanel.mapIconLayout:GetWide() / 2 - mapVotePanel.phaseLabel:GetWide(), (mapVotePanel.mapIconLayout.y + mapVotePanel.mapIconLayout:GetTall() + 20) - mapVotePanel.phaseLabel:GetTall() / 2)

	putRandomInMiddle()

	mapVotePanel:RenderMapButtons(gmcore.MapVote.Maps)
	mapVotePanel:UpdateVoters()

	if gmcore.MapVote.Maps.mapList[gmcore.MapVote.SelectedMapVote] == nil and gmcore.MapVote.SelectionMade != nil then
		mapVotePanel.voteTime:SetTextColor(Color(255, 0, 0))
		mapVotePanel.voteTime:SetText("Your map was eliminated, choose a new map!")
		mapVotePanel.voteTime:SizeToContents()
		mapVotePanel.voteTime:SetWide(mapVotePanel.voteTime:GetWide() + 20)
		mapVotePanel.voteTime:SetPos((mapVotePanel:GetWide() / 2) - (mapVotePanel.voteTime:GetWide() / 2), voteCueY)

		gmcore.chatprint("Your map choice did not make it to the second round! Please cast another vote.")
	end

	inHiddenPhase = false
end)

net.Receive("gmcore.MapVote.SendRTVNotice", function()
	local pPlyRTVer = net.ReadEntity()
	local iRTVCount = net.ReadInt(8)
	local bIsSuccessfulRTV = net.ReadBool()

	if bIsSuccessfulRTV then
		gmcore.chatprint(CHAT_PRINT_BLUE, pPlyRTVer:Nick(), color_white, " has voted to rock the vote! Enough votes to rock the vote! MapVote will begin when round ends!")
	else
		gmcore.chatprint(CHAT_PRINT_BLUE, pPlyRTVer:Nick(), color_white, " has voted to rock the vote (" .. iRTVCount .. "/" .. math.Round(#player.GetAll() * 0.75) .. ") Type ", CHAT_PRINT_BLUE, "!rtv ", color_white, "to add your vote!")
	end
end)

gmcore.print("Loaded client mapvote")
