---@class GunGameEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: GunGameEvent): number
---@field OverrideRoles fun(self: GunGameEvent): boolean
---@field PlayerDeath fun(self: GunGameEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PreventWepPickup fun(self: GunGameEvent, ply: Player, wep: Weapon): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["gungame"] or {}
---@cast EVENT GunGameEvent

EVENT.AutoIDBodies = true

-- Weapons broken down into categories for picking
local availableWeps = {
	smg = {
		"weapon_zm_mac10",
		"weapon_ttt_usc",
		"weapon_ttt_mp5",
	},
	ar = {
		"weapon_ttt_ak47",
		"weapon_ttt_m16",
		"weapon_ttt_famas",
		"weapon_ttt_f2000",
		"weapon_ttt_galil",
	},
	dmr = {
		"weapon_ttt_sl8",
		"weapon_ttt_aug",
		"weapon_ttt_m14ebr"
	},
	shotgun = {
		"weapon_zm_shotgun",
		"weapon_ttt_benelli_m3",
		"weapon_ttt_ksg",
		"weapon_ttt_benelli_m3",
		"weapon_ttt_double_barrel"
	},
	sniper = {
		"weapon_zm_rifle",
		"weapon_ttt_m24",
		"weapon_ttt_barrett_m82"
	},
	pistol = {
		"weapon_zm_pistol",
		"weapon_ttt_glock",
		"weapon_ttt_luger",
		"weapon_ttt_python",
		"weapon_zm_revolver",
		"weapon_ttt_usp"
	}
}

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

--[[
	Given a weapon category, picks 2 random weps and puts them into event's weapons for disbursement
]]
local function populateWithRandomWeps(cat)
	for i = 1, 2 do
		local randomIndex = math.random(1, #EVENT.weaponsAvailable[cat])

		table.insert(EVENT.weaponTierList, EVENT.weaponsAvailable[cat][randomIndex])
		table.remove(EVENT.weaponsAvailable[cat], randomIndex) -- Remove so we don't pick the same wep twice
	end
end

function EVENT:Prepare()
	m_Begin(self)

	self.weaponsAvailable = table.Copy(availableWeps) -- Used so we don't delete our original reference table
	self.weaponTierList = {} -- List of weapons to give in order
	self.KillsThisRound = {} -- For counting how many kills each player has

	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("TTTPreCreateCorpse", self.RemoveRagdollOnDeath)
	self:AddHook("PlayerDeath", self.PlayerDeath)

	-- Randomly pick 2 weps from each category. Can't use loop for availableWeps since it goes out of order
	populateWithRandomWeps("smg")
	populateWithRandomWeps("ar")
	populateWithRandomWeps("dmr")
	populateWithRandomWeps("shotgun")
	table.insert(self.weaponTierList, "weapon_zm_sledge")
	populateWithRandomWeps("sniper")
	populateWithRandomWeps("pistol")
end

function EVENT:Begin()
	for _, ply in ipairs(self:GetPlayers()) do
		self:ApplyWeps(ply)
	end
end

-- Make everyone an innocent
function EVENT:OverrideWin()
	for _, ply in pairs(player.GetAll()) do
		if ply:IsTerror() and ply:Alive() and ply:GetNWInt("gmcore.GunGameLevel", 1) > 14 then
			return WIN_TRAITOR
		end
	end

	return WIN_NONE
end

-- Make everyone an innocent
function EVENT:OverrideRoles()
	for _, ply in pairs(self:GetPlayers()) do
		ply:SetRole(ROLE_INNOCENT)
	end

	return true
end

function EVENT:PreventWepPickup(ply, wep)
	return wep:GetClass() == ply.gg_currentweapon or wep:GetClass() == "weapon_zm_improvised" or wep:GetClass() == "weapon_ttt_knife"
end

--[[
	Checks a player's gun game level and gives them the corresponding weapon
]]
function EVENT:ApplyWeps(ply)
	if not ply:IsAlive() then return end
	if ply.gg_currentweapon then
		ply:StripWeapon(ply.gg_currentweapon)
	else
		ply:StripWeapons()

		local crowbar = ply:Give("weapon_zm_improvised")
		crowbar.Primary.Damage = 2000
	end

	local plyLevel = math.Clamp(ply:GetNWInt("gmcore.GunGameLevel", 1), 1, 15)

	-- If we have level 14 then give knife
	if plyLevel >= 14 then
		local knife = ply:Give("weapon_ttt_knife")
		knife.AllowDrop = false
		ply:SelectWeapon(knife)

		return
	end

	ply.gg_currentweapon = self.weaponTierList[ply:GetNWInt("gmcore.GunGameLevel", 1)]
	local wep = ply:Give(ply.gg_currentweapon)
	ply:SetAmmo(100, wep:GetPrimaryAmmoType())
	wep.AllowDrop = false
	ply:SelectWeapon(wep)
end

function EVENT:RemoveRagdollOnDeath(rag, ply)
	return false
end

-- Death tracker, computed in ComputeRewards
function EVENT:PlayerDeath(victim, wep, attacker)
	if !IsValid(victim) then return end
	if victim:GetForceSpec() then return end -- check they havnt switched to spec so we don't arm a spectator
	if !IsValid(attacker) or not attacker:IsPlayer() then -- fall etc
		timer.Simple(1, function()
			victim:SpawnForRound(true)
			self:ApplyWeps(victim)
		end)

		return
	end

	-- If we kill ourselves just respawn with no effect
	if victim == attacker then
		timer.Simple(1, function()
			victim:SpawnForRound(true)
			self:ApplyWeps(victim)
		end)

		return
	end

	if !self.KillsThisRound[attacker:SteamID()] then -- If the player hasn't killed anyone yet
		self.KillsThisRound[attacker:SteamID()] = 1
	end

	self.KillsThisRound[attacker:SteamID()] = self.KillsThisRound[attacker:SteamID()] + 1

	-- Now handle weapon tracking for level
	-- For some reason PlayerDeath is called twice on same tick. This prevents double calls
	if victim.GMCoreGunGameLastDieTime and victim.GMCoreGunGameLastDieTime == CurTime() then return end
	victim.GMCoreGunGameLastDieTime = CurTime()

	if wep:GetClass() == "weapon_zm_improvised" then
		victim:SetNWInt("gmcore.GunGameLevel", math.Clamp(attacker:GetNWInt("gmcore.GunGameLevel", 1) - 1, 1, 14)) -- Humiliation from COD

		-- Respawn victim and apply weps
		timer.Simple(1, function()
			victim:SpawnForRound(true)
			self:ApplyWeps(victim)
		end)

		return
	end -- Crowbar deaths don't count so don't run code below to increment attacker's level

	-- Respawn victim and apply weps
	timer.Simple(1, function()
		victim:SpawnForRound(true)
		self:ApplyWeps(victim)
	end)

	attacker:SetNWInt("gmcore.GunGameLevel", attacker:GetNWInt("gmcore.GunGameLevel", 1) + 1)

	if attacker.gg_currentweapon then
		attacker:SetFOV(0, 0.2)
		attacker:StripWeapon(attacker.gg_currentweapon)
	end

	timer.Simple(0.5, function()
		self:ApplyWeps(attacker)
	end)
end

function EVENT:ComputeRewards()
	local plyWinGG = nil

	for _, v in pairs(self:GetPlayers()) do
		if v:Alive() and !v:IsSpec() and v:GetNWInt("gmcore.GunGameLevel") > 14 then
			plyWinGG = v

			plyWinGG:PS_GivePointsBoostable(self.Rewards.winsGG)
			rewardMessageToPly("Winning Gun Game!", self.Rewards.winsGG, true, plyWinGG)

			v:SetNWInt("gmcore.GunGameLevel", 1)
		end
	end


	local tToSendWinners = {
		plyWinGG = plyWinGG or nil,
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
end

gmcore.FunRounds:RegisterFunRound("gungame", EVENT)
