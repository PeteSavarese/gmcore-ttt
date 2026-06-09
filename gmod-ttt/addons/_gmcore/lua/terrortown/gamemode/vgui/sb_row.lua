include("sb_info.lua")

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local OpenedVoicePanels = {}

local function HideVolumePanels()
	for _, pnl in pairs(OpenedVoicePanels) do
			if IsValid(pnl) then
				pnl:Close()
				pnl = nil
			end
	end
end

hook.Add("ScoreboardHide", "TTT_HideVolumePanels", HideVolumePanels)

SB_ROW_HEIGHT = 24 --16

---@class TTTScorePlayerRow : DButton
local PANEL = {}

function PANEL:Init()
	-- cannot create info card until player state is known
	self.info = nil
	self.open = false
	self.cols = {}
	self:AddColumn(GetTranslation("sb_ping"), function(ply) return ply:Ping() end)
	self:AddColumn(GetTranslation("sb_deaths"), function(ply) return ply:Deaths() end)
	self:AddColumn(GetTranslation("sb_score"), function(ply) return ply:Frags() end)

	if KARMA.IsEnabled() then
		self:AddColumn(GetTranslation("sb_karma"), function(ply) return math.Round(ply:GetBaseKarma()) end)
	end

	-- Let hooks add their custom columns
	hook.Call("TTTScoreboardColumns", nil, self)

	for _, c in ipairs(self.cols) do
		c:SetMouseInputEnabled(false)
	end

	self.tag = vgui.Create("DLabel", self)
	self.tag:SetText("")
	self.tag:SetMouseInputEnabled(false)
	self.sresult = vgui.Create("DImage", self)
	self.sresult:SetSize(16, 16)
	self.sresult:SetMouseInputEnabled(false)
	self.avatar = vgui.Create("AvatarImage", self)
	self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
	self.avatar:SetMouseInputEnabled(false)
	self.nick = vgui.Create("DLabel", self)
	self.nick:SetMouseInputEnabled(false)
	self.voice = vgui.Create("DImageButton", self)
	self.voice:SetSize(16, 16)
	self:SetCursor("hand")
end

---@param label string Column header text
---@param func fun(ply: Player, lbl?: DLabel): string|number Data getter
---@param width? number Column width in pixels (default 50)
---@return DLabel lbl The created column label
function PANEL:AddColumn(label, func, width, _, _)
	local lbl = vgui.Create("DLabel", self)
	lbl.GetPlayerText = func
	lbl.IsHeading = false
	lbl.Width = width or 50 -- Retain compatibility with existing code
	table.insert(self.cols, lbl)

	return lbl
end

-- Mirror sb_main, of which it and this file both call using the
--    TTTScoreboardColumns hook, but it is useless in this file
-- Exists only so the hook wont return an error if it tries to
--    use the AddFakeColumn function of `sb_main`, which would
--    cause this file to raise a `function not found` error or others
function PANEL:AddFakeColumn() end

local namecolor = {
	default = COLOR_WHITE,
	admin = Color(220, 180, 0, 255),
	dev = Color(100, 240, 105, 255)
}

local rolecolor = {
	default = Color(0, 0, 0, 0),
	traitor = Color(255, 0, 0, 30),
	detective = Color(0, 0, 255, 30)
}

---@param ply Player Player to determine the name color for
---@return Color color Name colour for the scoreboard
function GM:TTTScoreboardColorForPlayer(ply)
	if !IsValid(ply) then return namecolor.default end

	if ply:SteamID() == "STEAM_0:0:1963640" then
		return namecolor.dev
	elseif ply:IsAdmin() and GetGlobalBool("ttt_highlight_admins", true) then
		return namecolor.admin
	end

	return namecolor.default
end

---@param ply Player Player to determine the row background color for
---@return Color color Row background colour based on role
function GM:TTTScoreboardRowColorForPlayer(ply)
	if !IsValid(ply) then return rolecolor.default end

	if ply:IsTraitor() then
		return rolecolor.traitor
	elseif ply:IsDetective() then
		return rolecolor.detective
	end

	return rolecolor.default
