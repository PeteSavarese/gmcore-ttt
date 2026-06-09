if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
end

local event = {}
event.Type = "DMG"
event.IsDamage = true

function event:EntityTakeDamage(victim, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not (victim.IsGhost and victim:IsGhost()) and victim:IsPlayer() and (IsValid(attacker) and attacker:GetClass() == "npc_manhack") and victim ~= attacker then
		-- Check if victim isn't ghost, valid ply, and the attacker is a manhack
		if gmcore.FunRounds.ActiveRound and gmcore.FunRounds.DLogs_disabled[gmcore.FunRounds.ChosenFunRound] then return end
		if not attacker.CurrentAttacker then -- There is no attacker to log. Maybe just a map-spawned manhack so ignore
			return
		end

		local plyAttacker = attacker.CurrentAttacker
		local damages = dmginfo:GetDamage()
		if plyAttacker == victim then return end
		if math.floor(damages) > 0 then
			local tbl = {
				[1] = victim:Nick(),
				[2] = victim:GetRole(),
				[3] = plyAttacker:Nick(),
				[4] = plyAttacker:GetRole(),
				[5] = math.Round(damages),
				[6] = "Manhack",
				[7] = victim:SteamID(),
				[8] = plyAttacker:SteamID()
			}

			if Damagelog:IsTeamkill(tbl[2], tbl[4]) then tbl.icon = {"icon16/exclamation.png"} end
			self.CallEvent(tbl)
		end
	end
end

function event:ToString(tbl)
	local weapon = tbl[6]
	local str

	if weapon then
		str = string.format("%s [%s] has damaged %s [%s] for %s HP with %s", tbl[3], Damagelog:StrRole(tbl[4]), tbl[1], Damagelog:StrRole(tbl[2]), tbl[5], weapon)
	else
		str = string.format("%s [%s] has damaged %s [%s] for %s HP with an unknown weapon", tbl[3], Damagelog:StrRole(tbl[4]), tbl[1], Damagelog:StrRole(tbl[2]), tbl[5])
	end

	return str
end

function event:IsAllowed(tbl)
	return Damagelog:IsFilterEnabled("filter_show_damages")
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[3]) then return true end

	return false
end

function event:GetColor(tbl)
	if Damagelog:IsTeamkill(tbl[2], tbl[4]) then return Damagelog:GetColor("color_team_damages") end

	return Damagelog:GetColor("color_damages")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, {tbl[3], tbl[8]}, {tbl[1], tbl[7]})
end

Damagelog:AddEvent(event)
