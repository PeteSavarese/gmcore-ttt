--[[
	TTT Extension for Pointshop by Peter Savarese
	Description: Awards points to players for playing gamemode (Killing traitors, innocents as traitor, etc.) and
	overrides hooks for model color setting
]]

util.AddNetworkString("gmcore.PointShop.TTTRewardReceive")

---@type table<string, number> Point rewards per kill/event type
local rewards = {
	["traitor_kill_innocent"] = 10,
	["traitor_kill_detective"] = 30,
	["detective_kill_traitor"] = 30,
	["innocent_kill_traitor"] = 40,
	["dna_bonus"] = 10,
	["headshot_bonus"] = 10
}

---@type table[] Queued rewards applied at round end to prevent ghosting
local roundEndPoints = {} -- Used to prevent ghosting I.E. When an innocent kills a traitor, they won't get their points awared until round end.

---Sends a TTT reward notification to a player.
---@param message string Reward description
---@param points number Points awarded
---@param small boolean Whether to show as a small notification
---@param ply Player The player to send the reward notification to
function rewardMessageToPly(message, points, small, ply)
	net.Start("gmcore.PointShop.TTTRewardReceive")
	net.WriteString(message)
	net.WriteInt(points, 16)
	net.WriteBool(small)
	net.Send(ply)
end

--[[
	Description: Adds player and rewarded points to table to prevent ghosting. Table is looped through on round end and cleared
]]
---Queues a point reward to be applied at round end (prevents ghosting).
---@param message string Reward description
---@param points number Points to award
---@param small boolean Whether to show as a small notification
---@param ply Player The player to award the delayed reward to
local function addDelayedRewards(message, points, small, ply)
	table.insert(roundEndPoints, {
		points = points,
		message = message,
		small = small,
		ply = ply
	})
end

---Applies all queued round-end rewards and clears the queue.
local function applyDelayedRewards()
	for k, v in ipairs(roundEndPoints) do
		v.ply:PS_GivePointsBoostable(v.points)
		rewardMessageToPly(v.message, v.points,  v.small, v.ply)
	end

	roundEndPoints = {}
end

hook.Add("ScalePlayerDamage", "SetDeathGroup", function(ply, hit_group, dmg_info)
	ply.DeathGroup = hit_group
end)

hook.Add("PlayerDeath", "gmcore.PointShop.TTTRewards", function(victim, inflictor, attacker)
	if gmcore.FunRounds.IsRoundFun then return end

	if victim == attacker then return end
	if (attacker.IsGhost and attacker:IsGhost()) then return end --SpecDM Support.

	if !victim.GetRole then return end
	local victimRole = victim:GetRole()

	if !attacker.GetRole then return end
	local attackerRole = attacker:GetRole()

	if attackerRole == ROLE_TRAITOR then -- If killer is trator, begin rewards
		if victimRole == ROLE_INNOCENT then
			if victim.DeathGroup == HITGROUP_HEAD then
				attacker:PS_GivePointsBoostable(rewards["headshot_bonus"])
				rewardMessageToPly("Headshot bonus", rewards["headshot_bonus"], true, attacker)
			end

			attacker:PS_GivePointsBoostable(rewards["traitor_kill_innocent"])
			rewardMessageToPly("Killed Innocent", rewards["traitor_kill_innocent"], false, attacker)
		elseif victimRole == ROLE_DETECTIVE then
			if victim.DeathGroup == HITGROUP_HEAD then
				attacker:PS_GivePointsBoostable(rewards["headshot_bonus"])
				rewardMessageToPly("Headshot bonus", rewards["headshot_bonus"], true, attacker)
			end

			attacker:PS_GivePointsBoostable(rewards["traitor_kill_detective"])
			rewardMessageToPly("Killed Detective", rewards["traitor_kill_detective"], false, attacker)
		end
	elseif attackerRole == ROLE_DETECTIVE then -- If killer is detective, begin rewards
		if victimRole == ROLE_TRAITOR then
			if victim.DeathGroup == HITGROUP_HEAD then
				attacker:PS_GivePointsBoostable(rewards["headshot_bonus"])
				addDelayedRewards("Headshot bonus", rewards["headshot_bonus"], true, attacker)
			end

			if attacker.hasDnaOn and attacker.hasDnaOn[victim] then
				addDelayedRewards("DNA Bonus", rewards["dna_bonus"], true, attacker)
			end

			addDelayedRewards("Killed Traitor", rewards["detective_kill_traitor"], false, attacker)
		end
	elseif attackerRole == ROLE_INNOCENT then -- If killer is innocent, begin rewards
		if victimRole == ROLE_TRAITOR then
			if victim.DeathGroup == HITGROUP_HEAD then
				attacker:PS_GivePointsBoostable(rewards["headshot_bonus"])
				addDelayedRewards("Headshot bonus", rewards["headshot_bonus"], true, attacker)
			end

			if attacker.hasDnaOn and attacker.hasDnaOn[victim] then
				addDelayedRewards("DNA Bonus", rewards["dna_bonus"], true, attacker)
			end

			addDelayedRewards("Killed Traitor", rewards["innocent_kill_traitor"], false, attacker)
		end
	end
end)

hook.Add("TTTFoundDNA", "gmcore.PointShop.DNABonusTracker", function(ply, dnaOwner, ent)
	ply.hasDnaOn = ply.hasDnaOn or {}

	ply.hasDnaOn[dnaOwner] = true
end)

hook.Add("TTTEndRound", "gmcore.PointShop.EndRoundRewards", function(result)
	applyDelayedRewards()

	-- Clear DNA retrievals
	for _, ply in pairs(player.GetAll()) do
		ply.hasDnaOn = {}
	end
end)

