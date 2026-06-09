---@class FireworksEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: FireworksEvent): number
---@field OverrideRoles fun(self: FireworksEvent): boolean
---@field BeginWepDist fun(self: FireworksEvent)
---@field PreventWepPickup fun(self: FireworksEvent, ply: Player, wep: Weapon): boolean
---@field PlayerDeath fun(self: FireworksEvent, victim: Player, wep: Weapon, attacker: Player)

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Fireworks"] or {}
---@cast EVENT FireworksEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale
local m_End = EVENT.End or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)
	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("TTTBeginRound", self.BeginWepDist)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("PlayerDeath", self.PlayerDeath)
end

-- Prevent win until 1 player standing
function EVENT:OverrideWin()
	local iPlyCount = 0

	for _, ply in pairs(player.GetAll()) do
		if ply:IsTerror() and ply:Alive() then
			iPlyCount = iPlyCount + 1
		end
	end

	return iPlyCount > 1 and WIN_NONE or WIN_TRAITOR
end

-- Make everyone an innocent
function EVENT:OverrideRoles()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetRole(ROLE_INNOCENT)
	end

	return true
end

function EVENT:PreventWepPickup(ply, wep)
	return wep:GetClass() == "gmcore_funround_firework"
end

function EVENT:BeginWepDist()
	timer.Create("gmcore.FunRound.FireworkDist", 2, 0, function()
		for _, v in ipairs(self:GetPlayers()) do
			v:Give("gmcore_funround_firework")
		end
	end)

	timer.Start("gmcore.FunRound.FireworkDist")
end

-- Death tracker, computed in ComputeRewards
function EVENT:PlayerDeath(victim, _, attacker)
	if victim == attacker then return end
	if !IsValid(attacker) then return end
	if !attacker:IsPlayer() then return end

	if !self.KillsThisRound[attacker:SteamID()] then -- If the player hasn't killed anyone yet
		self.KillsThisRound[attacker:SteamID()] = 0
	end

	self.KillsThisRound[attacker:SteamID()] = self.KillsThisRound[attacker:SteamID()] + 1
end

function EVENT:End()
	m_End(self)

	timer.Remove("gmcore.FunRound.FireworkDist")
end


function EVENT:ComputeRewards()
	local plyLastAlive = nil
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

	for _, v in pairs(player.GetAll()) do
		if v:Alive() and !v:IsSpec() then
			plyLastAlive = v

			v:PS_GivePointsBoostable(self.Rewards.iLastStanding)
			rewardMessageToPly("Last Player Standing!", self.Rewards.iLastStanding,  true, v)
		end
	end

	BroadcastLua([[surface.PlaySound("gmcore/july4/firework/winning_player.mp3")]]) -- Everyone will hear fireworks sound at full volume. Better than EmitSound at last player's post imo ~ dime

	if plyTopKills then
		plyTopKills:PS_GivePointsBoostable(self.Rewards.iMostKills)
		rewardMessageToPly(iTopKills .. " | Most amount of kills!", self.Rewards.iMostKills, true, plyTopKills)
	end

	local tToSendWinners = {
		eLastAlive = plyLastAlive or nil,
		eMostKills = plyTopKills or nil,
		iKillCount = iTopKills or 0
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound("Fireworks", EVENT)
