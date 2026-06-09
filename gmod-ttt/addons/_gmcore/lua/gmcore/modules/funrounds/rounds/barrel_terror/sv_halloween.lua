---@class BarrelTerrorEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field EnemyPly Player The player selected as the enemy for this round
---@field OverrideRoles fun(self: BarrelTerrorEvent): boolean
---@field PreventWepPickup fun(self: BarrelTerrorEvent, ply: Player, wep: Weapon): boolean
---@field PlayerShouldTakeDamage fun(self: BarrelTerrorEvent, ply: Player, attacker: Entity): boolean
---@field SetAsEnemy fun(self: BarrelTerrorEvent, ply: Player)
---@field EntityTakeDamage fun(self: BarrelTerrorEvent, target: Entity, dmginfo: CTakeDamageInfo): boolean
---@field PlayerDeath fun(self: BarrelTerrorEvent, victim: Player, wep: Weapon, attacker: Player)

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Barrel Terror"] or {}
---@cast EVENT BarrelTerrorEvent
EVENT.AutoIDBodies = true

util.AddNetworkString("gmcore.FunRounds.HalloweenSendTraitor")

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale
local m_End = EVENT.End or nil -- Run the body defined by each instance of this metatbale

function EVENT:Prepare()
	m_Begin(self)

	self.KillsThisRound = {} -- For counting how many kills each player has
	self.EnemyPly = nil -- Set in EVENT:SetAsEnemy, ply that is picked as the enemy

	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("PlayerShouldTakeDamage", self.PlayerShouldTakeDamage)
end

-- Make everyone an innocent
function EVENT:OverrideRoles()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetRole(ROLE_INNOCENT)
	end

	local tLeadsAndDirectors = {}
	for _, ply in ipairs(self:GetPlayers()) do
		if ply:IsUserGroup("owner") or ply:IsUserGroup("leadadmin") or ply:IsUserGroup("developer") or ply:IsUserGroup("communitymanager") then
			table.insert(tLeadsAndDirectors, ply)
		end
	end

	self:SetAsEnemy(tLeadsAndDirectors[math.random(1, #tLeadsAndDirectors)])

	return true
end

function EVENT:PreventWepPickup(ply, wep)
	if ply:GetRole() != ROLE_TRAITOR then
		return GAMEMODE:PlayerCanPickupWeapon(ply, wep)
	else
		return wep:GetClass() == "weapon_ttt_barrel_gun" or wep:GetClass() == "weapon_ttt_knife"
	end
end

---@param ply Player Player to assign as the enemy for the Halloween fun round
function EVENT:SetAsEnemy(ply)
	if not IsValid(ply) then gmcore.DebugPrint("Invalid ply selected for enemy") return end

	ply.gmcoreHalloweenOriginalWalkSpeed = ply:GetWalkSpeed()
	ply.gmcoreHalloweenOriginalJumpPower = ply:GetJumpPower()
	ply.gmcoreHalloween = ply.gmcoreHalloween or ply:GetViewOffset() -- Make viewpoint on client taller to match model scaling
	ply.gmcoreHalloweenDucked = ply.gmcoreHalloweenDucked or ply:GetViewOffsetDucked()

	ply:SetRole(ROLE_TRAITOR)
	ply:SetHealth(#self:GetPlayers() * 1000)
	ply:SetModelScale(1.1, 0)
	ply:SetViewOffset(ply.gmcoreHalloween * 1.3)
	ply:SetViewOffsetDucked(ply.gmcoreHalloweenDucked * 1.3)
	ply:SetJumpPower(ply.gmcoreHalloweenOriginalJumpPower * 2.5)
	ply:SetWalkSpeed(ply.gmcoreHalloweenOriginalWalkSpeed * 1.5)

	-- 2 second timer since pointshop models apply late. This will override PS model
	timer.Simple(2, function()
		if not IsValid(ply) then return end

		ply:SetModel("models/player/pizzaroll/baronofhell.mdl")
	end)

	ply:StripWeapons()
	ply:Give("weapon_ttt_knife")
	ply:Give("weapon_ttt_barrel_gun")

	timer.Create("gmcore.FunRounds.GiveReaperHarpoon", 30, 0, function()
		ply:Give("weapon_ttt_barrel_gun")
	end)

	timer.Create("gmcore.FunRounds.GiveReaperKnife", 3, 0, function()
		ply:Give("weapon_ttt_knife")
	end)

	net.Start("gmcore.FunRounds.HalloweenSendTraitor")
	net.WriteEntity(ply)
	net.Broadcast()
end

function EVENT:PlayerShouldTakeDamage(victim, attacker)
	if not victim:IsPlayer() and attacker:IsPlayer() and IsValid(victim) and IsValid(attacker) then return end

	if victim:GetRole() == attacker:GetRole() or
		victim:GetRole() == ROLE_INNOCENT and attacker:GetRole() == ROLE_DETECTIVE then

			return false
	end

	return true
end

function EVENT:End()
	m_End(self)

	for _, v in player.Iterator() do
		if v:GetRole() == ROLE_TRAITOR then
			v:SetViewOffset(v.gmcoreHalloween)
			v:SetViewOffsetDucked(v.gmcoreHalloweenDucked)
			v:SetJumpPower(v.gmcoreHalloweenOriginalJumpPower)
			v:SetWalkSpeed(v.gmcoreHalloweenOriginalWalkSpeed)
			v:SetModelScale(1)

			break; -- Only 1 grim reaper. No longer need to continue looping
		end
	end

	timer.Remove("gmcore.FunRounds.GiveReaperHarpoon")
	timer.Remove("gmcore.FunRounds.GiveReaperKnife")
end

function EVENT:ComputeRewards()
	local sLastTeam

	for _, v in ipairs(self:GetPlayers()) do
		if v:GetRole() == ROLE_TRAITOR then
			sLastTeam = "T"
		else
			for _, w in player.Iterator() do
				if w:GetRole() == ROLE_INNOCENT then
					file.Write("gmcore/" .. w:SteamID64() .. "_halloween.txt", "PRIZE!") -- TODO: Replace with Halloween 2025 item
				end
			end

			sLastTeam = "I"
		end
	end

	local tToSendWinners = {
		lastTeam = sLastTeam or nil,
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound(EVENT.sTitle, EVENT)
