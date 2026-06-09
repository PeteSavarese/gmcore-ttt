if SERVER then
	Damagelog:EventHook("TTTHealthStationDamaged")
else
	Damagelog:AddFilter("Show health station damages", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Health Station Damage", Color(0, 255, 237))
end

local event = {}

event.Type = "HSDMG"
event.IsDamage = true

function event:TTTHealthStationDamaged(dmgInfo, eHealthStation)
	local attacker = dmgInfo:GetAttacker()

	if IsValid(attacker) and attacker:IsPlayer() then
	local damages = dmgInfo:GetDamage()

	local tbl = {
		[1] = attacker:Nick(),
		[2] = attacker:GetRole(),
		[3] = math.Round(damages),
		[4] = Damagelog:WeaponFromDmg(dmgInfo),
		[5] = attacker:SteamID(),
		[6] = eHealthStation:GetPlacer():Nick(),
		[7] = eHealthStation:GetPlacer():SteamID(),
	}

	if tbl[2] ~= ROLE_DETECTIVE then
		tbl.icon = {"icon16/exclamation.png"}
	end

	self.CallEvent(tbl)
	end
end

function event:ToString(tbl)
	local weapon = tbl[4]
	weapon = Damagelog:GetWeaponName(weapon)

	return string.format("%s [%s] has damaged %s's health station for %s dmg with %s", tbl[1], Damagelog:StrRole(tbl[2]), tbl[6], tbl[3], weapon)
end

function event:IsAllowed(tbl)
	return Damagelog:IsFilterEnabled("Show health station damages")
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Health Station Damage")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)

	line:ShowCopy(true, {tbl[1], tbl[4]})
end

Damagelog:AddEvent(event)