end

local function ColorForPlayer(ply)
	if IsValid(ply) then
		local c = hook.Call("TTTScoreboardColorForPlayer", GAMEMODE, ply)

		-- verify that we got a proper color
		if c and istable(c) and c.r and c.b and c.g and c.a then
			return c
		else
			ErrorNoHalt("TTTScoreboardColorForPlayer hook returned something that isn't a color!\n")
		end
	end

	return namecolor.default
end

function PANEL:Paint(width, height)
	if !IsValid(self.Player) then return end
	--   if ( self.Player:GetFriendStatus() == "friend" ) then
	--      color = Color( 236, 181, 113, 255 )
	--   end
	local ply = self.Player
	local c = hook.Call("TTTScoreboardRowColorForPlayer", GAMEMODE, ply)

	surface.SetDrawColor(c)
	surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)

	if ply == LocalPlayer() then
		surface.SetDrawColor(200, 200, 200, math.Clamp(math.sin(RealTime() * 2) * 50, 0, 100))
		surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)
	end

	return true
end

---@param ply Player The player this row represents
function PANEL:SetPlayer(ply)
	self.Player = ply
	self.avatar:SetPlayer(ply)

	if !self.info then
		local g = ScoreGroup(ply)

		if g == GROUP_TERROR and ply ~= LocalPlayer() then
			self.info = vgui.Create("TTTScorePlayerInfoTags", self)
			self.info:SetPlayer(ply)
			self:InvalidateLayout()
		elseif g == GROUP_FOUND or g == GROUP_NOTFOUND then
			self.info = vgui.Create("TTTScorePlayerInfoSearch", self)
			self.info:SetPlayer(ply)
			self:InvalidateLayout()
		end
	else
		self.info:SetPlayer(ply)
		self:InvalidateLayout()
	end

	self.voice.DoClick = function()
		if IsValid(ply) and ply ~= LocalPlayer() then
			ply:SetMuted(!ply:IsMuted())
		end
	end

	self.voice.DoRightClick = function()
		if IsValid(ply) and ply != LocalPlayer() then
				self:ShowMicVolumeSlider()
		end
	end

	self:UpdatePlayerData()
end

---@return Player ply The player this row represents
function PANEL:GetPlayer()
	return self.Player
end

function PANEL:UpdatePlayerData()
	if !IsValid(self.Player) then return end
	local ply = self.Player

	for i = 1, #self.cols do
		-- Set text from function, passing the label along so stuff like text
		-- color can be changed
		self.cols[i]:SetText(self.cols[i].GetPlayerText(ply, self.cols[i]))
	end

	self.nick:SetText(ply:Nick())
	self.nick:SizeToContents()
	self.nick:SetTextColor(ColorForPlayer(ply))
	local ptag = ply.sb_tag

	if ScoreGroup(ply) ~= GROUP_TERROR then
		ptag = nil
	end

	self.tag:SetText(ptag and GetTranslation(ptag.txt) or "")
	self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
	self.sresult:SetVisible(ply.search_result ~= nil)

	-- more blue if a detective searched them
	if ply.search_result and (LocalPlayer():IsDetective() or (!ply.search_result.show)) then
		self.sresult:SetImageColor(Color(200, 200, 255))
	end

	-- cols are likely to need re-centering
	self:LayoutColumns()

	if self.info then
		self.info:UpdatePlayerData()
	end

	if self.Player ~= LocalPlayer() then
		local muted = self.Player:IsMuted()
		self.voice:SetImage(muted and "icon16/sound_mute.png" or "icon16/sound.png")
	else
		self.voice:Hide()
	end
end

function PANEL:ApplySchemeSettings()
	for k, v in pairs(self.cols) do
		v:SetFont("treb_small")
		v:SetTextColor(COLOR_WHITE)
	end

	self.nick:SetFont("treb_small")
	self.nick:SetTextColor(ColorForPlayer(self.Player))
	local ptag = self.Player and self.Player.sb_tag
	self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
	self.tag:SetFont("treb_small")
	self.sresult:SetImage("icon16/magnifier.png")
	self.sresult:SetImageColor(Color(170, 170, 170, 150))
