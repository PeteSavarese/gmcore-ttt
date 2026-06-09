local ROUND_SELECT_TARGET_HEIGHT = 260
local ROUND_SELECT_ANIM_TIME   = 0.25

local monthnames = {
	TTTLogTranslate(GetDMGLogLang, "January"),
	TTTLogTranslate(GetDMGLogLang, "February"),
	TTTLogTranslate(GetDMGLogLang, "March"),
	TTTLogTranslate(GetDMGLogLang, "April"),
	TTTLogTranslate(GetDMGLogLang, "May"),
	TTTLogTranslate(GetDMGLogLang, "June"),
	TTTLogTranslate(GetDMGLogLang, "July"),
	TTTLogTranslate(GetDMGLogLang, "August"),
	TTTLogTranslate(GetDMGLogLang, "September"),
	TTTLogTranslate(GetDMGLogLang, "October"),
	TTTLogTranslate(GetDMGLogLang, "November"),
	TTTLogTranslate(GetDMGLogLang, "December")
}

local loading = {}
local ShotsOpen = false

local function LoadLogs(node)
	if node.received or node.receiving then return end
	node.receiving = true

	local id = table.insert(loading, node)

	net.Start("DL_AskOldLogRounds")
		net.WriteUInt(id, 32)
		net.WriteUInt(node.year, 32)
		net.WriteUInt(node.month, 32)
		net.WriteUInt(node.day, 32)
	net.SendToServer()
end

local function isLeapYear(year)
	return (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0))
end

local function getNumberOfDays(year, month)
	if month == 2 then
		local real_year = 2000 + year
		return isLeapYear(real_year) and 29 or 28
	end

	if month == 4 or month == 6 or month == 9 or month == 11 then
		return 30
	end

	return 31
end

local function addDayNodes(node_month, year, month)
	local number_of_days = getNumberOfDays(year, month)

	for d = 1, number_of_days do
		if Damagelog.OldLogsDays[year][month][d] then
			local day = node_month:AddNode(tostring(d))
			day.year  = node_month.year
			day.month = node_month.month
			day.day   = d
			day:SetForceShowExpander(true)

			local old = day.SetExpanded

			day.SetExpanded = function(pnl, expand, anim)
				if expand then LoadLogs(day) end

				return old(pnl, expand, anim)
			end
		end
	end
end

net.Receive("DL_SendOldLogRounds", function()
	local id   = net.ReadUInt(32)
	local list = net.ReadTable()
	local node = loading[id]
	if not node then return end

	if #list <= 0 then
		node:Remove()
		return
	end

	local byHour = {}

	for _, v in pairs(list) do
		local _time = string.Explode(",", os.date("%H,%M", v.date))
		v.min = tonumber(_time[2])
		local hour = tonumber(_time[1])
		byHour[hour] = byHour[hour] or {}
		table.insert(byHour[hour], v)
	end

	local all_rounds = {}

	for i = 0, 24 do
		local hourTbl = byHour[i]
		if hourTbl then
			local hn = node:AddNode(string.format("%02dh", i))
			table.SortByMember(hourTbl, "date")
			hn.rounds = hourTbl
			hn.hour   = i

			for _, r in ipairs(hourTbl) do table.insert(all_rounds, r) end
		end
	end

	table.SortByMember(all_rounds, "date")

	node.all_rounds  = all_rounds
	node.received    = true
	node.receiving   = false
	node:SetExpanded(true)
end)

