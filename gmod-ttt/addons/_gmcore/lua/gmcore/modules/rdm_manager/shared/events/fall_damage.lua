if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
else
	Damagelog:AddFilter("filter_show_falldamage", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_fall_damages", Color(0, 0, 0))
end

local event = {}
event.Type = "FD"

local EVENT_DETAILS = {
	VictimId = 1,
	DamageTaken = 2,
	WasVictimPushed = 3,
	AttackerId = 4
}

function event:EntityTakeDamage(ent, dmginfo)
	local att = dmginfo:GetAttacker()

	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and att:IsWorld() and dmginfo:GetDamageType() == DMG_FALL then
		local damages = dmginfo:GetDamage()

		if math.floor(damages) > 0 then
			local tbl = {
				[EVENT_DETAILS.VictimId]    = ent:GetDamagelogID(),
				[EVENT_DETAILS.DamageTaken]   = math.Round(damages),
				[EVENT_DETAILS.WasVictimPushed] = false
			}

			local playerThatPushed = ent:GetPlayerThatRecentlyPushedMe()

			if playerThatPushed ~= nil then
				tbl[EVENT_DETAILS.WasVictimPushed]  = true
				tbl[EVENT_DETAILS.AttackerId]     = playerThatPushed:GetDamagelogID()
			end

			self.CallEvent(tbl)
		end
	end
end

function event:ToString(tbl, roles)
	local ply = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.VictimId])
	local t = string.format(TTTLogTranslate(GetDMGLogLang, "FallDamage"), ply.nick, Damagelog:StrRole(ply.role), tbl[EVENT_DETAILS.DamageTaken])

	if tbl[EVENT_DETAILS.WasVictimPushed] then
		local att = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.AttackerId])
		t = t .. string.format(TTTLogTranslate(GetDMGLogLang, "AfterPush"), att.nick, Damagelog:StrRole(att.role))
	end

	return t
end

function event:IsAllowed(tbl)
	return Damagelog:IsFilterEnabled("filter_show_falldamage")
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[EVENT_DETAILS.VictimId])
end

function event:GetColor(tbl, roles)
	if tbl[EVENT_DETAILS.WasVictimPushed] then
		local ent = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.VictimId])
		local att = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.AttackerId])

		if att ~= nil and Damagelog:IsTeamkill(att.role, ent.role) then
			return Damagelog:GetColor("color_team_damages")
		end
	end

	return Damagelog:GetColor("color_fall_damages")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.VictimId])

	if tbl[EVENT_DETAILS.WasVictimPushed] then
		local att = Damagelog:InfoFromID(roles, tbl[EVENT_DETAILS.AttackerId])
		line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)}, {att.nick, util.SteamIDFrom64(att.steamid64)})
	else
		line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)})
	end
end

Damagelog:AddEvent(event)