end

function PANEL:LayoutColumns()
	local cx = self:GetWide() - 25

	for k, v in ipairs(self.cols) do
		v:SizeToContents()
		cx = cx - v.Width / 2
		v:SetPos(cx - v:GetWide() / 2, (SB_ROW_HEIGHT - v:GetTall()) / 2)
		cx = cx - v.Width / 2
	end

	self.tag:SizeToContents()
	cx = cx - 90
	self.tag:SetPos(cx - self.tag:GetWide() / 2, (SB_ROW_HEIGHT - self.tag:GetTall()) / 2)
	self.sresult:SetPos(cx - 8, (SB_ROW_HEIGHT - 16) / 2)
end

function PANEL:PerformLayout()
	self.avatar:SetPos(0, 0)
	self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
	local fw = sboard_panel.ply_frame:GetWide()
	self:SetWide(sboard_panel.ply_frame.scroll.Enabled and fw - 16 or fw)

	if !self.open then
		self:SetSize(self:GetWide(), SB_ROW_HEIGHT)

		if self.info then
			self.info:SetVisible(false)
		end
	elseif self.info then
		self:SetSize(self:GetWide(), 100 + SB_ROW_HEIGHT)
		self.info:SetVisible(true)
		self.info:SetPos(5, SB_ROW_HEIGHT + 5)
		self.info:SetSize(self:GetWide(), 100)
		self.info:PerformLayout()
		self:SetSize(self:GetWide(), SB_ROW_HEIGHT + self.info:GetTall())
	end

	self.nick:SizeToContents()
	self.nick:SetPos(SB_ROW_HEIGHT + 10, (SB_ROW_HEIGHT - self.nick:GetTall()) / 2)
	self:LayoutColumns()
	self.voice:SetVisible(!self.open)
	self.voice:SetSize(16, 16)
	self.voice:DockMargin(4, 4, 4, 4)
	self.voice:Dock(RIGHT)
end

function PANEL:DoClick(x, y)
	local x = self.avatar:LocalToScreen(0,0)
	local x2 = input.GetCursorPos()
	if(x2 > x and x2 < x + 30) then
	local lply = LocalPlayer()
	if IsValid(lply) and (!lply:Alive() or lply:IsSpec()) then
			surface.PlaySound("ui/buttonclick.wav")
			net.Start("SB_Spectate")
				net.WriteEntity(self:GetPlayer())
			net.SendToServer()
		end
	else
		self:SetOpen(!self.open)
	end
end

function PANEL:SetOpen(o)
	if self.open then
		surface.PlaySound("ui/buttonclickrelease.wav")
	else
		surface.PlaySound("ui/buttonclick.wav")
	end

	self.open = o
	self:PerformLayout()
	self:GetParent():PerformLayout()
	sboard_panel:PerformLayout()
end

