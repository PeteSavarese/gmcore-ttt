CreateClientConVar("ttt_dmglogs_language", "english", FCVAR_ARCHIVE)
GetDMGLogLang = GetConVar("ttt_dmglogs_language"):GetString()

cvars.AddChangeCallback("ttt_dmglogs_language", function(convar_name, value_old, value_new)
	GetDMGLogLang = value_new

	net.Start("DL_SendLang")
	net.WriteString(value_new)
	net.SendToServer()
end)

include(Damagelog.ModulePath .. "shared/defines.lua")
include(Damagelog.ModulePath .. "config/config.lua")
include(Damagelog.ModulePath .. "shared/lang.lua")
include(Damagelog.ModulePath .. "shared/von.lua")
include(Damagelog.ModulePath .. "client/settings.lua")
include(Damagelog.ModulePath .. "shared/sync.lua")
include(Damagelog.ModulePath .. "client/drawcircle.lua")
include(Damagelog.ModulePath .. "client/tabs/damagetab.lua")
include(Damagelog.ModulePath .. "client/tabs/shoots.lua")
include(Damagelog.ModulePath .. "client/tabs/chat_logs.lua")
include(Damagelog.ModulePath .. "client/tabs/old_logs.lua")
include(Damagelog.ModulePath .. "client/weapon_names.lua")
include(Damagelog.ModulePath .. "client/colors.lua")
include(Damagelog.ModulePath .. "client/recording.lua")
include(Damagelog.ModulePath .. "client/listview.lua")
include(Damagelog.ModulePath .. "client/filters.lua")
include(Damagelog.ModulePath .. "shared/events.lua")
include(Damagelog.ModulePath .. "shared/notify.lua")
include(Damagelog.ModulePath .. "client/info_label.lua")
include(Damagelog.ModulePath .. "shared/privileges.lua")

if Damagelog.RDM_Manager_Enabled then
	include(Damagelog.ModulePath .. "shared/rdm_manager.lua")
	include(Damagelog.ModulePath .. "shared/chat.lua")
	include(Damagelog.ModulePath .. "client/tabs/rdm_manager.lua")
	include(Damagelog.ModulePath .. "client/rdm_manager.lua")
	include(Damagelog.ModulePath .. "client/chat.lua")
end

local color_lightyellow = Color(255, 245, 148)
local color_red = Color(255, 62, 62)
local color_lightblue = Color(98, 176, 255)
local outdated = false

hook.Add("InitPostEntity", "Damagelog_InitPostHTTP", function()
	print("Damagelog: Sending language to server" .. GetDMGLogLang)

	net.Start("DL_SendLang")
	net.WriteString(GetDMGLogLang)
	net.SendToServer()
end)