function Damagelog:DrawOldLogs()
	self.CurSelectedRound = nil

	local root = vgui.Create("DPanel")
	root:Dock(FILL)
	root:DockMargin(6,6,6,6)

	local toggleBtn = vgui.Create("DButton", root)
	toggleBtn:Dock(TOP)
	toggleBtn:SetTall(34)
	toggleBtn:DockMargin(0,0,0,6)
	toggleBtn:SetText(TTTLogTranslate(GetDMGLogLang, "SelectRoundToLoad"))

	local datePanel = vgui.Create("DPanel", root)
	datePanel:Dock(TOP)
	datePanel:SetTall(0)
	datePanel:SetVisible(false)
	datePanel:DockMargin(0,0,0,6)

	local leftCol = vgui.Create("DPanel", datePanel)
	leftCol:Dock(LEFT)
	leftCol:SetWide(260)
	leftCol:DockMargin(6,6,3,6)

	local leftLabel = vgui.Create("DLabel", leftCol)
	leftLabel:SetText(TTTLogTranslate(GetDMGLogLang, "SelectDate"))
	leftLabel:Dock(TOP)
	leftLabel:DockMargin(2,2,2,4)
	leftLabel:SetFont("DermaDefaultBold")

	local dateTree = vgui.Create("DTree", leftCol)
	dateTree:Dock(FILL)
	dateTree:DockMargin(2,0,2,2)

	local rightCol = vgui.Create("DPanel", datePanel)
	rightCol:Dock(FILL)
	rightCol:DockMargin(3,6,6,6)

	local centerLabel = vgui.Create("DLabel", rightCol)
	centerLabel:SetText(TTTLogTranslate(GetDMGLogLang, "SelectRound"))
	centerLabel:Dock(TOP)
	centerLabel:DockMargin(2,2,2,4)
	centerLabel:SetFont("DermaDefaultBold")

	local rounds = vgui.Create("DListView", rightCol)
	rounds:Dock(FILL)
	rounds:DockMargin(2,0,2,2)
	rounds:SetMultiSelect(false)
	rounds:AddColumn(TTTLogTranslate(GetDMGLogLang,"Time")):SetFixedWidth(150)
	rounds:AddColumn(TTTLogTranslate(GetDMGLogLang,"Map")):SetFixedWidth(150)
	rounds:AddColumn(TTTLogTranslate(GetDMGLogLang,"Round"))

	local main = vgui.Create("DPanel", root)
	main:Dock(FILL)

	local playersForm = vgui.Create("DForm", main)
	playersForm:Dock(TOP)
	playersForm:DockMargin(0,0,0,6)
	playersForm:SetLabel(TTTLogTranslate(GetDMGLogLang, "PlayerInformation"))
	playersForm:SetExpanded(false)

	local players = vgui.Create("DListView")
	players:SetTall(240)
	players:AddColumn(TTTLogTranslate(GetDMGLogLang,"Player")):SetFixedWidth(150)
	players:AddColumn("SteamID"):SetFixedWidth(130)
	players:AddColumn(TTTLogTranslate(GetDMGLogLang,"Role"))
	playersForm:AddItem(players)

	local damageCard = vgui.Create("DPanel", main)
	damageCard:Dock(FILL)

	local bottomLabel = vgui.Create("DLabel", damageCard)
	bottomLabel:SetText(TTTLogTranslate(GetDMGLogLang,"DmgInfo"))
	bottomLabel:Dock(TOP)
	bottomLabel:DockMargin(8,8,8,4)
	bottomLabel:SetFont("DermaDefaultBold")

	local dmgList = vgui.Create("DListView", damageCard)
	dmgList:Dock(FILL)
	dmgList:DockMargin(8,0,8,8)
	dmgList:AddColumn(TTTLogTranslate(GetDMGLogLang, "Time")):SetFixedWidth(50)
	dmgList:AddColumn(TTTLogTranslate(GetDMGLogLang, "Type")):SetFixedWidth(50)
	dmgList:AddColumn(TTTLogTranslate(GetDMGLogLang, "Event"))
	dmgList:AddColumn(""):SetFixedWidth(28)

	local function recomputeFormHeights()
		if not IsValid(main) then return end

		local h = main:GetTall()
		local target = math.Clamp(math.floor(h * 0.34), 180, 360)
		players:SetTall(target - 28)

		if playersForm:GetExpanded() then playersForm:SetTall(target) end

		main:InvalidateLayout(true)
	end

	main.OnSizeChanged = recomputeFormHeights
	timer.Simple(0, recomputeFormHeights)

	self.OldLogs      = root
	self.DateChoice   = dateTree
	self.RoundChoice  = rounds
	self.OldDamagelog = dmgList
	self.PlayerList   = players

	local chooserOpen  = false
	local selectedUnix = nil

	rounds.OnRowSelected = function(_, _, line)
		selectedUnix = line._time
	end

	local function animateOpen()
		datePanel:SetVisible(true)
		datePanel:SetTall(0)
		datePanel:InvalidateLayout(true)
		datePanel:SizeTo(datePanel:GetWide(), ROUND_SELECT_TARGET_HEIGHT, ROUND_SELECT_ANIM_TIME, 0)

		chooserOpen = true
	end

	local function animateClose()
		datePanel:SizeTo(datePanel:GetWide(), 0, ROUND_SELECT_ANIM_TIME, 0)

		timer.Simple(ROUND_SELECT_ANIM_TIME + 0.02, function()
			if IsValid(datePanel) then datePanel:SetVisible(false) end
		end)

		chooserOpen = false
	end

	toggleBtn.DoClick = function()
		if not chooserOpen then
			animateOpen()
			return
		end

		if not selectedUnix then
			GMCore_MessageDialog(TTTLogTranslate(GetDMGLogLang, "PleaseSelectRound"), TTTLogTranslate(GetDMGLogLang, "Error"), "Ok")
			return
		end

		net.Start("DL_AskOldLog")
			net.WriteUInt(selectedUnix, 32)
			net.WriteBool(false)
		net.SendToServer()

		animateClose()
	end

	dateTree.OnNodeSelected = function(_, node)
		if node.hour and node.rounds then
			rounds:Clear()
			selectedUnix = nil

			local seen = {}

			for _, v in ipairs(node.rounds) do
				if not seen[v.date] then
					local t = os.date("%H:%M", v.date)
					if string.sub(t,1,1) == "0" then t = string.sub(t,2) end
					local line = rounds:AddLine(t, v.map, tostring(v.round))
					line._time = v.date
					seen[v.date] = true
				end
			end

			return
		end

		if node.day then
			if not node.received then
				LoadLogs(node)
				node:SetExpanded(true)

				return
			end

			if node.all_rounds then
				rounds:Clear()
				selectedUnix = nil

				local seen = {}
				for _, v in ipairs(node.all_rounds) do
					if not seen[v.date] then
						local t = os.date("%H:%M", v.date)
						if string.sub(t,1,1) == "0" then t = string.sub(t,2) end
						local line = rounds:AddLine(t, v.map, tostring(v.round))
						line._time = v.date
						seen[v.date] = true
					end
				end

				return
			end
		end

		if node.year and not node.day then
			node:SetExpanded(not node.m_bExpanded)
		end
	end

	self.OldLogs.UpdateDates = function()
		if not IsValid(dateTree) then return end

		dateTree:Clear()
		if not Damagelog.OlderDate or not Damagelog.LatestDate or not Damagelog.OldLogsDays then return end

		local older  = string.Explode(",", os.date("%y,%m,%d,%H,%M", Damagelog.OlderDate))
		local latest = string.Explode(",", os.date("%y,%m,%d,%H,%M", Damagelog.LatestDate))

		for _, v in pairs({older, latest}) do
			for k, data in pairs(v) do v[k] = tonumber(data) end
		end

		local years = latest[1] - older[1]
		for y = 0, years do
			local yy = latest[1] - y
			if Damagelog.OldLogsDays[yy] then
				local yearNode = dateTree:AddNode("20" .. tostring(yy))
				yearNode.year = yy

				local start_m, end_m
				if years == 0 then
					start_m = older[2]; end_m = latest[2]
				elseif yy == latest[1] then
					start_m = 1; end_m = latest[2]
				elseif yy == older[1] then
					start_m = older[2]; end_m = 12
				else
					start_m = 1; end_m = 12
				end

				for m = start_m, end_m do
					if Damagelog.OldLogsDays[yy][m] then
						local monthNode = yearNode:AddNode(monthnames[m])
						monthNode.year  = yy
						monthNode.month = m
						monthNode.received = false

						addDayNodes(monthNode, yy, m)
					end
				end
			end
		end
	end

	self.Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "OldLogs"), root, "icon16/calendar_view_week.png", false, false)
	net.Start("DL_AskLogsList")
	net.SendToServer()
