
include("sv_rtv.lua")

util.AddNetworkString("gmcore.MapVote.StartVoting")
util.AddNetworkString("gmcore.MapVote.MapVoteSelection")
util.AddNetworkString("gmcore.MapVote.UpdateVotingTable") -- Not used in previous code
--util.AddNetworkString("gmcore.MapVote.GetMapVotesTable") -- Not used in previous code
--util.AddNetworkString("gmcore.MapVote.GetMapVotes")  -- Not used in previous code
util.AddNetworkString("gmcore.MapVote.SendWinningMap")
util.AddNetworkString("gmcore.MapVote.PhaseChangeNotice")
gmcore.MapVote = {}

---@type {totalVotes: integer, mapList: table<string, {totalVotes: integer, voters: table<string, table>, name: string, order: integer}>}
-- DO NOT TOUCH THIS! This is filled when a mapvote starts.
gmcore.MapVote.voteList = {
	["totalVotes"] = 0,
	["mapList"] = {}
}

---@type boolean
gmcore.MapVote.isVoting = false
---@type number Hidden phase duration in seconds
gmcore.MapVote.hiddenTime = 10
---@type boolean
gmcore.MapVote.hideVotes = true
---@type number?
gmcore.MapVote.voteTimeBegin = nil
---@type number Vote duration in seconds
gmcore.MapVote.voteTime = 20
---@type integer
gmcore.MapVote.MaxMapsForVote = 26
---@type integer How many map changes a map is locked out for
gmcore.MapVote.MapCooldown = 5
---@type integer Number of maps to keep after culling
gmcore.MapVote.cullThreshold = 9
---@type string[]
gmcore.MapVote.mapList = {}
---@type string[]
gmcore.MapVote.lockedMaps = {}

---Gets the voting multiplier of a player based on their store rank.
---@param ply Player The player whose vote multiplier to retrieve
---@return integer? multiplier The player's vote multiplier from their store rank, or nil if invalid
function gmcore.MapVote:GetVoteMultiplier(ply)
	if not IsValid(ply) then return end
	local plyStoreRank = ply:GetStoreRank()

	if plyStoreRank == 0 then
		return 1
	else
		return gmcore.StoreRank.Ranks[plyStoreRank].vcount
	end
end

---Reads JSON rotation list and filters maps by current player population.
---@return string[] maps Maps from the rotation list matching the current player count
local function filterMapsByPopulation()
	local mapRotationList = {}
	local resultList = {}

	local rotationFileName = (gmcore.MapRotationFile and file.Exists("gmcore/mapvote/" .. gmcore.MapRotationFile, "DATA")) and gmcore.MapRotationFile or "rotation_list.json"
	local rotationFilePath = "gmcore/mapvote/" .. rotationFileName

	if file.Exists(rotationFilePath, "DATA") then
		mapRotationList = util.JSONToTable(file.Read(rotationFilePath, "DATA"))
		local playerCount = #player.GetAll()

		for k, v in pairs(mapRotationList) do
			if v["max"] == 0 then
				if playerCount >= v["min"] then
					table.insert(resultList, v["map"])
				end
			else
				if playerCount >= v["min"] and playerCount <= v["max"] then
					table.insert(resultList, v["map"])
				end
			end
		end

	else
		gmcore.print("[MapVote] ERROR Attempted to load non-existant file at path: " .. rotationFilePath)

		file.CreateDir("gmcore/mapvote")
		file.Write(rotationFilePath, util.TableToJSON(mapRotationList))
	end

	return resultList
end

---Returns list of locked maps from file.
---@return string[] lockedMaps Map names currently locked out of rotation
local function getLockedMaps()
	local lockedMaps = {}

	if file.Exists("gmcore/lockedmaps.json", "DATA") then
		lockedMaps = util.JSONToTable(file.Read("gmcore/lockedmaps.json", "DATA"))
	else
		if not file.Exists("gmcore/", "DATA") then
			file.CreateDir("gmcore")
		end

		file.Write("gmcore/lockedmaps.json", "{}")
	end

	return lockedMaps
end

---Locks a map by entering it into the lockedmaps.json file.
---@param mapName string The name of the map to lock from rotation
local function lockMap(mapName)
	if mapName == "random" then return end
	-- Remove from active rotation for a certain amount of map changes.
	table.insert(gmcore.MapVote.lockedMaps, mapName) -- Should be O(1) look-ups when done like this I think.
	file.Write("gmcore/lockedmaps.json", util.TableToJSON(gmcore.MapVote.lockedMaps)) -- Update the file

	return
end