---Opens the Damagelog/RDM Manager menu window.
function Damagelog:OpenMenu()
	local x, y = 765, 680
	local show_outdated = outdated and GetConVar("ttt_dmglogs_updatenotifications"):GetBool()

	if show_outdated then
		y = y + 30
	end

	self.Menu = vgui.Create("DFrame")
	self.Menu:SetSize(x, y)
	self.Menu:SetTitle("TTT Damagelogs")
	self.Menu:SetDraggable(true)
	self.Menu:MakePopup()
	self.Menu:SetKeyboardInputEnabled(false)
	self.Menu:Center()
	self.Menu.AboutPos = 0
	self.Menu.AboutPosMax = 35
	self.Menu.AboutState = false

	self.Menu.About = function(self)
		self.AboutState = not self.AboutState
	end

	local old_think = self.Menu.Think

	self.Menu.Think = function(self)
		self.AboutMoving = true

		if self.AboutState and self.AboutPos < self.AboutPosMax then
			self.AboutPos = self.AboutPos + 15
		elseif not self.AboutState and self.AboutPos > 0 then
			self.AboutPos = self.AboutPos - 15
		else
			self.AboutMoving = false
		end

		if old_think then
			old_think(self)
		end
	end

	self.Menu.PaintOver = function(self, w, h)
		local _x, _y, _w, _h = x - 200, show_outdated and 80 or 50, 195, self.AboutPos
		surface.SetDrawColor(color_black)
		surface.DrawRect(_x, _y, _w, _h)
		surface.SetDrawColor(color_lightyellow)
		surface.DrawRect(_x + 1, _y + 1, _w - 2, _h - 2)

		if self.AboutPos >= 35 then
			surface.SetFont("DermaDefault")
			surface.SetTextColor(color_black)
			surface.SetTextPos(_x + 5, _y + 5)
			surface.DrawText("Created by Tommy228.")
			surface.SetTextPos(_x + 5, _y + 25)
			surface.DrawText("Licensed under GPL-3.0.")
		end
	end

	if show_outdated then
		local info = vgui.Create("Damagelog_InfoLabel", self.Menu)
		info:SetText(TTTLogTranslate(GetDMGLogLang, "UpdateNotify"))
		info:SetInfoColor("blue")
		info:SetPos(5, 30)
		info:SetSize(x - 10, 25)
	end

	self.Tabs = vgui.Create("DPropertySheet", self.Menu)
	self.Tabs:SetPos(5, show_outdated and 60 or 30)
	self.Tabs:SetSize(x - 10, show_outdated and y - 65 or y - 35)
	self:DrawDamageTab(x, y)
	self:DrawShootsTab(x, y)
	self:DrawChatLogs()

	if Damagelog.RDM_Manager_Enabled then
		self:DrawRDMManager(x, y)
	end

	self:DrawOldLogs(x, y)

	self.About = vgui.Create("DButton", self.Menu)
	self.About:SetPos(x - 60, show_outdated and 57 or 27)
	self.About:SetSize(55, 19)
	self.About:SetText("▼" .. TTTLogTranslate(GetDMGLogLang, "About"))

	if not Damagelog.HideDonateButton then
		self.Donate = vgui.Create("DButton", self.Menu)
		self.Donate:SetPos(x - 120, show_outdated and 57 or 27)
		self.Donate:SetSize(55, 19)
		self.Donate:SetText(TTTLogTranslate(GetDMGLogLang, "Donate"))

		self.Donate.DoClick = function()
			gui.OpenURL("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=YSJDH4CJ4N3BQ")
		end
	end

	self.About.DoClick = function()
		self.Menu:About()
		self.About:SetText(self.Menu.AboutState and "▲" .. TTTLogTranslate(GetDMGLogLang, "About") or "▼" .. TTTLogTranslate(GetDMGLogLang, "About"))
	end
end

concommand.Add("damagelog", function()
	Damagelog:OpenMenu()
end)

Damagelog.pressed_key = false

---Think hook handler. Checks for key presses to open damagelog.
function Damagelog:Think()
	if input.IsKeyDown(self.Key) and not self.pressed_key then
		self.pressed_key = true

		if not IsValid(self.Menu) then
			self:OpenMenu()
		else
			if self:IsRecording() then
				self:StopRecording()
				self.Menu:SetVisible(true)
			else
				self.Menu:Close()
			end
		end
	elseif self.pressed_key and not input.IsKeyDown(self.Key) then
		self.pressed_key = false
	end
end

hook.Add("Think", "Think_Damagelog", function()
	Damagelog:Think()
end)

---@param role number TTT role constant or DAMAGELOG_ROLE_* constant
---@return string roleName
function Damagelog:StrRole(role)
	if role == DAMAGELOG_ROLE_DISCONNECTED then
		return TTTLogTranslate(GetDMGLogLang, "disconnected")
	else
		if TTT2 then
			return TTTLogTranslate(GetDMGLogLang, GetRoleByIndex(role).name)
		elseif CR_VERSION then
			return TTTLogTranslate(GetDMGLogLang, ROLE_STRINGS[role])
		else
			if role == ROLE_TRAITOR then
				return TTTLogTranslate(GetDMGLogLang, "traitor")
			elseif role == ROLE_DETECTIVE then
				return TTTLogTranslate(GetDMGLogLang, "detective")
			else
				return TTTLogTranslate(GetDMGLogLang, "innocent")
			end
		end
	end
