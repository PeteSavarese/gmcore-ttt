---@class DodgeballEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideRoles fun(self: DodgeballEvent): boolean
---@field PreventWepPickup fun(self: DodgeballEvent, ply: Player, wep: Weapon): boolean
---@field PlayerDeath fun(self: DodgeballEvent, victim: Player, wep: Weapon, attacker: Player)

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Dodgeball"] or {}
---@cast EVENT DodgeballEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)
	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("PlayerDeath", self.PlayerDeath)
end

function EVENT:OverrideRoles()
	for i, ply in pairs(self:GetPlayers()) do
		if (i % 2) == 0 then -- For every 2nd player set as a detective
			ply:SetRole(ROLE_DETECTIVE)
		else
			ply:SetRole(ROLE_TRAITOR)
		end
	end

	return true
end

function EVENT:PreventWepPickup(ply, wep)
	return wep:GetClass() == "gmcore_funround_dodgeball"
end

-- Death tracker, computed in ComputeRewards
function EVENT:PlayerDeath(victim, _, attacker)
	if !IsValid(attacker) then return end
	if !attacker:IsPlayer() then return end
	if victim == attacker then return end

	if !self.KillsThisRound[attacker:SteamID()] then -- If the player hasn't killed anyone yet
		self.KillsThisRound[attacker:SteamID()] = 0
	end

	self.KillsThisRound[attacker:SteamID()] = self.KillsThisRound[attacker:SteamID()] + 1
end

function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers()) do
		ply:StripWeapons()
		local eDodgeball = ply:Give("gmcore_funround_dodgeball")

		if ply:GetRole() == ROLE_DETECTIVE then
			eDodgeball:SetBallColor(Vector(0, 0, 1))
		elseif ply:GetRole() == ROLE_TRAITOR then
			eDodgeball:SetBallColor(Vector(1, 0, 0))
		end
	end
end

function EVENT:ComputeRewards()
	local sLastTeam = nil
	local plyTopKills = nil
	local iTopKills = 0

	for plySteamID, iKills in pairs(self.KillsThisRound) do
		local ply = player.GetBySteamID(plySteamID)
		if !ply or !ply:IsPlayer() then continue end

		local iPoints = iKills * self.Rewards.iPerKill

		if iKills > iTopKills then
			plyTopKills = ply
			iTopKills = iKills
		end

		ply:PS_GivePointsBoostable(iPoints)
		rewardMessageToPly(iKills .. " Fun Round kills", iPoints,  true, ply)
	end

	for _, ply in pairs(self:GetPlayers()) do
		if ply:Alive() then
			sLastTeam = ply:GetRole()
			break; -- No need to continue loop
		end
	end

	for _, ply in pairs(player.GetAll()) do
		if ply:GetRole() == sLastTeam then
			ply:PS_GivePointsBoostable(self.Rewards.iLastStanding)
			rewardMessageToPly("Apart of Last Team Standing!", self.Rewards.iLastStanding, true, ply)
		end
	end

	if plyTopKills then
		plyTopKills:PS_GivePointsBoostable(self.Rewards.iMostKills)
		rewardMessageToPly(iTopKills .. " | Most amount of kills!", self.Rewards.iMostKills, true, plyTopKills)
	end

	sLastTeam = sLastTeam == ROLE_DETECTIVE and "D" or "T" -- Final change for small net message, since alert winners checks last team like this

	local tToSendWinners = {
		lastTeam = sLastTeam or nil,
		eMostKills = plyTopKills or nil,
		iKillCount = iTopKills or 0
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound("Dodgeball", EVENT)