---Randomly selects the first non-locked map from the map list.
---@return string mapName A randomly selected map that is not currently locked
local function getRandomMap()
	--Return first instance of non-locked map.
	for k, v in RandomPairs(gmcore.MapVote.mapList) do
		if not table.HasValue(gmcore.MapVote.lockedMaps, v) then return v end
	end
	--If the for loop somehow fails.

	return gmcore.MapVote.mapList[math.random(table.Count(gmcore.MapVote.mapList))]
end

---Networks vote table data to all clients (skips during hidden phase).
local function updateVoteTable()
	if gmcore.MapVote.hideVotes then return end
	net.Start("gmcore.MapVote.UpdateVotingTable")
	net.WriteTable(gmcore.MapVote.voteList)
	net.Broadcast()
end

---Reveals votes to players (ends hidden phase).
local function revealVotes()
	gmcore.MapVote.hideVotes = false
	updateVoteTable()
end

---Culls the bottom maps with the least votes, keeping only `cullThreshold` maps.
local function cullMaps()
	for mapName, mapData in SortedPairsByMemberValue(gmcore.MapVote.voteList.mapList, "totalVotes", false) do
		if table.Count(gmcore.MapVote.voteList.mapList) <= gmcore.MapVote.cullThreshold then break end -- We want to remove so that only cullThreshold amount of maps remain.
		if mapData.name == "Random" then continue end -- Random choice is immune to removal.
		-- TODO: Add a net call or something to notify users if their choice of map was culled.
		gmcore.MapVote.voteList.mapList[mapName] = nil -- Perform the removal.
	end
end

---Stops receiving votes, calculates the winning map, and changes level.
local function endMapVote()
	local maxVotes = 0
	local bestMapID = nil

	for mapName, mapData in pairs(gmcore.MapVote.voteList.mapList) do
		if mapData.totalVotes > maxVotes then
			maxVotes = mapData.totalVotes
			bestMapID = mapName
		end
	end

	if bestMapID == nil then
		bestMapID = "random"
	end

	--Inform all clients of the winning map.
	net.Start("gmcore.MapVote.SendWinningMap")
	net.WriteString(bestMapID)
	net.Broadcast()

	if maxVotes == 0 or bestMapID == "random" then
		bestMapID = getRandomMap()
	end

	if table.Count(gmcore.MapVote.lockedMaps) >= gmcore.MapVote.MapCooldown then
		table.remove(gmcore.MapVote.lockedMaps, 1)
	end

	lockMap(bestMapID) -- Lock the map that won
	gmcore.RTV.updateRTVLock()

	-- Migrated this since I don't want to interfere with Crash monitoring protocol
	timer.Simple(3, function()
		CrashMonitor_onMapChange()
		RunConsoleCommand("ChangeLevel", bestMapID)

		timer.Simple(5, function()
			gmcore.print("[MapVote] ERROR attempt to changelevel to " .. bestMapID)
			RunConsoleCommand("ChangeLevel", "ttt_innocentmotel_gl_v6")
		end)
	end)
end

---Randomly picks maps from the maplist, adds them to the voting list, and broadcasts to players.
function gmcore.MapVote.initializeMapVote()
	gmcore.MapVote.mapList = filterMapsByPopulation()
	gmcore.MapVote.isVoting = true
	gmcore.MapVote.voteTimeBegin = CurTime()

	-- mapList[1] = some map name/value
	timer.Simple(16.8, function()
		MuteForRestart(false)
	end)

	local iterationNum = 1 -- Start at 1 since table indexes start at 1

	for iMapKey, iMapInfo in RandomPairs(gmcore.MapVote.mapList) do
		if iterationNum == gmcore.MapVote.MaxMapsForVote then break end

		if iterationNum == 13 then
			gmcore.MapVote.voteList.mapList["random"] = {
				["totalVotes"] = 0,
				["voters"] = {},
				["name"] = "Random",
				["order"] = iterationNum
			}

			iterationNum = iterationNum + 1
			continue
		end

		if not table.HasValue(gmcore.MapVote.lockedMaps, iMapInfo) then
			gmcore.MapVote.voteList.mapList[iMapInfo] = {
				["totalVotes"] = 0,
				["voters"] = {},
				["name"] = iMapInfo,
				["order"] = iterationNum
			}

			iterationNum = iterationNum + 1
		end
	end

	timer.Simple(gmcore.MapVote.hiddenTime, function()
		cullMaps()
		revealVotes()
		net.Start("gmcore.MapVote.PhaseChangeNotice")
		net.Broadcast()
		updateVoteTable()
	end)

	timer.Simple(gmcore.MapVote.voteTime, endMapVote)
	-- Network timer and voting list to all clients.
	net.Start("gmcore.MapVote.StartVoting")
	net.WriteFloat(gmcore.MapVote.voteTimeBegin)
	net.WriteTable(gmcore.MapVote.voteList)
	net.Broadcast()
