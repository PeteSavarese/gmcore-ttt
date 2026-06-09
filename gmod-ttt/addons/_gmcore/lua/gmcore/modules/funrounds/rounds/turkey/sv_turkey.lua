util.AddNetworkString("gmcore.FunRound.Turkey.StuffKillConfetti")

---@class TurkeyEvent : FunRound
---@field KillsThisRound table<Player, number>
---@field OverrideWin fun(self: TurkeyEvent): number
---@field OverrideRoles fun(self: TurkeyEvent): boolean
---@field PreventWepPickup fun(self: TurkeyEvent, ply: Player, wep: Weapon): boolean
---@field PlayerDeath fun(self: TurkeyEvent, victim: Player, wep: Weapon, attacker: Player)
---@field PlayerUse fun(self: TurkeyEvent, ply: Player, ent: Entity): boolean

local EVENT = gmcore.FunRounds.RegisteredFunRounds["Turkey"] or {}
---@cast EVENT TurkeyEvent

EVENT.AutoIDBodies = true

local m_Begin = EVENT.Prepare or nil -- Run the body defined by each instance of this metatbale
local m_End = EVENT.End or nil -- Run the body defined by each instance of this metatbale
local tWeaponSpawnPos = {} -- In EVENT:Prepare, is filled with position of all weapons before weapons are removed. Use for spawning food items in original weapon positions

--[[
0* Table of food items which are allowed to spawn, along with their chance of spawning out of 10. Order from most likely to least likely
0*
0* Index values
0*    1. Weapon class
0*    2. chance of spawning out of 100
0--]]
local tFoodItems = {
	[1] = {"gmcore_funround_turkeyleg", 0}, -- Set to 0 since if no item is chosen out of 100, a turkey leg will spawn by default.
	[2] = {"gmcore_funround_wine", 70},
	[3] = {"gmcore_funround_pie", 45},
	[4] = {"gmcore_funround_turkey", 35}
}

local tFoodItemsStuffCount = {
	["gmcore_funround_turkeyleg"] = 1,
	["gmcore_funround_wine"] = 2,
	["gmcore_funround_pie"] = 3,
	["gmcore_funround_turkey"] = 4,
}

local PERCENT_OF_MAX_SPAWN_ITEMS = 0.75 -- How many food items may be spawned at once via % of total weapon spawn positions
local MAX_ALLOWED_FOOD_ITEMS = 0 -- DO NOT CHANGE!!! Constant is determined EVENT:Prepare

function EVENT:Prepare()
	m_Begin(self)
	self.StuffingThisRound = {} -- We don't track kills. Instead track how many times a person stuffed someone else.

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

	self:AddHook("TTTBeginRound", self.SpawnFoodItems)
	self:AddHook("gmcore.FunRound.Turkey.PlayerStuffed", self.PlayerStuffed)
	self:AddHook("PlayerCanPickupWeapon", self.PreventWepPickup)
	self:AddHook("gmcore.FunRounds.OverrideWin", self.OverrideWin)
end

function EVENT:Begin()
	for _, ply in ipairs(player.GetAll()) do
		ply.iOriginalWalkSpeed = ply:GetWalkSpeed()
		ply:SetWalkSpeed(400)
	end
end

function EVENT:PreventWepPickup(ply, wep)
	return wep:GetClass() == "gmcore_funround_wine" or wep:GetClass() == "gmcore_funround_turkeyleg" or wep:GetClass() == "gmcore_funround_pie" or wep:GetClass() == "gmcore_funround_turkey"
end

