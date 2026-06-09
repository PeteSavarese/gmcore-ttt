---@class gmcore
---@field PlayerUpdateServerLastSeen fun(steamId64: string) Update player last seen timestamp
---@field UpdatePlayerData fun(ply: Player, currentData?: table) Update player name/IP history
---@field GetLatestPlayerDataAndRerun fun(ply: Player) Fetch latest player data then rerun UpdatePlayerData

---@class Player
local pMeta = FindMetaTable("Player")

---Whether the player is a ghost (always false, stub)
---@return boolean isGhost Always false, ghost mode is not implemented
function pMeta:IsGhost() return false end

---Returns amount of slaynr rounds currently active. If a player has 1 slay at round start, it will return 0
---before slaying ply and de-incrementing
---@return integer
function pMeta:GetSlayCount()
	local sid = self:SteamID()
	local existingSlays = tonumber(sql.QueryValue(string.format("SELECT slays FROM gmcore_slays WHERE steamid = %s LIMIT 1", sql.SQLStr(sid))))
	if not existingSlays then return 0 end

	return existingSlays
end

---Fetches player's total playtime in minutes from the database
---and sets it as NW2Int "gmcore.PlayTimeMins"
function pMeta:SyncMinutesPlayed()
	if not IsValid(self) then return end

	if self:IsBot() then return end

	local ply = self

	local fetchMinsPlayed = gmcore.Database:prepare("SELECT minutes FROM players_stats WHERE steamid64 = ?")

	fetchMinsPlayed.onSuccess = function(s, data)
		if not IsValid(ply) then return end

		local playtime = data[1] and data[1]["minutes"] or 0
		ply:SetNW2Int("gmcore.PlayTimeMins", playtime)
	end

	function fetchMinsPlayed:onError(err)
		gmcore.print("pMeta:GetPlayTime MySQL error:" .. err)
	end

	fetchMinsPlayed:setString(1, ply:SteamID64())
	fetchMinsPlayed:start()
end

---Updates player's last seen timestamp on this server.
---Wrapper for `gmcore.PlayerUpdateServerLastSeen` since meta can't be called after disconnect.
function pMeta:UpdateServerLastSeen()
	if not IsValid(self) then gmcore.print("[Player Controller] Attempted to update last seen for invalid player") return end

	gmcore.PlayerUpdateServerLastSeen(self:SteamID64())
end

gmcore.Database.CurrentlyRunningPData = false -- Set to true when GMCoreGetAllPData query is called, false when query finishes
gmcore.Database.BackLogSetPData = {}          -- Table that stores pdata queries to run if GMCoreGetAllPData while a previous query hasn't completed

---Fetches entire persistent data block from MySQL
---@param fPostRunFunc fun(data: table) Callback with the parsed pdata table
function pMeta:GMCoreGetAllPData(fPostRunFunc)
	if not IsValid(self) then return end

	local fetchPData = gmcore.Database:prepare("SELECT pdata FROM player_data WHERE steamid64 = ?")
	local returnedData = nil

	function fetchPData:onSuccess(data)
		if not data or not data[1] or not data[1]["pdata"] then return end

		returnedData = data[1]["pdata"]

		fPostRunFunc(util.JSONToTable(returnedData))
	end

	fetchPData:setString(1, self:SteamID64())
	fetchPData:start()
end

---Fetches a persistent data value by key from MySQL
---@param name string Unique key of the data
---@param default any Default value if key doesn't exist
---@param fPostRunFunc fun(value: any) Callback with the fetched value
function pMeta:GMCoreGetPData(name, default, fPostRunFunc)
	local fetchPData = gmcore.Database:prepare("SELECT pdata FROM player_data WHERE steamid64 = ?")
	local returnedData = nil

	function fetchPData:onSuccess(data)
		if not data or not data[1] or not data[1]["pdata"] then return end

		returnedData = util.JSONToTable(data[1]["pdata"])
		if returnedData[name] == nil then return fPostRunFunc(default) end -- Key doesn't exist

		fPostRunFunc(returnedData[name])
	end

	fetchPData:setString(1, self:SteamID64())
	fetchPData:start()
end

