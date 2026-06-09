if SERVER then
	Damagelog:EventHook("glTraitorWarningSent")
else
	Damagelog:AddFilter("filter_show_traitor_warnings", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_traitor_warnings", Color(200, 20, 20))
end

local event = {}
event.Type = "WARN"

function event:glTraitorWarningSent(ply, typ, ent, title)
	local name = ent:GetClass()

	if name == "ttt_traitor_button" then
		name = ent:GetDescription()
	end

	self.CallEvent({
		[1] = ply:GetDamagelogID(),
		[2] = typ,
		[3] = name,
		[4] = title,
	})
end

function event:ToString(v, roles)
	local ply = Damagelog:InfoFromID(roles, v[1])
	local typ = v[2]
	local desc = v[3]
	local title = v[4]

	if typ == "trap" then
		return string.format(TTTLogTranslate(GetDMGLogLang, "TrapWarning"), ply.nick, desc)
	elseif typ == "nade" or typ == "jihad" then
		return string.format(TTTLogTranslate(GetDMGLogLang, "OtherWarning"), ply.nick, title)
	end
end

function event:IsAllowed(tbl)
	return Damagelog:IsFilterEnabled("filter_show_traitor_warnings")
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[2]) then
		return true
	end

	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_traitor_warnings")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)})
end

Damagelog:AddEvent(event)