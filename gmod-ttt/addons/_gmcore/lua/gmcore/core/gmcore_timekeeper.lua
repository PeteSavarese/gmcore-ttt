---@class gmcore
---@field SyncAllPlayersMinutes fun(self: gmcore) Batch sync playtime for all players
---@field IncrementPlayerMinutes fun(self: gmcore) Increment playtime for all players

---Batch sync playtime for all connected (non-bot) players in a single query.
---Sets NW2Int "gmcore.PlayTimeMins" on each player.
function gmcore:SyncAllPlayersMinutes()
	local players = {}
	local steamids = {}

	for _, ply in player.Iterator() do
		if ply:IsBot() then continue end

		table.insert(players, ply)
		table.insert(steamids, "'" .. ply:SteamID64() .. "'")
	end

	if #players == 0 then return end

	local sql = "SELECT steamid64, minutes FROM players_stats WHERE steamid64 IN (" .. table.concat(steamids, ", ") .. ")"

	local fetchAllMinsPlayed = gmcore.Database:prepare(sql)

	function fetchAllMinsPlayed:onSuccess(data)
		local minutesLookup = {}

		for _, row in ipairs(data) do
			minutesLookup[row.steamid64] = row.minutes
		end

		-- Update all players with their playtime
		for _, ply in ipairs(players) do
			if IsValid(ply) then -- Check if player is still valid
				local playtime = minutesLookup[ply:SteamID64()] or 0
				ply:SetNW2Int("gmcore.PlayTimeMins", playtime)
			end
		end
	end

	function fetchAllMinsPlayed:onError(err)
		gmcore.print("SyncAllPlayersMinutes MySQL error: " .. err)
	end

	fetchAllMinsPlayed:start()
end

---Increment playtime by 1 minute for all connected players via batch INSERT ON DUPLICATE KEY UPDATE.
---Triggers SyncAllPlayersMinutes on success.
function gmcore:IncrementPlayerMinutes()
	local players = {}

	for _, ply in player.Iterator() do
		table.insert(players, ply)
	end

	if #players == 0 then return end

	local sql = "INSERT INTO players_stats (serverid, created_on, steamid64, minutes) VALUES "
	local values = {}

	for i, ply in ipairs(players) do
		table.insert(values, string.format("(%d, CURRENT_TIMESTAMP(), '%s', 1)", gmcore.ServerId, ply:SteamID64()))
	end

	sql = sql .. table.concat(values, ", ") .. " ON DUPLICATE KEY UPDATE minutes = minutes + 1, last_seen_on = CURRENT_TIMESTAMP()"

	local updateStatsMinutes = gmcore.Database:prepare(sql)

	function updateStatsMinutes:onSuccess()
		-- Sync all players after successful batch update
		gmcore:SyncAllPlayersMinutes()
	end

	function updateStatsMinutes:onError(err)
		gmcore.print("Error incrementing player minutes (batched): " .. err)
	end

	updateStatsMinutes:start()
end

timer.Create("gmcore.Core.Timekeeper.UpdateMinutes", 60, 0, gmcore.IncrementPlayerMinutes)
timer.Start("gmcore.Core.Timekeeper.UpdateMinutes")
