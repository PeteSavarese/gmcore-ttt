--- Server hopper menu for browsing servers. Also detects server crashes (ping gap > 5secs) and will.
--- show menu without close button and auto-reconnect after 30secs.

---@type table[] Server entries returned from API.
local servers = {}

---@type integer Number of entries in `servers` after the last successful fetch.
local serverCount = 0

---@type integer UNIX timestamp of the most recent server-ping net message.
local lastServerPingResponse = 0

---@type boolean True while RDB debugger is attached; used to supress crash detection.
local debuggerActive = false

---@type Panel Open server-list frame. nil when no menu is visible.
local menuPanel = nil

---@type boolean True when the currently open menu was triggered by a crash event.
local menuPanelOpenedCrash = false

---@type number CurTime() at which a crash was detected and the menu was opened.
local menuOpened = 0

---@type number Last os.time() crash-detection Think ran.
local lastThink = 0

local CRASH_TEXT = "It looks like the server may have crashed. You will be reconnected automatically in %i seconds, or hop to another server below."

local FRAME_WIDTH = 620
local CARD_H = 90 -- must match CARD_HEIGHT in glservercard.lua
local CARD_M = 12 -- vertical margin below each server card
local CRASH_H = 108 -- estimated GLNoticeCard height for the wrapped crash text
local CRASH_M = 12 -- vertical gap below the crash notice
local HEADER_H = 56 -- GLFrame header height
local FRAME_PAD_T = 12 -- padding between the header and the first card
local FRAME_PAD_B = 12 -- padding at the bottom of the frame

--- Fetches the server list from the GMCore API and optionally runs a callback.
---@param postCallFunc fun()? Optional function invoked after the list is refreshed.
local function updateServers(postCallFunc)
	local base = (GetGlobalString("gmcore.ForumsBaseUrl", ""):gsub("/+$", ""))
	http.Fetch(base .. "/gl/servers/dumpjson", function(body)
		local parsed = util.JSONToTable(body)
		if not parsed then return end

		servers = parsed
		serverCount = #servers

		if postCallFunc and isfunction(postCallFunc) then
			postCallFunc()
		end
	end, function() end)
end

--- Opens the server-list menu. When `isCrash` is true a red warning notice with a
--- countdown timer is shown above the server cards.
---@param isCrash boolean? Pass true to show the crash-reconnect banner.
local function openServerMenu(isCrash)
	if IsValid(menuPanel) then return end

	menuPanelOpenedCrash = isCrash or false

	-- Frame dimensions
	-- Height = header + top-padding + (N cards with bottom margin) + bottom-padding
	-- If a crash notice is shown, add its estimated height plus its margin.
	local contentH = serverCount * (CARD_H + CARD_M)
	if isCrash then contentH = contentH + CRASH_H + CRASH_M end

	local frameH = HEADER_H + FRAME_PAD_T + contentH + FRAME_PAD_B

	menuPanel = vgui.Create("GmcoreFrame")
	menuPanel:SetTitle("Server List")
	menuPanel:SetSize(FRAME_WIDTH, frameH)
	menuPanel:Center()
	menuPanel:MakePopup()
	menuPanel:DockPadding(12, HEADER_H + FRAME_PAD_T, 12, FRAME_PAD_B)

	if isCrash then
		menuPanel:ShowCloseButton(false)
	end

	menuPanel.OnRemove = function()
		menuOpened = 0
		menuPanelOpenedCrash = false
		menuPanel = nil
	end

	-- Crash reconnect notice
	if isCrash then
		menuOpened = CurTime()

		local crashNotice = vgui.Create("GmcoreNoticeCard", menuPanel)
		crashNotice:Dock(TOP)
		crashNotice:DockMargin(0, 0, 0, CRASH_M)
		crashNotice:SetFadeOnOpen(false)
		crashNotice:SetFadeOnRemove(false)

		crashNotice.Paint = function(s, w, h)
			local pulse = (math.sin(CurTime() * 2.5) + 1) * 0.5
			local bgAlpha = math.floor(Lerp(pulse, 190, 240))

			draw.RoundedBox(10, 0, 0, w, h, Color(55, 10, 10, bgAlpha))

			-- Accent bar
			draw.RoundedBoxEx(10, 0, 0, 6, h, INPUT_FIELD_INVALID_COLOR, true, false, true, false)

			-- Border
			surface.SetDrawColor(INPUT_FIELD_INVALID_COLOR)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		crashNotice.infoIcon:SetSize(24, 24)
		crashNotice.infoIcon.Paint = function(s, w, h)
			surface.SetMaterial(s.Material)
			surface.SetDrawColor(INPUT_FIELD_INVALID_COLOR)
			surface.DrawTexturedRect(0, 0, w, h)
		end

		crashNotice.textLabel:SetTextColor(CARD_TITLE_TEXT_COLOR)

		crashNotice.PerformLayout = function(s, w, h)
			local pad = 18
			local iconSize = s.infoIcon:GetWide()
			s.infoIcon:SetPos(16, pad)
			s.textLabel:SetPos(16 + iconSize + 14, pad)
			s.textLabel:SetWide(w - 16 - iconSize - 14 - 16)
			s.textLabel:SizeToContentsY()

			local contentH = math.max(s.textLabel:GetTall(), iconSize)
			s:SetTall(contentH + pad * 2)
		end

		local baseThink = crashNotice.Think
		crashNotice.Think = function(s)
			if baseThink then baseThink(s) end
			if menuOpened <= 0 then return end

			local remaining = math.Clamp(math.floor(menuOpened + 30 - CurTime()), 0, 30)
			s:SetText(string.format(CRASH_TEXT, remaining))
		end

		crashNotice:SetText(string.format(CRASH_TEXT, 30))
	end

	for _, server in ipairs(servers) do
		local card = vgui.Create("GmcoreServerCard", menuPanel)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, CARD_M)
		card:SetServerData(server)
		card:SetOnConnect(function()
			if IsValid(menuPanel) then menuPanel:Remove() end

			LocalPlayer():ConCommand("connect " .. server.serverAddr)
		end)
	end
end

hook.Add("Think", "gmcore.ServerHopper.CheckServerStatus", function()
	if debuggerActive then return end
	if lastServerPingResponse <= 0 then return end
	if lastThink + 1 >= os.time() then return end

	if math.abs(lastServerPingResponse - os.time()) > 5 then
		lastThink = os.time()

		if not IsValid(menuPanel) then
			openServerMenu(true)
		end

		if menuOpened > 0 and math.floor(menuOpened + 30 - CurTime()) <= 0 then
			RunConsoleCommand("retry")
		end

		return
	end

	-- Server is back online; dismiss opened crash menu.
	if IsValid(menuPanel) and menuPanelOpenedCrash then
		if not IsValid(menuPanel) or menuPanel == nil then return end

		menuPanel:Remove()
	end

	lastThink = os.time()
end)

net.Receive("gmcore.ServerHopper.ServerPing", function()
	lastServerPingResponse = os.time()
end)

net.Receive("rdb.DebugStatus", function()
	debuggerActive = net.ReadBool()
	if debuggerActive then
		gmcore.print("[ServerHopper] Server debugging active - reconnect popup disabled")
	else
		gmcore.print("[ServerHopper] Server debugging inactive - reconnect popup enabled")
	end
end)

hook.Add("OnPlayerChat", "gmcore.ServerHopper.ChatCommand", function(ply, text, isteam, isdead)
	if ply ~= LocalPlayer() then return end

	local lower = string.lower(text)
	if lower == "!servers" or lower == "!hop" then
		updateServers(openServerMenu)

		return true
	end
end)

updateServers()
