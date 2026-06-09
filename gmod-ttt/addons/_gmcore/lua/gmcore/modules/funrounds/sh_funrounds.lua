---@class gmcore
---@field FunRounds gmcore.FunRounds Fun rounds system

---@class gmcore.FunRounds
---@field RegisteredFunRounds table<string, FunRound> Registered fun round instances
---@field IsRoundFun boolean Whether the current round is a fun round
---@field CurrentlyActiveRound string ID of the currently active fun round
---@field Active string[] List of active fun round IDs
gmcore.FunRounds = gmcore.FunRounds or {}

---@type table<string, FunRound>
gmcore.FunRounds.RegisteredFunRounds = gmcore.FunRounds.RegisteredFunRounds or {}
---@type boolean
gmcore.FunRounds.IsRoundFun = false
---@type string
gmcore.FunRounds.CurrentlyActiveRound = ""

---Finds the corpse entity for a player (used for auto-ID on death).
---@param v Player The player to find the corpse for
---@return Entity|false corpse The corpse entity or false if not found
local function findCorpseEntity(v)
	for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
		if ent.uqid == v:UniqueID() and IsValid(ent) then return ent or false end
	end
end

---@class FunRound
---@field Id string Unique identifier for this fun round
---@field Hooks table[] Array of registered hooks: [1]=hook type, [2]=hook identifier
---@field AutoIDBodies? boolean Whether to automatically ID bodies on death
---@field bPointRewards? boolean Whether this fun round awards points
---@field Active? boolean Whether this fun round is active
local m_FunRound = {}

---Takes a hook registered with the event, and adds it to its metatable instance for reference when a fun round is picked.
---@param sHookType string The hook type to register (e.g., "PlayerDeath", "TTTPrepareRound")
---@param fHookCallback? function The function registered to the hook (defaults to self[sHookType])
function m_FunRound:AddHook(sHookType, fHookCallback)
	local sHookName = "gmcore.FunRounds." .. self.Id .. ":" .. sHookType
	fHookCallback = fHookCallback or self[sHookType]

	-- If hook[1] == true, then we already have an existing hook type. Add an incremented number so we can have more than 1 of the same hook
	if self.Hooks then
		for _, hook in ipairs(self.Hooks) do
			if hook[1] == sHookType then
				sHookName = sHookName .. #self.Hooks
			end
		end
	end

	hook.Add(sHookType, sHookName, function(...) return fHookCallback(self, ...) end)

	-- Add hook to metatable instance, so we can loop through and add them when round begins, and remove when the round ends
	self.Hooks = self.Hooks or {}
	table.insert(self.Hooks, { sHookType, sHookName })
end

---Loops through metatable instance and removes all hooks stored in m_FunRound.Hooks, which are defined in m_FunRound:AddHook.
function m_FunRound:ClearHooks()
	if ! self.Hooks then return end

	-- Remove all active hooks
	for _, tHook in pairs(self.Hooks) do
		if ! tHook[1] or ! tHook[2] then
			ErrorNoHalt("[GMCore Fun Rounds] Attempted to remove a hook with a missing hook type or identifier.")
			continue
		end

		hook.Remove(tHook[1], tHook[2])
	end
end