-- When round begins, spawns food items at original weapon spawn positions
function EVENT:SpawnFoodItems()
	for _, pos in pairs(tWeaponSpawnPos) do
		local iChance = math.random(1, 100)
		local tChoseChoice = nil

		local tRandomFoodChosen = tFoodItems[math.random(1, #tFoodItems)]

		if iChance <= tRandomFoodChosen[2] then
			tChoseChoice = tRandomFoodChosen
		else
			tChoseChoice = tFoodItems[1] -- Make turkey leg default
		end

		if !tChoseChoice then continue end -- No item picked. Re-roll

		local foodItem = ents.Create("gmcore_funround_ents_fooditem")
		foodItem:SetPos(pos)
		foodItem:SetItemClass(tChoseChoice[1])
		foodItem:Spawn()
	end

	timer.Create("gmcore.FunRound.SpawnFoodItems", 7.5, 0, function()
		local iCurrentlySpawned = 0 -- How many food items are currently spawned

		for k, ent in pairs(ents.GetAll()) do
			if (ent.Base and ent.Base ~= nil and ent.Base ~= "") and ent:GetClass() == "gmcore_funround_ents_fooditem" then
				iCurrentlySpawned = iCurrentlySpawned + 1
			end
		end

		for _, pos in pairs(tWeaponSpawnPos) do
			if iCurrentlySpawned >= MAX_ALLOWED_FOOD_ITEMS then return end -- Don't spawn anymore than the allowed limit

			local bCurrenltSpawnedAtPos = false

			for _, ent in pairs(ents.FindInSphere(pos, 5)) do
				if (ent.Base and ent.Base ~= nil and ent.Base ~= "") and ent:GetClass() == "gmcore_funround_ents_fooditem" then
					bCurrenltSpawnedAtPos = true -- There is already a food item
					break; -- No need to loop through any other entities
				end
			end


			if bCurrenltSpawnedAtPos then continue end -- Loop to next spawn pos since there is already a food item here

			local iChance = math.random(1, 100)
			local tChoseChoice = nil

			local tRandomFoodChosen = tFoodItems[math.random(1, #tFoodItems)]

			if iChance <= tRandomFoodChosen[2] then
				tChoseChoice = tRandomFoodChosen
			else
				tChoseChoice = tFoodItems[1] -- Make turkey leg default
			end

			if !tChoseChoice then continue end -- No item picked. Re-roll

			local foodItem = ents.Create("gmcore_funround_ents_fooditem")
			foodItem:SetPos(pos)
			foodItem:SetItemClass(tChoseChoice[1])
			foodItem:Spawn()

			iCurrentlySpawned = iCurrentlySpawned + 1
		end
	end)

	timer.Start("gmcore.FunRound.SpawnFoodItems")
end

function EVENT:End()
	m_End(self)

	-- Reset everyone's playermodels back to normal
	local iFatSize = 1

	for _, ply in ipairs(player.GetAll()) do
		local boneID = ply:LookupBone("ValveBiped.Bip01_Spine4")

		if boneID or boneID == true then
			scale = Vector(iFatSize, iFatSize, iFatSize)
			ply:ManipulateBoneScale(boneID, scale)
		end

		boneID = ply:LookupBone("ValveBiped.Bip01_Spine2")
		if boneID or boneID == true then
			scale = Vector(iFatSize, iFatSize, iFatSize)
			ply:ManipulateBoneScale(boneID, scale)
		end

		boneID = ply:LookupBone("ValveBiped.Bip01_Spine")
		if boneID or boneID == true then
			scale = Vector(iFatSize, iFatSize, iFatSize)
			ply:ManipulateBoneScale(boneID, scale)
		end

		boneID = ply:LookupBone("ValveBiped.Bip01_Pelvis")
		if boneID or boneID == true then
			scale = Vector(iFatSize, iFatSize, iFatSize)
			ply:ManipulateBoneScale(boneID, scale)
		end

		ply:SetWalkSpeed(ply.iOriginalWalkSpeed ~= nil and ply.iOriginalWalkSpeed or 220)
	end

	timer.Remove("gmcore.FunRound.SpawnFoodItems")
end

--[[
0* Hook runs whenever a food item is fired upon another player
0*
0* eItem: the weapon which calls this function. Either pumpkin, turkey, or turkey leg
0--]]
function EVENT:PlayerStuffed(eAttacker, eStuffedPly, eItem)
	if !IsValid(eStuffedPly) or !IsValid(eAttacker) then return end

	local iCurStuffings = eStuffedPly:GetNW2Int("gmcore.FunRound.StuffedCount", 0)
	eStuffedPly:SetNW2Int("gmcore.FunRound.StuffedCount", iCurStuffings + tFoodItemsStuffCount[eItem])
	iCurStuffings = eStuffedPly:GetNW2Int("gmcore.FunRound.StuffedCount", 0) -- Update to our new count since we just incremented

	eStuffedPly:EmitSound("gmcore/funround/burp.mp3")


	local iFatSize = 1 + iCurStuffings / self.iStuffingToKill * 0.5


	-- Bones make player look fatter
	boneID = eStuffedPly:LookupBone("ValveBiped.Bip01_Spine4")
	scale = Vector(iFatSize, iFatSize, iFatSize)
	eStuffedPly:ManipulateBoneScale(boneID, scale)

	boneID = eStuffedPly:LookupBone("ValveBiped.Bip01_Spine2")
	scale = Vector(iFatSize, iFatSize, iFatSize)
	eStuffedPly:ManipulateBoneScale(boneID, scale)

	boneID = eStuffedPly:LookupBone("ValveBiped.Bip01_Spine")
	scale = Vector(iFatSize, iFatSize, iFatSize)
	eStuffedPly:ManipulateBoneScale(boneID, scale)

	boneID = eStuffedPly:LookupBone("ValveBiped.Bip01_Pelvis")
	scale = Vector(iFatSize, iFatSize, iFatSize)
	eStuffedPly:ManipulateBoneScale(boneID, scale)

	if iCurStuffings >= EVENT.iStuffingToKill then
		self:StuffKill(eAttacker, eStuffedPly)
	end
end

--[[
0* Hook is run in food items for this fun round when a player has reached their "stuff limit" and is about to die
0--]]
function EVENT:StuffKill(eAttacker, eStuffedPly)
	if !IsValid(eStuffedPly) or !IsValid(eAttacker) then return end

	eStuffedPly:EmitSound("gmcore/funround/gobble.mp3")
	eStuffedPly:Kill()

	net.Start("gmcore.FunRound.Turkey.StuffKillConfetti")
	net.WriteEntity(eStuffedPly)
	net.Broadcast()

	if !self.StuffingThisRound[eAttacker:SteamID()] then -- If the player hasn't killed anyone yet
		self.StuffingThisRound[eAttacker:SteamID()] = 1
	end

	self.StuffingThisRound[eAttacker:SteamID()] = self.StuffingThisRound[eAttacker:SteamID()] + 1
end

function EVENT:ComputeRewards()
	timer.Remove("gmcore.FunRound.SpawnFoodItems")

	local plyLastAlive = nil
	local plyMostStuffings = nil
	local iTopStuffings = 0

	for plySteamID, iStuffings in pairs(self.StuffingThisRound) do
		local ply = player.GetBySteamID(plySteamID)
		if !ply or !ply:IsPlayer() then continue end

		local iPoints = iStuffings * self.Rewards.iPerStuffing

		if iStuffings > iTopStuffings then
			plyMostStuffings = ply
			iTopStuffings = iStuffings
		end

		ply:PS_GivePointsBoostable(iPoints)
		rewardMessageToPly(iStuffings .. " Fun Round stuffing explosions", iPoints,  true, ply)
	end

	for _, v in pairs(player.GetAll()) do
		if v:Alive() then
			plyLastAlive = v
		end
	end

	if plyMostStuffings then
		plyMostStuffings:PS_GivePointsBoostable(self.Rewards.iMostStuffings)
		rewardMessageToPly(iTopStuffings .. " | Most amount of stuffings!", self.Rewards.iMostStuffings, true, plyMostStuffings)
	end

	local tToSendWinners = {
		eLastAlive = plyLastAlive or nil,
		eMostKills = plyMostStuffings or nil,
		iKillCount = iTopStuffings or 0
	}

	net.Start("gmcore.FunRounds.SendWinners")
	net.WriteTable(tToSendWinners)
	net.Broadcast()
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

gmcore.FunRounds:RegisterFunRound("Turkey", EVENT)