---Sets persistent data with a key. Queues if another GMCoreGetAllPData is running.
---@param name string Unique key of the data
---@param value any Value to store
---@param fPostRunFunc? fun(success: boolean) Optional callback after save
function pMeta:GMCoreSetPData(name, value, fPostRunFunc)
	if gmcore.Database.CurrentlyRunningPData then
		-- Query is currently running which hasn't completed. Put into backlog to run after query finishes
		table.insert(gmcore.Database.BackLogSetPData, { name, value, fPostRunFunc, self })

		return
	end

	gmcore.Database.CurrentlyRunningPData = true

	self:GMCoreGetAllPData(function(existingPData)
		existingPData[name] = value

		local setPDataQuery = gmcore.Database:prepare("UPDATE player_data SET pdata = ? WHERE steamid64 = ?")

		function setPDataQuery:onSuccess(data)
			if fPostRunFunc and isfunction(fPostRunFunc) then
				fPostRunFunc(successSetData)
			end

			gmcore.Database.CurrentlyRunningPData = false -- Set to false since callback has finished running and execute backlogged queries

			if #gmcore.Database.BackLogSetPData <= 0 then return end

			for queryId, query in ipairs(gmcore.Database.BackLogSetPData) do
				-- Store in local var then delete from global table before running GMCoreGetAllPData so we don't inf loop
				local tempStorageQuery = { name = query[1], value = query[2], fPostRunFunc = query[3], ply = query[4] }
				table.remove(gmcore.Database.BackLogSetPData, queryId)

				if IsValid(tempStorageQuery["ply"]) then
					tempStorageQuery["ply"]:GMCoreGetAllPData(tempStorageQuery["name"], tempStorageQuery["value"],
						tempStorageQuery["fPostRunFunc"])
				end
			end
		end

		function setPDataQuery:onError(err)
			print("[GMCore Player Controller] Error updating persistent data: " .. err)
		end

		setPDataQuery:setString(1, util.TableToJSON(existingPData))
		setPDataQuery:setString(2, self:SteamID64())
		setPDataQuery:start()
	end)
end

---Updates player's last seen timestamp on current serverid
---@param steamId64 string Player's SteamID64
function gmcore.PlayerUpdateServerLastSeen(steamId64)
	if not steamId64 then return end

	local updateServerLastSeen = gmcore.Database:prepare([[
															UPDATE players_stats
															SET last_seen_on = NOW()
															WHERE steamid64 = ?
															AND serverid = ?]])


	updateServerLastSeen.onSuccess = function(s, data)
		gmcore.DebugPrint("[Player Controller] Updated server last seen for player " .. steamId64 .. " on server " .. gmcore.ServerId)
	end

	updateServerLastSeen.onError = function(s, err)
		gmcore.print("pMeta:UpdateServerLastSeen MySQL error:" .. err)
	end
	updateServerLastSeen:setString(1, steamId64)
	updateServerLastSeen:setNumber(2, gmcore.ServerId)
	updateServerLastSeen:start()
end

---Fetch the latest player_data row, then call UpdatePlayerData with it. Workaround for async
---SQL not blocking code execution.
---Waaaaaaaaaay hacky fix because UpdatePlayerData would continue to run code after !currentData if check before the
---query completes. This fetch the latest data then reruns UpdatePlayerData with currentData param supplied.
---@param ply Player Player to update
function gmcore.GetLatestPlayerDataAndRerun(ply)
	local sql = gmcore.Database:prepare("SELECT * FROM player_data WHERE steamid64 = ?")

	function sql:onSuccess(data)
		if data then
			gmcore.UpdatePlayerData(ply, data[1])
		end
	end

	sql:setString(1, ply:SteamID64())
	sql:start()
end