end

---Removes a player's vote from a previously voted map if found.
---@param ply Player The player whose vote should be removed
local function removeVoteByPlayer(ply)
	if not gmcore.MapVote.isVoting then return end
	local plyVotePower = gmcore.MapVote:GetVoteMultiplier(ply)

	for k, v in pairs(gmcore.MapVote.voteList.mapList) do
		if v.voters[ply:SteamID64()] then
			local prevMapVote = gmcore.MapVote.voteList.mapList[k]
			--table.remove(v.voters, ply:SteamID64()) --Using AccountID as key for easy removal.
			v.voters[ply:SteamID64()] = nil
			prevMapVote.totalVotes = prevMapVote.totalVotes - plyVotePower
			gmcore.MapVote.voteList.totalVotes = gmcore.MapVote.voteList.totalVotes - plyVotePower
			break
		end
	end

	updateVoteTable()
end

---Sends current vote state (vote begin time and vote list) to player.
---@param ply Player Player to sync vote state to
local function checkMapVoteStatus(ply)
	if not gmcore.MapVote.isVoting or not gmcore.MapVote.voteTimeBegin then return end

	net.Start("gmcore.MapVote.StartVoting")
	net.WriteFloat(gmcore.MapVote.voteTimeBegin)
	net.WriteTable(gmcore.MapVote.voteList)
	net.Send(ply)
end

---Net receive handler. Removes player's previous vote and adds their vote for the selected map.
---@param _ number Net message length (unused)
---@param ply Player The player who sent the vote
local function updateVoteTally(_, ply)
	if not gmcore.MapVote.isVoting then return end
	if not gmcore.MapVote.voteList or not gmcore.MapVote.voteList.mapList then return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local mapName = net.ReadString()
	if not isstring(mapName) or mapName == "" then return end

	local plyVoteEnt = gmcore.MapVote.voteList.mapList[mapName]

	if not plyVoteEnt then
		-- Client may have older version of vote table and didn't get the pruned
		-- map list. Send resync to client
		checkMapVoteStatus(ply)

		return
	end

	plyVoteEnt.voters = plyVoteEnt.voters or {}

	local plyVotePower = gmcore.MapVote:GetVoteMultiplier(ply) or 1
	if plyVoteEnt.voters[ply:SteamID64()] then return end -- Player already voted for this map

	--Check if player had voted for a map previously
	removeVoteByPlayer(ply)

	plyVoteEnt.voters[ply:SteamID64()] = {}
	table.insert(plyVoteEnt.voters[ply:SteamID64()], plyVotePower)
	plyVoteEnt.totalVotes = plyVoteEnt.totalVotes + plyVotePower
	gmcore.MapVote.voteList.totalVotes = gmcore.MapVote.voteList.totalVotes + plyVotePower

	updateVoteTable()
end

net.Receive("gmcore.MapVote.MapVoteSelection", updateVoteTally)

-- Debug command copied over
concommand.Add("gmcore_checkmapconfig", function()
	local availMaps = file.Find("maps/*.bsp", "GAME")

	for _, map in ipairs(gmcore.MapVote.mapList) do
		if not table.HasValue(availMaps, map .. ".bsp") then
			print("[WARNING] " .. map .. " file does not exist on server")
		end

		if not mapNameToWorkshopId[map] then
			print("[WARNING] " .. map .. " is not in workshop download")
		end
	end
end)

gmcore.MapVote.lockedMaps = getLockedMaps()
hook.Add("PlayerInitialSpawn", "gmcore.MapVote.CheckForExistingMapvote", checkMapVoteStatus)
hook.Add("PlayerDisconnected", "gmcore.MapVote.DisconnectRemoveVote", removeVoteByPlayer)

-- hook.Add("TTTEndRound", "gmcore.MapVote.CheckForMapVote", CheckForMapSwitch)
-- Override default TTT mapvote CheckForMapSwitch
hook.Add("Initialize", "gmcore.MapVote.OverrideDefaultCheckForMapSwitch", function()
	function CheckForMapSwitch()
		local timeLeft = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
		local roundsLeft = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
		SetGlobalInt("ttt_rounds_left", roundsLeft)

		if roundsLeft <= 0 or timeLeft <= 0 then
			LANG.Msg("limit_vote")
			timer.Stop("end2prep")
			gmcore.MapVote.isVoting = true

			timer.Simple(3, function()
				gmcore.MapVote.initializeMapVote()
			end)
		end
	end
end)

gmcore.print("MapVote config loaded")
