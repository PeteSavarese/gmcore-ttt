local event = {}

event.Type = "SDMG"
event.IsDamage = true

function event:EntityTakeDamage(ent, dmginfo)
	local att = dmginfo:GetAttacker()
	if not IsValid(att) then return end

	local spec = att:GetNWEntity("spec_owner", nil)
	if not IsValid(spec) then
		if IsValid(att.spec_owner) and att.spec_time and att.spec_time > os.time() - 5 then
			spec = att.spec_owner
		end
	end

	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and (IsValid(att) and not att:IsPlayer()) and spec:IsPlayer() then
		local damages = dmginfo:GetDamage()

		if math.floor(damages) > 0 then
			damages = damages / 4 -- prop damage seams to be 4x the damage recieved
			local tbl = {
				[1] = ent:Nick(),
				[2] = ent:GetRole(),
				[3] = spec:Nick(),
				[4] = "Spectator",
				[5] = math.Round(damages),
				[6] = att:GetModel(),
				[7] = ent:SteamID(),
				[8] = spec:SteamID()
			}
			self.CallEvent(tbl)
			if GetRoundState() == ROUND_ACTIVE and !gmcore.FunRounds.ActiveRound then
				local hurt_amount = math.min(ent:Health(), damages)
				local penalty = KARMA.GetHurtPenalty(ent:GetLiveKarma(), hurt_amount) * 1.5
				KARMA.GivePenalty(spec, penalty, ent) -- apply karma here for conveniance.
			end
		end
	end
end

function event:ToString(tbl)
	local str = string.format("%s [SPECTATOR] has damaged %s [%s] for %s HP with %s", tbl[3], tbl[1], Damagelog:StrRole(tbl[2]), tbl[5], tbl[6])

	return str
end

function event:IsAllowed(tbl)
	return Damagelog:IsFilterEnabled("Show damage")
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[3]) then
		return true
	end

	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Team Damage")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, {tbl[3], tbl[8]}, {tbl[1], tbl[7]})
	line:ShowDamageInfos(tbl[3], tbl[1])
end

Damagelog:AddEvent(event)