---Called on TTTPrepareRound, which is when a new round begins, but doesn't start.
---This function gets saved as a local instance in each fun round, ran then overwritten since IDK how to save this in just the metatable file.
---@param selfT? any Self reference (legacy parameter)
function m_FunRound:Prepare(selfT)
	gmcore.FunRounds.IsRoundFun = true
	gmcore.FunRounds.CurrentlyActiveRound = self.Id -- Reference index of the currently active fun round

	if SERVER then
		if ! self.Hooks then self.Hooks = {} end

		-- Prevent karma being removed
		hook.Add("TTTKarmaGivePenalty", "gmcore.FunRounds.KarmaLockPenalty", function(ply, penalty, victim)
			return true
		end)
		table.insert(self.Hooks, { "TTTKarmaGivePenalty", "gmcore.FunRounds.KarmaLockPenalty" })

		-- Prevent karma being rewarded
		hook.Add("TTTKarmaGiveReward", "gmcore.FunRounds.KarmaLockReward", function(ply, penalty, victim)
			return false
		end)
		table.insert(self.Hooks, { "TTTKarmaGiveReward", "gmcore.FunRounds.KarmaLockReward" })

		-- Stop people from potentially buying items with console commant 'ttt_order_equipment'
		hook.Add("TTTCanOrderEquipment", "gmcore.FunRounds.PreventEquipmentBuy", function(ply, id, isItem)
			return false
		end)
		table.insert(self.Hooks, { "TTTCanOrderEquipment", "gmcore.FunRounds.PreventEquipmentBuy" })

		if self.AutoIDBodies then
			local sAutoIDHookName = "gmcore.FunRounds.AutoIDBodies:PlayerDeath"

			hook.Add("PlayerDeath", sAutoIDHookName, function(victim, attacker)
				local eBody = findCorpseEntity(victim)
				if ! eBody then return end

				CORPSE.SetFound(eBody, true)
				victim:SetNWBool("body_found", true)
				SendConfirmedTraitors(GetInnocentFilter(false))
				SCORE:HandleBodyFound(victim, victim)
			end)

			table.insert(self.Hooks, { "PlayerDeath", sAutoIDHookName })
		end
	else
		if ! self.Hooks then self.Hooks = {} end

		-- Prevent role shop from being opened during fun round
		hook.Add("TTTEquipmentTabs", "gmcore.FunRounds.RemoveRoleShop", function(dsheet)
			dsheet:GetParent():Remove()
		end)
		table.insert(self.Hooks, { "TTTEquipmentTabs", "gmcore.FunRounds.RemoveRoleShop" })

		-- Prevent T-traps buttons from being draw
		hook.Add("HUDShouldDraw", "gmcore.FunRounds.PreventTTraps", function(name)
			if name == "TTTTButton" then
				return false
			end
		end)
		table.insert(self.Hooks, { "HUDShouldDraw", "gmcore.FunRounds.PreventTTraps" })
	end
end

---Called when a round starts (abstract method - override in fun round implementation).
function m_FunRound:Begin()
end

---Computes and awards points to players (abstract method - override in fun round implementation).
function m_FunRound:ComputeRewards()
end

---Called when a round ends - clears hooks and computes rewards.
function m_FunRound:End()
	gmcore.FunRounds.IsRoundFun = false
	self:ClearHooks()

	-- If we have rewards enabled in the shared file, run how the instance rewards players
	if self.bPointRewards then
		self:ComputeRewards()
	end
end

---Takes a table and shuffles the values into different keys.
---Primarily used for m_FunRound:GetPlayers().
---@param t table The table to shuffle
---@return table shuffled The shuffled table
local function shuffleTable(t)
	local rand = math.random
	assert(t, "shuffleTable() expected a table, got nil")
	local iterations = #t
	local j

	for i = iterations, 2, -1 do
		j = rand(i)
		t[i], t[j] = t[j], t[i]
	end

	return t
end

---Returns all players that are alive so we don't have to keep repeating a for loop, checking if they are spec.
---@param shuffled? boolean Whether to shuffle the player list
---@return Player[] players Array of alive players
function m_FunRound:GetPlayers(shuffled)
	local tPlys = {}

	for _, ply in pairs(player.GetAll()) do
		if ply:IsAlive() then
			table.insert(tPlys, ply)
		end
	end

	if shuffled then
		tPlys = shuffleTable(tPlys)
	end

	return tPlys
end

---Registers a new fun round instance.
---@param sEventId string Unique identifier for this fun round
---@param iTable FunRound Table containing fun round configuration and methods
function gmcore.FunRounds:RegisterFunRound(sEventId, iTable)
	iTable.Id = sEventId
	iTable.__index = iTable
	setmetatable(iTable, m_FunRound)

	if iTable.Active and ! table.HasValue(gmcore.FunRounds.Active, sEventId) then
		table.insert(gmcore.FunRounds.Active, sEventId)
	end

	gmcore.FunRounds.RegisteredFunRounds[sEventId] = iTable
	gmcore.DebugPrint("Registered FR " .. sEventId)
end

m_FunRound.__index = m_FunRound

AddCSLuaFile("sh_funrounds_config.lua")
include("sh_funrounds_config.lua")