end

net.Receive("DL_InformSuperAdmins", function()
	local nick = net.ReadString()

	if nick then
		chat.AddText(color_red, nick, color_white, " " .. TTTLogTranslate(GetDMGLogLang, "AbuseNote"))
	end
end)

net.Receive("DL_Ded", function()
	if Damagelog.RDM_Manager_Enabled and GetConVar("ttt_dmglogs_rdmpopups"):GetBool() and net.ReadUInt(1, 1) == 1 and !gmcore.FunRounds.ActiveRound then
		local client = LocalPlayer()

		if client.IsGhost and client:IsGhost() then
			return
		end

		local death_reason = net.ReadString()

		if not death_reason then
			return
		end

		local frame = vgui.Create("DFrame")
		frame:SetSize(250, 120)
		frame:SetTitle(TTTLogTranslate(GetDMGLogLang, "PopupNote"))
		frame:ShowCloseButton(false)
		frame:Center()
		local reason = vgui.Create("DLabel", frame)
		reason:SetText(string.format(TTTLogTranslate(GetDMGLogLang, "KilledBy"), death_reason))
		reason:SizeToContents()
		reason:SetPos(5, 32)
		local report = vgui.Create("DButton", frame)
		report:SetPos(5, 55)
		report:SetSize(240, 25)
		report:SetText(TTTLogTranslate(GetDMGLogLang, "OpenMenu"))

		report.DoClick = function()
			net.Start("DL_StartReport")
			net.SendToServer()
			frame:Close()
		end

		local report_icon = vgui.Create("DImageButton", report)
		report_icon:SetMaterial("materials/icon16/report_go.png")
		report_icon:SetPos(1, 5)
		report_icon:SizeToContents()
		local close = vgui.Create("DButton", frame)
		close:SetPos(5, 85)
		close:SetSize(240, 25)
		close:SetText(TTTLogTranslate(GetDMGLogLang, "WasntRDM"))

		close.DoClick = function()
			frame:Close()
		end

		local close_icon = vgui.Create("DImageButton", close)
		close_icon:SetPos(2, 5)
		close_icon:SetMaterial("materials/icon16/cross.png")
		close_icon:SizeToContents()
		frame:MakePopup()
		chat.AddText(color_red, "[RDM Manager] ", COLOR_WHITE, TTTLogTranslate(GetDMGLogLang, "OpenReportMenu"), color_lightblue, " ", Damagelog.RDM_Manager_Command, COLOR_WHITE, " ", TTTLogTranslate(GetDMGLogLang, "Command"), ".")
	end
end)

hook.Add("StartChat", "Damagelog_StartChat", function()
	if IsValid(Damagelog.Menu) then
		Damagelog.Menu:SetPos(ScrW() - Damagelog.Menu:GetWide(), ScrH() / 2 - Damagelog.Menu:GetTall() / 2)
	end

	if IsValid(Damagelog.OldLogsShoots) then
		-- Position shot logs to the left of the main RDM manager window
		local mainMenuX = ScrW() - (IsValid(Damagelog.Menu) and Damagelog.Menu:GetWide() or 800)
		Damagelog.OldLogsShoots:SetPos(mainMenuX - Damagelog.OldLogsShoots:GetWide() - 10, ScrH() / 2 - Damagelog.OldLogsShoots:GetTall() / 2)
	end
end)

hook.Add("FinishChat", "Damagelog_FinishChat", function()
	if IsValid(Damagelog.Menu) then
		Damagelog.Menu:Center()
	end

	if IsValid(Damagelog.OldLogsShoots) then
		Damagelog.OldLogsShoots:SetPos(ScrW() / 2 - Damagelog.Menu:GetWide() / 2 - Damagelog.OldLogsShoots:GetWide() - 10, ScrH() / 2 - Damagelog.OldLogsShoots:GetTall() / 2)
	end
end)