--[[
	Begin event kill tracking
--]]
---Increments a persistent tracking value for event-based skin requirements.
---@param ply Player The player whose tracking data to increment
---@param key string PData key to increment
---@param iIncrementBy number Amount to add
local function incrementEventTrackingData(ply, key, iIncrementBy)
	ply:GMCoreGetPData(key, 0, function(iCurValue)
		local iNewValue = iCurValue + iIncrementBy
		ply:GMCoreSetPData(key, iNewValue, function()
			ply:SetNWInt(key, iNewValue)
		end)
	end)
end

--[[
	Key is weapon class, value is the PData that is to be incremented
0--]]
---@type table<string, string> Maps weapon class to PData key for kill tracking
tWeaponToIncrement = {
	["weapon_ttt_python"] = "christmas2025_python_kills",
	["weapon_ttt_famas"] = "christmas2025_famas_kills",
	["weapon_ttt_m24"] = "christmas2025_m24_kills",
	["weapon_ttt_m4a4"] = "christmas2025_m4a4_kills",
}

---@type table<string, string> Maps weapon class to PData key for headshot tracking
tWeaponToIncrementHeadshots = {
	-- ["weapon_ttt_intervention"] = "fall2022_intervention_headshots",
}

hook.Add("OnGamemodeLoaded", "CheckSkinsforRequirements", function()
	for _, v in pairs(PS.Items) do
		if not v or v.Category ~= "Skins" then continue end
		if not v.Event or not PS.SkinEventInfo or not PS.SkinEventInfo[v.Event] then continue end
		if not v.Requirements or #v.Requirements == 0 then continue end

		local info = PS.SkinEventInfo[v.Event]
		local beginTime = tonumber(info.begin) or 0
		local endTime = tonumber(info["end"]) or 0
		local now = os.time()
		if beginTime > 0 and now < beginTime then continue end
		if endTime > 0 and now > endTime then continue end

		for _, req in ipairs(v.Requirements) do
			if req.type == "weapon_kills" and req.weapon and req.key then
				tWeaponToIncrement[req.weapon] = req.key
			elseif req.type == "weapon_headshots" and req.weapon and req.key then
				tWeaponToIncrementHeadshots[req.weapon] = req.key
			end
		end
	end
end)

hook.Add("PlayerInitialSpawn", "gmcore.PointShop.SyncSkinTracking", function(ply)
	for _, data in pairs(tWeaponToIncrement) do
		ply:GMCoreGetPData(data, 0, function(curStats)
			if not IsValid(ply) then return end

			ply:SetNWInt(data, curStats)
		end)
	end

	for _, data in pairs(tWeaponToIncrementHeadshots) do
		ply:GMCoreGetPData(data, 0, function(curStats)
			if not IsValid(ply) then return end

			ply:SetNWInt(data, curStats)
		end)
	end
end)

hook.Add("PlayerDeath", "gmcore.PointShop.SkinTracking", function(victim, inflictor, attacker)
	if gmcore.FunRounds.IsRoundFun then return end

	if victim == attacker then return end
	if !IsValid(attacker) or !IsValid(victim) then return end
	if attacker.IsGhost and attacker:IsGhost() then return end

	if !victim.GetRole then return end
	local victimRole = victim:GetRole()

	if !attacker.GetRole then return end
	local attackerRole = attacker:GetRole()

	if !attacker:Alive() then return end
	if !inflictor then return end

	if inflictor:IsPlayer() then
		inflictor = inflictor:GetActiveWeapon()
	end
	local weapon = inflictor:GetClass()

	if (attackerRole == ROLE_INNOCENT or attackerRole == ROLE_DETECTIVE) and victimRole == ROLE_TRAITOR then
		-- print("Inno/DT on T kill")
		if tWeaponToIncrement[weapon] then
			incrementEventTrackingData(attacker, tWeaponToIncrement[weapon], 1)
			-- print("Incremented", tWeaponToIncrement[weapon])
		end

		if tWeaponToIncrementHeadshots[weapon] and victim.DeathGroup == HITGROUP_HEAD then
		-- print("Incremented", tWeaponToIncrement[weapon])
			incrementEventTrackingData(attacker, tWeaponToIncrementHeadshots[weapon], 1)
		end
	elseif attackerRole == ROLE_TRAITOR and (victimRole == ROLE_INNOCENT or victimRole == ROLE_DETECTIVE) then
		--print("T on Inno/DT kill")

		if tWeaponToIncrement[weapon] then
			incrementEventTrackingData(attacker, tWeaponToIncrement[weapon], 1)
			-- print("Incremented", tWeaponToIncrement[weapon])
		end

		if tWeaponToIncrementHeadshots[weapon] and victim.DeathGroup == HITGROUP_HEAD then
			incrementEventTrackingData(attacker, tWeaponToIncrementHeadshots[weapon], 1)
			-- print("Incremented", tWeaponToIncrement[weapon])
		end
	end
end)

--[[
	Prevent TTT base gamemode from resetting a player's color if they have a custom color for their playermodel
]]
hook.Add("TTTPlayerSetColor", "gmcore.Pointshop.PreventColorOverride", function(ply)
	for k, v in pairs(ply.PS_Items) do
		if !v.Equipped then continue end

		local ITEM = PS.Items[k]
		if ITEM == nil then continue end

		if ITEM.Category != "Playermodels" then continue end
		if !ITEM then return end
		if !ply.PS_Items[k].Modifiers then return end

		ITEM:OnEquip(ply, ply.PS_Items[k].Modifiers) -- Have their player model color set

		return false
	end
end)
