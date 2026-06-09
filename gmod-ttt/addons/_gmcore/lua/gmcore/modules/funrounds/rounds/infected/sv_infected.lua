---@class InfectedEvent : FunRound
---@field OverrideWin fun(self: InfectedEvent): number
---@field OverrideRoles fun(self: InfectedEvent): boolean
---@field PlayerDeath fun(self: InfectedEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PreventWepPickup fun(self: InfectedEvent, ply: Player, wep: Weapon): boolean
---@field PlayerCanPickupWeapon fun(self: InfectedEvent, ply: Player, wep: Weapon): boolean
---@field EntityTakeDamage fun(self: InfectedEvent, target: Entity, dmginfo: CTakeDamageInfo): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Infected"] or {}
---@cast EVENT InfectedEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale
local m_End = EVENT.End or nil -- Run the body defined by each instance of this metatbale

local endTime = 0

local zombieSpeedMult = 1.2
local zombieJumpPwr = 1.4
local infectedTime = 3	--Minutes a round of infected should be at most. Humans have to survive this long.
local oldTime = nil

local primarySelection = {
		"weapon_zm_mac10",
		"weapon_ttt_usc",
		"weapon_ttt_mp5",
		"weapon_ttt_ak47",
		"weapon_ttt_an94",
		"weapon_ttt_m4a4",
		"weapon_ttt_m16",
		"weapon_ttt_an94",
		"weapon_ttt_famas",
		"weapon_ttt_f2000",
		"weapon_ttt_galil",
		"weapon_ttt_sl8",
		"weapon_ttt_aug",
		"weapon_ttt_m14ebr",
		"weapon_zm_shotgun",
		"weapon_ttt_benelli_m3",
		"weapon_ttt_ksg",
		"weapon_ttt_benelli_m3",
		"weapon_ttt_double_barrel",
		"weapon_zm_rifle",
		"weapon_ttt_m24",
		"weapon_ttt_barrett_m82",
		"weapon_ttt_intervention",
		"weapon_ttt_m1_garand",
		"weapon_ttt_m1918_bar",
		"weapon_ttt_p90",
		"weapon_ttt_scar",
		"weapon_ttt_thompson",
		"weapon_ttt_winchester_1873"
}

local secondarySelection = {
		"weapon_zm_pistol",
		"weapon_ttt_glock",
		"weapon_ttt_luger",
		"weapon_ttt_python",
		"weapon_zm_revolver",
		"weapon_ttt_usp",
		"weapon_ttt_dual_berettas",
		"weapon_ttt_remington_1858"
}

local primary = math.random(1, #primarySelection)
local secondary = math.random(1, #secondarySelection)

util.AddNetworkString("gmcore.FunRounds.UpdateZombies")

local function updateZombies()
	net.Start("gmcore.FunRounds.UpdateZombies")
		net.WriteBool(true)
	net.Broadcast()
end

function infectedTimeLeft()
	if CurTime() < endTime then
		return endTime - CurTime()
	end

	return 9999
end

function EVENT:Prepare()
	m_Begin(self)
	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("TTTPreCreateCorpse", self.RemoveRagdollOnDeath)
	self:AddHook("PlayerShouldTakeDamage", self.PlayerShouldTakeDamage)
	self:AddHook("PlayerDeath", self.PlayerDeath)

	local timeVar = GetConVar("ttt_roundtime_minutes")
	oldTime = timeVar:GetInt()
	timeVar:SetInt(infectedTime)
end

function EVENT:distributeRandomWeps()
	local players = self:GetPlayers()
	for i, ply in pairs(players) do
		if ply:GetRole() == ROLE_INNOCENT then
			local prim = ply:Give(primarySelection[primary])
			local sec = ply:Give(secondarySelection[secondary])

			ply:GiveAmmo(prim.Primary.ClipMax * 2, prim.Primary.Ammo)
			ply:GiveAmmo(sec.Primary.ClipMax * 2, sec.Primary.Ammo)
		end
	end
end

function EVENT:OverrideRoles()
	local players = self:GetPlayers()

	for i, ply in pairs(players) do
		if (i == 1 or (i % 10 == 0)) then -- 1 zombie + another zombie for every 10 players
			ply:SetRole(ROLE_TRAITOR)
			-- 2 second timer since pointshop models apply late. This will override PS model
			timer.Simple(2, function()
				ply:SetModel("models/player/grim/grim.mdl")
			end)
		else
			ply:SetRole(ROLE_INNOCENT)
		end
	end

	return true
end

function EVENT:OverrideWin()
	local humanAlive = false
	local zombieExists = false
	for _, ply in pairs(player.GetAll()) do
		if ply:GetRole() == ROLE_TRAITOR and !ply:GetForceSpec() then
			zombieExists = true
		end
		if ply:IsTerror() and ply:GetRole() == ROLE_INNOCENT then
			humanAlive = true
			if CurTime() < endTime and zombieExists then
				return WIN_NONE
			end
		end
	end

	if !zombieExists then
		return WIN_INNOCENT
	end

	if !humanAlive then
		return WIN_TRAITOR
	end

	if CurTime() < endTime and humanAlive then
		return WIN_NONE
	end

	if CurTime() >= endTime and humanAlive then
		return WIN_INNOCENT
	end

	return WIN_NONE
end

--[[
	Returns true if the player is allowed to pick up this weapon.
]]
function EVENT:PreventWepPickup(ply, wep)
	if ply:GetRole() == ROLE_TRAITOR then
		return wep:GetClass() == "weapon_ttt_zombie_knife"
	end
	if ply:GetRole() == ROLE_INNOCENT then
		return wep:GetClass() == primarySelection[primary] or wep:GetClass() == secondarySelection[secondary]
	end
end

--Only remove ragdoll of infected to prevent ragdoll buildup, Detective/human ragdolls can remain.
function EVENT:RemoveRagdollOnDeath(ply)
	if ply:GetRole() == ROLE_TRAITOR then
		return false
	end
end

--Copied from halloween code.
function EVENT:PlayerShouldTakeDamage(victim, attacker)
	if victim:IsPlayer() and attacker:IsPlayer() and IsValid(victim) and IsValid(attacker) then
		if victim:GetRole() == ROLE_INNOCENT and attacker:GetRole() == ROLE_INNOCENT then
			return false
		elseif victim:GetRole() == ROLE_TRAITOR and attacker:GetRole() == ROLE_TRAITOR then
			return false
		elseif victim:GetRole() == ROLE_DETECTIVE and attacker:GetRole() == ROLE_DETECTIVE then
			return false
		elseif victim:GetRole() == ROLE_INNOCENT and attacker:GetRole() == ROLE_DETECTIVE then
			return false
		else
			return true
		end
	end
end

local function giveZombieWep(ply)
	if not (ply:IsSpec() or ply:GetNWBool("TTTIsForceSpec")) and gmcore.FunRounds.ActiveRound then
		ply:Give("weapon_ttt_zombie_knife")
		ply:ShouldDropWeapon(false)
	end
end

function refreshWeps()
	for _, ply in pairs(player.GetAll()) do
		if !ply:HasWeapon("weapon_ttt_zombie_knife") and ply:GetRole() == ROLE_TRAITOR and ply:Alive() and !ply:IsSpec() and !ply:GetNWBool("TTTIsForceSpec") then
			giveZombieWep(ply)
		end
	end
end

local function syncWep(ply)
	if ply:Alive() and !ply:IsSpec() and !ply:GetNWBool("TTTIsForceSpec") and ply:GetRole() == ROLE_TRAITOR and !ply:HasWeapon("weapon_ttt_zombie_knife") then
		giveZombieWep(ply)
	end
end

--Infects player by making them traitor and respawning them.
local function infectPlayer(ply)
	ply:SetRole(ROLE_TRAITOR)
	timer.Simple(3, function()
		ply:SpawnForRound(true)
		ply:SetModel("models/player/grim/grim.mdl")

		timer.Simple(0.5, function()
			ply.originalWalkSpd = ply:GetWalkSpeed()
			ply:SetWalkSpeed(ply.originalWalkSpd * zombieSpeedMult)

			ply.originalJumpPwr = ply:GetJumpPower()
			ply:SetJumpPower(ply.originalJumpPwr * zombieJumpPwr)
			giveZombieWep(ply)
			syncWep(ply)
		end)
	end)
end

function EVENT:grantKillCredit(ply, infection)
	if !self.KillsThisRound[ply:SteamID()]["infections"] and infection then -- If the player hasn't killed anyone yet
		self.KillsThisRound[ply:SteamID()]["infections"] = 1

		return
	elseif !self.KillsThisRound[ply:SteamID()]["zombieKills"] and !infection then
		self.KillsThisRound[ply:SteamID()]["zombieKills"] = 1

		return
	end

	if infection then
		self.KillsThisRound[ply:SteamID()]["infections"] = self.KillsThisRound[ply:SteamID()]["infections"] + 1
	else
		self.KillsThisRound[ply:SteamID()]["zombieKills"] = self.KillsThisRound[ply:SteamID()]["zombieKills"] + 1
	end
end

-- Death tracker, computed in ComputeRewards
function EVENT:PlayerDeath(victim, _, attacker)
	--Human dies, infect them and award kill credit if killer is valid.
	if victim:GetRole() == ROLE_INNOCENT and !victim:IsSpec() and !victim:GetNWBool("TTTIsForceSpec") then
		infectPlayer(victim)
		victim:SetRole(ROLE_TRAITOR)

		if attacker:IsPlayer() and (victim != attacker) and attacker:GetRole() == ROLE_TRAITOR then
			self:grantKillCredit(attacker, true)
		end

		updateZombies()

		return
	end

	--Zombie dies, respawn them and award kill credit if killer is valid.
	if victim:GetRole() == ROLE_TRAITOR then
		if attacker:IsPlayer() and (victim != attacker) and attacker:GetRole() == ROLE_INNOCENT then
			self:grantKillCredit(attacker, false)
		end

		timer.Simple(3, function()
			victim:SpawnForRound(true)
			giveZombieWep(victim)
		end)

		timer.Simple(3.5, function()
			victim:SetModel("models/player/grim/grim.mdl")
		end)
	end
end

function EVENT:Begin()
	for _, ply in pairs(self:GetPlayers()) do
		if ply:GetRole() == ROLE_TRAITOR then
			ply:StripWeapons()

			ply.originalWalkSpd = ply:GetWalkSpeed()
			ply:SetWalkSpeed(ply.originalWalkSpd * 1.1)

			ply.originalJumpPwr = ply:GetJumpPower()
			ply:SetJumpPower(ply.originalJumpPwr * 1.3)
			giveZombieWep(ply)
			ply:SetHealth(75)
		end
		if ply:GetRole() == ROLE_INNOCENT then
		ply:StripWeapons()
		end

		self.KillsThisRound[ply:SteamID()] = {}

		self.KillsThisRound[ply:SteamID()]["infections"] = 0
		self.KillsThisRound[ply:SteamID()]["zombieKills"] = 0
	end
	endTime = CurTime() + (infectedTime * 60) - 1		--Give players 3 minutes to play the round.
	self:distributeRandomWeps()
end

function EVENT:End()
	m_End(self) -- Call metatable for original end

	for _, v in ipairs(player.GetAll()) do
		v:StripWeapons()
		if v:GetRole() == ROLE_TRAITOR then
			if v.originalJumpPwr and v.originalJumpPwr != v:GetJumpPower() then
				v:SetJumpPower(v.originalJumpPwr)
			end

			if v.originalWalkSpd and v.originalWalkSpd != v:GetWalkSpeed() then
				v:SetWalkSpeed(v.originalWalkSpd)
			end
		end
	end

	timer.Simple(5 , function ()
		for _, v in ipairs(player.GetAll()) do
			if IsValid(v) then
				v:StripWeapons()
			end
		end
	end)

	local timeDef = GetConVar("ttt_roundtime_minutes")
	timeDef:SetInt(oldTime)
end

--Using Dodgeball code for now. Temporary measure while balance design is being worked out.
function EVENT:ComputeRewards()
	local sLastTeam = nil
	local plyTopInfections = nil
	local plyTopZombieKills = nil

	local topInfections	= 0
	local topZombieKills = 0

	for plySteamID, iKills in pairs(self.KillsThisRound) do
		local ply = player.GetBySteamID(plySteamID)
		if !ply or !ply:IsPlayer() then continue end

		local infections = 0
		local zombieKills = 0

		if self.KillsThisRound[plySteamID]["infections"] then
			infections = self.KillsThisRound[plySteamID]["infections"]
		end

		if self.KillsThisRound[plySteamID]["zombieKills"] then
			zombieKills = self.KillsThisRound[plySteamID]["zombieKills"]
		end

		local iPoints = (infections + zombieKills) * self.Rewards.iPerKill

		if infections > topInfections then
			plyTopInfections = ply
			topInfections = infections
		end

		if zombieKills > topZombieKills then
			plyTopZombieKills = ply
			topZombieKills = zombieKills
		end

		ply:PS_GivePointsBoostable(iPoints)
		rewardMessageToPly(infections .. " Infection kills", infections * self.Rewards.iPerKill,  true, ply)
		rewardMessageToPly(zombieKills .. " Zombie kills", zombieKills * self.Rewards.iPerKill,  true, ply)
	end

	sLastTeam = ROLE_TRAITOR
	for _, ply in pairs(self:GetPlayers()) do
		if ply:Alive() and ply:GetRole() == ROLE_INNOCENT then
			sLastTeam = ply:GetRole()
			break; -- No need to continue loop
		end
	end

	for _, ply in pairs(player.GetAll()) do
		--Only reward humans for surviving.
		if ply:GetRole() == sLastTeam and ply:GetRole() == ROLE_INNOCENT then
			ply:PS_GivePointsBoostable(self.Rewards.iLastStanding)
			rewardMessageToPly("A part of the surviving Humans!", self.Rewards.iLastStanding, true, ply)
		end
	end

	if plyTopInfections then
		plyTopInfections:PS_GivePointsBoostable(self.Rewards.mostInfections)
		rewardMessageToPly(plyTopInfections:GetName() .. " | Most amount of Infections!", self.Rewards.mostInfections, true, plyTopInfections)
	end

	if plyTopZombieKills then
		plyTopZombieKills:PS_GivePointsBoostable(self.Rewards.mostZombieKills)
		rewardMessageToPly(plyTopZombieKills:GetName() .. " | Most amount of Zombie Kills!", self.Rewards.mostZombieKills, true, plyTopZombieKills)
	end

	sLastTeam = sLastTeam == ROLE_INNOCENT and "D" or "T" -- Final change for small net message, since alert winners checks last team like this

	local tToSendWinners = {
		lastTeam = sLastTeam or nil,
		mostInfections = plyTopInfections or nil,
		mostZombKills = plyTopZombieKills or nil,
		iZombieKills = topZombieKills or 0,
		iInfections = topInfections or 0
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

hook.Add("PlayerSpawn", "gmcore.Infected.MonitorModelStatus", function(ply)
	if gmcore.FunRounds.ActiveRound and gmcore.FunRounds.ChosenFunRound == "Infected" and IsValid(ply) and ply:GetRole() == ROLE_TRAITOR then
			ply:SetHealth(75)
			timer.Simple(3, function()
				ply:SetModel("models/player/grim/grim.mdl")
			end)
	end
end)

gmcore.FunRounds:RegisterFunRound("Infected", EVENT)