---Updates a player's name, name history, IP, and IP history for current serverid.
---If currentData is nil, fetches it from DB first then re-calls itself.
---@param ply Player Player to update
---@param currentData? table Existing player_data row (fetched if nil)
function gmcore.UpdatePlayerData(ply, currentData)
	if not IsValid(ply) then return end

	currentData = currentData or nil

	if not currentData then
		gmcore.DebugPrint("[Player Controller] No currentData provded. Fetching latest")
		currentData = gmcore.GetLatestPlayerDataAndRerun(ply)

		return -- I hate Lua. Maybe I should just use coroutines. The code below will continue to run before the SQL query is completed. Have it fetch the latest data then rerun this data with currentData param supplied
	end

	-- Begin name history
	local sPreviousNames = currentData["previous_names"] -- JSON string

	if sPreviousNames == nil then
		-- There is no previous name history
		sPreviousNames = util.TableToJSON({ ply:Nick() })
	else
		local tPreviousNames = util.JSONToTable(sPreviousNames) or {} -- Convert from JSON to table

		if not table.HasValue(tPreviousNames, ply:Nick()) then
			table.insert(tPreviousNames, ply:Nick())
		end

		sPreviousNames = util.TableToJSON(tPreviousNames)
	end

	-- Begin IP history
	local sPreviousIPs = currentData["ip_history"] -- JSON string
	local sCurrentIP = string.Explode(":", ply:IPAddress())[1]

	if sPreviousIPs == nil then
		-- There is no previous ip history.
		sPreviousIPs = util.TableToJSON({ sCurrentIP })
	else
		local tPreviousIPs = util.JSONToTable(sPreviousIPs) or {} -- Convert from JSON to table

		if not table.HasValue(tPreviousIPs, sCurrentIP) then
			table.insert(tPreviousIPs, sCurrentIP)
		end

		sPreviousIPs = util.TableToJSON(tPreviousIPs)
	end

	local updateDataSQL = gmcore.Database:prepare([[
													UPDATE player_data
													SET in_game_name = ?,
													previous_names = ?,
													ip = ?,
													ip_history = ?
													WHERE steamid64 = ?
												]])

	function updateDataSQL:onSuccess(data)
		if not IsValid(ply) then return end

		gmcore.DebugPrint("[Player Controller] Successfully updated player data for " ..
		ply:Nick() .. " (" .. ply:SteamID64() .. ")")
	end

	function updateDataSQL:onError(err)
		gmcore.print("[Player Controller] Error updating player data. Error: " .. err)
	end

	updateDataSQL:setString(1, ply:Nick())
	updateDataSQL:setString(2, sPreviousNames)
	updateDataSQL:setString(3, sCurrentIP)
	updateDataSQL:setString(4, sPreviousIPs)
	updateDataSQL:setString(5, ply:SteamID64())
	updateDataSQL:start()
end

hook.Add("PlayerInitialSpawn", "gmcore.Stats.UpdateServerLastSeen", function(ply)
	if not IsValid(ply) then return end

	ply:UpdateServerLastSeen()
end)

hook.Add("PlayerDisconnected", "gmcore.Core.PlayerDisconnected", function(ply)
	if ply:IsBot() then return end

	gmcore.PlayerUpdateServerLastSeen(ply:SteamID64())
end)

hook.Add("PlayerInitialSpawn", "gmcore.Core.UpdateLatestPlayerInfo", function(ply)
	if ply:IsBot() then return end

	local plyNick = ply:Nick()
	local steamId64 = ply:SteamID64()
	local currentIpAddress = string.Explode(":", ply:IPAddress())[1]

	-- TODO: Move this to its own function
	local sql = gmcore.Database:prepare("SELECT * FROM player_data WHERE steamid64 = ?")

	function sql:onSuccess(data)
		if #data > 0 then
			gmcore.UpdatePlayerData(ply, data[1])
		else
			local insertPlayerDataSQL = gmcore.Database:prepare(
				"INSERT INTO player_data (`steamid64`, `last_seen`, `in_game_name`, `ip`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE last_seen=UNIX_TIMESTAMP()") -- On dup key just incase the if statement messes up

			function insertPlayerDataSQL:onSuccess()
				gmcore.DebugPrint("[Player Controller] Insert new player data row for " ..
				plyNick .. "(" .. steamId64 .. ")")
			end

			function insertPlayerDataSQL:onError(err)
				local identifier = IsValid(ply) and (plyNick .. "(" .. steamId64 .. ")") or "[disconnected]"
				gmcore.print("[Player Controller] Failure inserting new player data row for " .. identifier .. ". Error: " .. err)
			end

			insertPlayerDataSQL:setString(1, steamId64)
			insertPlayerDataSQL:setNumber(2, os.time())
			insertPlayerDataSQL:setString(3, plyNick)
			insertPlayerDataSQL:setString(4, currentIpAddress)
			insertPlayerDataSQL:start()
		end
	end

	function sql:onError(err)
		gmcore.print("[Player Controller] Check latest player info error: " .. err)
	end

	sql:setString(1, steamId64)
	sql:start()

	ply:SyncMinutesPlayed()
end)

gameevent.Listen("player_changename")

hook.Add("player_changename", "gmcore.Core.UpdateNameHistoryPlayerData", function(data)
	--local ply = player.GetByID(data.userid)
	local ply

	-- Using this since player.GetByID doesn't seem to work
	for _, v in ipairs(player.GetAll()) do
		if v:UserID() == data.userid then
			ply = v

			break
		end
	end

	gmcore.UpdatePlayerData(ply)
end)

gmcore.print("Player Controller Module Loaded Success")
