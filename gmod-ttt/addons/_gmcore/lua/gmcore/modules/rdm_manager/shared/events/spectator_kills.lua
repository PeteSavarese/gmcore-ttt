local event = {}
if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
end

event.Type = "SKILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	local att = dmginfo:GetAttacker()
	local spec = att:GetNWEntity("spec_owner", nil)
	if(not IsValid(spec)) then
		if(IsValid(att.spec_owner) and att.spec_time and att.spec_time > os.time() - 5) then
			spec = att.spec_owner
		end
	end
	if not (ply.IsGhost and ply:IsGhost()) and ply:IsPlayer() and (IsValid(att) and not att:IsPlayer()) and spec:IsPlayer() then
		Damagelog.SceneID = Damagelog.SceneID + 1
		local scene = Damagelog.SceneID
		local tbl = {
			[1] = ply:Nick(),
			[2] = ply:GetRole(),
			[3] = spec:Nick(),
			[4] = "Spectator",
			[5] = att:GetModel(),
			[6] = ply:SteamID(),
			[7] = spec:SteamID(),
			[8] = scene
		}
		if scene then
			timer.Simple(0.6, function()
				Damagelog.Death_Scenes[scene] = table.Copy(Damagelog.Records)

				-- Begin extra stuff for offline deathscenes
				Damagelog.Death_Scenes[scene].ExtraInfo = {}
				Damagelog.Death_Scenes[scene].ExtraInfo.Map = game.GetMap()
				Damagelog.Death_Scenes[scene].ExtraInfo.Round = Damagelog.CurrentRound
				Damagelog.Death_Scenes[scene].ExtraInfo.Time = Damagelog.Time
			end)
		end
		self.CallEvent(tbl)
		if GetRoundState() == ROUND_ACTIVE and !gmcore.FunRounds.ActiveRound then
			net.Start("DL_Ded")
			net.WriteUInt(1,1)
			net.WriteString(tbl[3])
			net.Send(ply)
			ply:SetNWEntity("DL_Killer", spec)

			local penalty = KARMA.GetKillPenalty(ply:GetLiveKarma()) * 1.5
			KARMA.GivePenalty(spec, penalty, ply) -- apply karma here for conveniance.
		end
	end
end

function event:ToString(tbl)
	local str = string.format("%s [SPECTATOR] has killed %s [%s] with %s", tbl[3], tbl[1], Damagelog:StrRole(tbl[2]), tbl[5])

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
	line:ShowCopy(true, {tbl[1], tbl[7]}, {tbl[3], tbl[6]})
	line:ShowDamageInfos(tbl[3], tbl[1])

	if tbl[8] then
		line:ShowDeathScene(tbl[3], tbl[1], tbl[8])
	end
end

Damagelog:AddEvent(event)
