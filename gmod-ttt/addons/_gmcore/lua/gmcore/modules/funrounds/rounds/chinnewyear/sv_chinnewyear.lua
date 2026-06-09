---@class ChinNewYearEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: ChinNewYearEvent): number
---@field OverrideRoles fun(self: ChinNewYearEvent): boolean
---@field PlayerDeath fun(self: ChinNewYearEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PlayerUse fun(self: ChinNewYearEvent, ply: Player, ent: Entity): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["ChinNewYear"] or {}
---@cast EVENT ChinNewYearEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale

local tWeaponSpawnPos = {} -- In EVENT:Prepare, is filled with position of all weapons before weapons are removed. Use for spawning food items in original weapon positions

local PERCENT_OF_MAX_SPAWN_ITEMS = 0.75 -- How many food items may be spawned at once via % of total weapon spawn positions
local MAX_ALLOWED_FOOD_ITEMS = 0 -- DO NOT CHANGE!!! Constant is determined EVENT:Prepare

function EVENT:Prepare()
	m_Begin(self)

	self.KillsThisRound = {} -- For counting how many kills each player has

	-- Remove all ammo and weapons from map. Populat tWeaponSpawnPos with all weapon positions
	for k, ent in pairs(ents.GetAll()) do
		if (ent.Base and ent.Base ~= nil and ent.Base ~= "") and ent.Base == "base_ammo_ttt" then
			ent:Remove()
		end

		if (ent.Base and ent.Base ~= nil and ent.Base ~= "") and ent.Base == "weapon_tttbase" then
			table.insert(tWeaponSpawnPos, ent:GetPos())
			ent:Remove()
		end

		if (ent.Base and ent.Base ~= nil and ent.Base ~= "") and ent.Base == "weapon_tttbasegrenade" then
			table.insert(tWeaponSpawnPos, ent:GetPos())
			ent:Remove()
		end
	end

	MAX_ALLOWED_FOOD_ITEMS = #tWeaponSpawnPos * PERCENT_OF_MAX_SPAWN_ITEMS

	self:AddHook("TTTBeginRound", self.SpawnLanterns)
	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
	self:AddHook("gmcore.FunRounds.OverrideRoles", self.OverrideRoles)
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

-- When round begins, spawns food items at original weapon spawn positions
function EVENT:SpawnLanterns()
	for _, pos in pairs(tWeaponSpawnPos) do
		local foodItem = ents.Create("sgm_funround_newyearlantern")
		foodItem:SetPos(pos)
		foodItem:Spawn()

		print("spawn", foodItem)
	end

	timer.Start("gmcore.FunRound.SpawnFoodItems")
end

gmcore.FunRounds:RegisterFunRound("ChinNewYear", EVENT)
