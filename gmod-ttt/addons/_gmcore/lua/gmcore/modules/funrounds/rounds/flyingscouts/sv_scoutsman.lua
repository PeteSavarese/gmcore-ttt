---@class FlyingScoutsEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: FlyingScoutsEvent): number
---@field OverrideRoles fun(self: FlyingScoutsEvent): boolean
---@field PlayerDeath fun(self: FlyingScoutsEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PreventWepPickup fun(self: FlyingScoutsEvent, ply: Player, wep: Weapon): boolean
---@field DoPlayerDeath fun(self: FlyingScoutsEvent, ply: Player, attacker: Entity, dmginfo: CTakeDamageInfo)

local EVENT = gmcore.FunRounds.RegisteredFunRounds["flyingscouts"] or {}
---@cast EVENT FlyingScoutsEvent

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
	self:AddHook("DoPlayerDeath", self.DoPlayerDeath)
end

local function supplyWeapons(ply)
	ply:StripWeapons()

	local scoutSWEP = ply:Give("weapon_zm_rifle")
	scoutSWEP.AllowDrop = false
	ply:GiveAmmo(500, scoutSWEP:GetPrimaryAmmoType(), true)
end


function EVENT:Begin()
	RunConsoleCommand("sv_gravity", 150)
	RunConsoleCommand("sv_airaccelerate", 100)

	for _, ply in pairs(self:GetPlayers()) do
		supplyWeapons(ply)
	end
end

-- Make everyone an innocent
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
	return wep:GetClass() == "weapon_zm_rifle"
end

-- Death tracker, computed in ComputeRewards
function EVENT:PlayerDeath(victim, wep, attacker)
	if !IsValid(attacker) then return end
	if !attacker:IsPlayer() then return end
	if !IsValid(victim) then return end
	if victim == attacker then return end

	if !self.KillsThisRound[attacker:SteamID()] then -- If the player hasn't killed anyone yet
		self.KillsThisRound[attacker:SteamID()] = 0
	end

	self.KillsThisRound[attacker:SteamID()] = self.KillsThisRound[attacker:SteamID()] + 1
end

--[[
	Handles ammo dispursement when killed with either deagle or crowbar
]]
function EVENT:DoPlayerDeath(victim, attacker, dmginfo)
	if !IsValid(attacker) then return end
	if !IsValid(victim) then return end
	if victim == attacker then return end

	-- Now handle weapon tracking for level
	-- For some reason PlayerDeath is called twice on same tick. This prevents double calls
	if victim.GMCoreGunGameLastDieTime and victim.GMCoreGunGameLastDieTime == CurTime() then return end
	victim.GMCoreGunGameLastDieTime = CurTime()
end

function EVENT:ComputeRewards()
	RunConsoleCommand("sv_gravity", 600)
	RunConsoleCommand("sv_airaccelerate", 10)

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

gmcore.FunRounds:RegisterFunRound("flyingscouts", EVENT)
