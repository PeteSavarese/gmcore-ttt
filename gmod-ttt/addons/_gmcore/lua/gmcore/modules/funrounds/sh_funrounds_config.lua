
---Adds a Lua file to clients (AddCSLuaFile on server, include on client).
---@param fil string Lua file path to add for clients
local function AddClient(fil)
	if SERVER then AddCSLuaFile(fil) end
	if CLIENT then include(fil) end
end

---Includes a Lua file on server only.
---@param fil string Lua file path to include on the server
local function AddServer(fil)
	if SERVER then include(fil) end
end

---Includes a Lua file on both server and client.
---@param fil string Lua file path to include on both server and client
local function AddShared(fil)
	AddServer(fil)
	AddClient(fil)
end

---@class gmcore.FunRoundsConfig
---@field bOverrideForDebug boolean Sets 1st round to be 100% of fun round, and the defined fun round below
---@field sOverrideRound string Fun round ID used when debug override is enabled
---@field fPercOfChance number Percentage chance per eligible round
---@field mapIntervalMin number Minimum maps needed before a fun round is allowed
---@field mapIntervalMax number Maximum maps needed before a fun round is allowed
---@field bCheckOnMapStart boolean If true, pick on mapchange; otherwise roll at round end
---@type gmcore.FunRoundsConfig
gmcore.FunRounds.Config = {
	bOverrideForDebug = false, -- Sets 1st round to be 100% of fun round, and the defined fun round below
	sOverrideRound = "Dodgeball",
	fPercOfChance = 8, -- 8% * 6 rounds = ~50% per map since bCheckOnMapStart is false
	mapIntervalMin = 1,	-- Minimum Maps needed to load before fun round is allowed.
	mapIntervalMax = 3,	-- Max of the range.
	bCheckOnMapStart = true, -- If true, a fun round is picked on mapchange. If not, a random check with the percentage defined above is performed on round end. Still only 1 fr per map
}

---@type string[]
gmcore.FunRounds.Active = {}

---@type table<string, boolean>
gmcore.FunRounds.DLogs_disabled = {}
gmcore.FunRounds.DLogs_disabled["oitc"] = true
gmcore.FunRounds.DLogs_disabled["gungame"] = true
gmcore.FunRounds.DLogs_disabled["Deathmatch"] = true
gmcore.FunRounds.DLogs_disabled["flyingscouts"] = true

local fol = "gmcore/modules/funrounds/rounds/"
local weapons = "gmcore/modules/funrounds/weapons/"
local _, folders = file.Find(fol .. "*", "LUA")


-- TODO: Organize this nice and combine weapon inclusion into round inclusion. Maybe 1 function that checks for which we are including?
if SERVER then
	for _, folder in SortedPairs(folders, true) do
		for _, File in SortedPairs(file.Find(fol .. folder .. "/sh_*.lua", "LUA"), true) do
			AddCSLuaFile(fol .. folder .. "/" .. File)
			include(fol .. folder .. "/" .. File)
		end

		for _, File in SortedPairs(file.Find(fol .. folder .. "/sv_*.lua", "LUA"), true) do
			include(fol .. folder .. "/" .. File)
		end

		for _, File in SortedPairs(file.Find(fol .. folder .. "/cl_*.lua", "LUA"), true) do
			AddCSLuaFile(fol .. folder .. "/" .. File)
		end
	end

	-- Include weapons
	for _, File in SortedPairs(file.Find(weapons .. "/*.lua", "LUA"), true) do -- Add all files as shared. No weapon file is strictly server or client.
		AddCSLuaFile(weapons .. "/" .. File)
		include(weapons .. "/" .. File)
	end
else
	local root = "gmcore/modules/funrounds/rounds/"
	weapons = "gmcore/modules/funrounds/weapons/"
	_, folders = file.Find(fol .. "*", "LUA")

	for _, folder in SortedPairs(folders, true) do
		for _, File in SortedPairs(file.Find(root .. folder .. "/sh_*.lua", "LUA"), true) do
			include(root .. folder .. "/" .. File)
		end

		for _, File in SortedPairs(file.Find(root .. folder .. "/cl_*.lua", "LUA"), true) do
			include(root .. folder .. "/" .. File)
		end
	end

	-- Include weapons
	for _, File in SortedPairs(file.Find(weapons .. "/*.lua", "LUA"), true) do
		include(weapons .. "/" .. File)
	end
end