function PANEL:DoRightClick()
	local menu = DermaMenu()
	menu.Player = self:GetPlayer()

	menu:Open()
	local ply = self.Player
	surface.PlaySound("buttons/button9.wav")
	local options = DermaMenu()

	options:AddOption("Copy Name", function()
		if not IsValid(ply) then return end

		SetClipboardText(ply:Nick())
		gmcore.chatprint("Name copied to clipboard.")
		surface.PlaySound("buttons/button9.wav")
	end):SetImage("icon16/user_edit.png")

	options:AddOption("Copy SteamID", function()
		if not IsValid(ply) then return end

		SetClipboardText(ply:SteamID())
		gmcore.chatprint("SteamID copied to clipboard.")
		surface.PlaySound("buttons/button9.wav")
	end):SetImage("icon16/tag_blue.png")

	options:AddOption("Send Private Message", function()
		if not IsValid(ply) then return end

		Derma_StringRequest("Private Message", "Type a message to private message to " .. ply:Nick() .. "", "", function(text)
			if #text > 0 and #text <= 125 then
				RunConsoleCommand("ulx", "psay", ply:Nick(), text)
			end
		end, nil, "Send")
	end):SetImage("icon16/comment.png")

	options:AddOption("Open Steam Profile", function()
		if not IsValid(ply) then return end

		ply:ShowProfile()
		gmcore.chatprint("Profile opened in steam overlay.")
		surface.PlaySound("buttons/button9.wav")
	end):SetImage("icon16/world.png")

	options:AddOption("Open Forum Profile", function()
		if not IsValid(ply) then return end

		local fprofile = ply:GetNWInt("forumId", nil)
		if fprofile ~= 0 then
			gmcore.chatprint("Forum Profile opened in steam overlay.")
			surface.PlaySound("buttons/button9.wav")
			gui.OpenURL(GetGlobalString("gmcore.ForumsBaseUrl", "") .. "/members/" .. fprofile)
		else
			gmcore.chatprint("This player doesn't have a forum account!")
			surface.PlaySound("buttons/button10.wav")
		end
	end):SetImage("icon16/application_form_magnify.png")

	options:AddSpacer()

	if IsValid(ply) and LocalPlayer():HasStaffPerms() then
		local adminop, subimg = options:AddSubMenu("Staff")
		subimg:SetImage("icon16/lorry.png")

		adminop:AddOption("Slay Next Round", function()
			if not IsValid(ply) then return end

			Derma_StringRequest("Reason", "Please type the reason why you want to slay " .. ply:Nick(), "", function(txt)
				if IsValid(ply) then
					RunConsoleCommand("ulx", "slaynr", ply:Nick(), 1, txt)
				end
			end)
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/lightning_go.png")

		adminop:AddOption("Slay Now", function()
			if not IsValid(ply) then return end

			Derma_Query("Confirm that you want to slay " .. ply:Nick(), "Confirm Slay", "Yes", function() -- Since we are close to Slay Next Round, add a confirmation
				RunConsoleCommand("ulx", "slay", ply:Nick())
			end, "No", function() end)
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/lightning.png")

		adminop:AddOption("Kick", function()
			if not IsValid(ply) then return end

			Derma_StringRequest("Reason", "Please type the reason why you want to kick " .. ply:Nick(), "", function(txt)
				if IsValid(ply) then
					RunConsoleCommand("ulx", "kick", ply:Nick(), txt)
				end
			end)
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/door_out.png")

		adminop:AddOption("Ban", function()
			if not IsValid(ply) then return end

			xgui.ShowBanWindow(ply, ply:SteamID(), false, false) -- #3: Freeze player false; #4: IsUpdate false
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/delete.png")

		adminop:AddOption("Spectate", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "spectate", ply:Nick())
		end):SetImage("icon16/eye.png")

		adminop:AddSpacer()
		local gag, proxy = adminop:AddSubMenu("Gag")
		proxy:SetImage("icon16/asterisk_yellow.png")

		gag:AddOption("Gag", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "gag", ply:Nick())
		end):SetImage("icon16/accept.png")

		gag:AddOption("UnGag", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "ungag", ply:Nick())
		end):SetImage("icon16/cross.png")

		local gag, proxy = adminop:AddSubMenu("Mute")
		proxy:SetImage("icon16/asterisk_orange.png")

		gag:AddOption("Mute", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "mute", ply:Nick())
		end):SetImage("icon16/accept.png")

		gag:AddOption("UnMute", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "unmute", ply:Nick())
		end):SetImage("icon16/cross.png")

		adminop:AddSpacer()

		adminop:AddOption("View History Logs", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "hlogs", ply:Nick())
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/application_view_list.png")

		adminop:AddOption("Check Friends", function()
			if not IsValid(ply) then return end

			RunConsoleCommand("ulx", "friends", ply:Nick())
			surface.PlaySound("buttons/button9.wav")
		end):SetImage("icon16/group.png")

		adminop:AddSpacer()
	end

	options:Open()
end