end

net.Receive("DL_SendLogsList", function()
	if not IsValid(Damagelog.OldLogs) then return end
	Damagelog.OlderDate = net.ReadUInt(32)
	Damagelog.LatestDate = net.ReadUInt(32)

	local length = net.ReadUInt(32)
	Damagelog.OldLogsDays = util.JSONToTable(util.Decompress(net.ReadData(length)))
	Damagelog.OldLogs:UpdateDates()
end)

net.Receive("DL_SendOldLog", function()
	local exists = net.ReadUInt(1) == 1
	if not exists then return end

	local size = net.ReadUInt(32)
	local data = net.ReadData(size)

	if not data then return end
	data = util.Decompress(data)

	if not data then return end
	data = util.JSONToTable(data)
	if not data then return end

	if ShotsOpen and IsValid(Damagelog.OldLogsShoots) then
		Damagelog.OldLogsShoots:Close()
		Damagelog.OldLogsShoots:Remove()
	end

	ShotsOpen = true
	Damagelog.OldDamagelog:Clear()
	Damagelog.OldShootTables = data.ShootTable

	Damagelog:SetListViewTable(Damagelog.OldDamagelog, {
		logs  = data.DamageTable,
		roles = data.Roles
	}, false, true)

	local mx, my = Damagelog.Menu:GetPos()
	Damagelog.OldLogsShoots = vgui.Create("DFrame")
	Damagelog.OldLogsShoots:SetSize(300, Damagelog.Menu:GetTall())
	Damagelog.OldLogsShoots:SetPos(mx - Damagelog.OldLogsShoots:GetWide() - 10, my)
	Damagelog.OldLogsShoots:SetTitle(TTTLogTranslate(GetDMGLogLang, "ShotLogs"))
	Damagelog.OldLogsShoots:SetDraggable(true)
	Damagelog.OldLogsShoots:SetSizable(true)
	Damagelog.OldLogsShoots:SetKeyboardInputEnabled(false)
	Damagelog.OldLogsShoots.OnClose = function() ShotsOpen = false end
	Damagelog.OldLogsShoots.Think = function(fr)
		if not IsValid(Damagelog.Menu) then return end

		local x, y = Damagelog.Menu:GetPos()
		local mw, mh = Damagelog.Menu:GetSize()
		fr:SetSize(fr:GetWide(), mh)
		fr:SetPos(x - fr:GetWide() - 10, y)
	end

	Damagelog.OldShoot = vgui.Create("DListView", Damagelog.OldLogsShoots)
	Damagelog.OldShoot:Dock(FILL)
	Damagelog.OldShoot:AddColumn(TTTLogTranslate(GetDMGLogLang, "ShotEvent"))
	Damagelog.OldShoot.OnRowRightClick = function()
		local Menu = DermaMenu()
		Menu:Open()
		Menu:AddOption(TTTLogTranslate(GetDMGLogLang, "CopyLines"), function()
			local full_text, append = "", false
			for _, line in pairs(Damagelog.OldShoot:GetSelected()) do
				if append then full_text = full_text .. "\n" end
				full_text = full_text .. line:GetColumnText(1)
				append = true
			end
			SetClipboardText(full_text)
		end):SetImage("icon16/tab_edit.png")
	end

	if data.ShootTable then
		Damagelog:SetDamageInfosLV(Damagelog.OldShoot, data.Roles, nil, nil, nil, nil, data.ShootTable)
	end

	Damagelog.PlayerList:Clear()
	for _, v in pairs(data.Roles or {}) do
		local steamid = util.SteamIDFrom64(v.steamid64)

		local line = Damagelog.PlayerList:AddLine(v.nick or "?", steamid or "?", Damagelog:StrRole(v.role))
		line.steamid = steamid
		line.OnRightClick = function()
			local m = DermaMenu()
			m:AddOption(TTTLogTranslate(GetDMGLogLang, "CopySteamID"), function()
				SetClipboardText(line.steamid or "")
			end):SetImage("icon16/tab_edit.png")
			m:Open()
		end
	end

	if IsValid(Damagelog.Menu) then
		local oldClose = Damagelog.Menu.OnClose

		Damagelog.Menu.OnClose = function(...)
			if IsValid(Damagelog.OldLogsShoots) then
				Damagelog.OldLogsShoots:Close()
				Damagelog.OldLogsShoots:Remove()
			end

			if oldClose then return oldClose(...) end
		end
	end
end)

function Damagelog:FindFromOldLogs(t, att, victim)
	local results, found = {}, false

	for k, v in pairs(self.OldShootTables or {}) do
		if k >= t - 10 and k <= t then
			for _, i in pairs(v) do
				if i[1] == victim or i[1] == att then
					results[k] = results[k] or {}
					table.insert(results[k], i)
					found = true
				end
			end
		end
	end

	return found, results
end
