---@class HarpoonWarsEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: HarpoonWarsEvent): number
---@field OverrideRoles fun(self: HarpoonWarsEvent): boolean
---@field PlayerDeath fun(self: HarpoonWarsEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PreventWepPickup fun(self: HarpoonWarsEvent, ply: Player, wep: Weapon): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Harpoonwars"] or {}
---@cast EVENT HarpoonWarsEvent

EVENT.Active = true

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)

	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerDeath", self.PlayerDeath)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
end

local function giveharpoon(ply)
	if GetRoundState() != ROUND_ACTIVE then return end
	local SWEP = ply:Give("weapon_ttt_harpoon")
	ply:ShouldDropWeapon(false)

	function SWEP:PrimaryAttack()
		if not SERVER then return end

		local owner = self:GetOwner()
		local harpoon = self:SpawnHarpoon(owner:GetAimVector():Angle(), owner:GetShootPos())

		timer.Simple(5, function() if IsValid(harpoon) and not harpoon.Stuck then harpoon:Remove() end end)
		timer.Simple(1, function() giveharpoon(ply) end)

		self:Remove()
	end

	function SWEP:OnDrop()
		timer.Simple(1, function() giveharpoon(ply) end)
		self:Remove()
	end
end


function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers()) do
		ply:StripWeapons()
		giveharpoon(ply)
	end
end

-- Make everyone an innocent
function EVENT:OverrideWin()
	local iPlyCount = 0

	for _, ply in player.Iterator() do
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
	return wep:GetClass() == "weapon_ttt_harpoon"
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

	for _, v in player.Iterator() do
		if v:Alive() and !v:IsSpec() then
			plyLastAlive = v
		end
	end

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

gmcore.FunRounds:RegisterFunRound("Harpoonwars", EVENT)