function PANEL:ShowMicVolumeSlider()
	local width = 300
	local height = 50
	local padding = 10

	local sliderHeight = 16
	local sliderDisplayHeight = 8

	local x = math.max(gui.MouseX() - width, 0)
	local y = math.min(gui.MouseY(), ScrH() - height)

	local currentPlayerVolume = self:GetPlayer():GetVoiceVolumeScale()
	currentPlayerVolume = currentPlayerVolume != nil and currentPlayerVolume or 1

	-- Frame for the slider
	self.VolumeFrame = vgui.Create("DFrame")
	self.VolumeFrame:SetPos(x, y)
	self.VolumeFrame:SetSize(width, height)
	self.VolumeFrame:MakePopup()
	self.VolumeFrame:SetTitle("")
	self.VolumeFrame:ShowCloseButton(false)
	self.VolumeFrame:SetDraggable(false)
	self.VolumeFrame:SetSizable(false)
	self.VolumeFrame.Paint = function(self, w, h)
			draw.RoundedBox(5, 0, 0, w, h, Color(24, 25, 28, 255))
	end
	self.VolumeFrame.Think = function(s)
		if !sboard_panel:IsVisible() then
			-- If scoreboard has been untabbed (no longer visible) then no need to draw this menu anymore
			s:Remove()
		end
	end

	-- Automatically close after 10 seconds (something may have gone wrong)
	timer.Simple(10, function() if IsValid(self.VolumeFrame) then self.VolumeFrame:Close() end end)

	-- "Player volume"
	local label = vgui.Create("DLabel", self.VolumeFrame)
	label:SetPos(padding, padding)
	label:SetFont("cool_small")
	label:SetSize(width - padding * 2, 20)
	label:SetColor(Color(255, 255, 255, 255))
	label:SetText("Player Volume")

	-- Slider
	local slider = vgui.Create("DSlider", self.VolumeFrame)
	slider:SetHeight(sliderHeight)
	slider:Dock(TOP)
	slider:DockMargin(padding, 0, padding, 0)
	slider:SetSlideX(currentPlayerVolume)
	slider:SetLockY(0.5)
	slider.TranslateValues = function(slider, x, y)
			if IsValid(self:GetPlayer()) then self:GetPlayer():SetVoiceVolumeScale(x) end
			return x, y
	end

	-- Close the slider panel once the player has selected a volume
	slider.OnMouseReleased = function(panel, mcode) self.VolumeFrame:Close() end
	slider.Knob.OnMouseReleased = function(panel, mcode) self.VolumeFrame:Close() end

	-- Slider rendering
	-- Render slider bar
	slider.Paint = function(self, w, h)
			local iVolumePercent = slider:GetSlideX()

			-- Filled in box
			draw.RoundedBox(5, 0, sliderDisplayHeight / 2, w * iVolumePercent, sliderDisplayHeight, Color(200, 46, 46, 255))

			-- Grey box
			draw.RoundedBox(5, w * iVolumePercent, sliderDisplayHeight / 2, w * (1 - iVolumePercent), sliderDisplayHeight, Color(79, 84, 92, 255))
	end

	-- Render slider "knob" & text
	slider.Knob.Paint = function(self, w, h)
			if slider:IsEditing() then
				local sTextVal = math.Round(slider:GetSlideX() * 100) .. "%"
				local iTextPadding = 5

				-- The position of the text and size of rounded box are not relative to the text size. May cause problems if font size changes
				draw.RoundedBox(
						5, -- Radius
						-sliderHeight * 0.5 - iTextPadding, -- X
						-25, -- Y
						sliderHeight * 2 + iTextPadding * 2, -- Width
						sliderHeight + iTextPadding * 2, -- Height
						Color(52, 54, 57, 255)
				)
				draw.DrawText(sTextVal, "cool_small", sliderHeight / 2, -20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
			end

			draw.RoundedBox(100, 0, 0, sliderHeight, sliderHeight, Color(255, 255, 255, 255))
	end
end

vgui.Register("TTTScorePlayerRow", PANEL, "DButton")
