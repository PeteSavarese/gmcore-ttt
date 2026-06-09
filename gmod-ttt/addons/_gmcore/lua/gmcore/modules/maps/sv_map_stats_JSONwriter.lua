---Writes per-round player count statistics to JSON files in gl/data/.
local mapStats = {}

---Initialize the mapStats table with the current map name.
local function intializeStats()
	--Defined backwards because util.TableToJSON writes table contents backwards.
	mapStats["player_counts"] = {}
	mapStats["map"] = tostring(game.GetMap())
end

---@return string Fun round name or "null"
local function determineFunRound()
	if gmcore.FunRounds.ActiveRound then
		return gmcore.FunRounds.ChosenFunRound
	end

	return "null"
end

--TODO: Combine this with createPlayerTable().
---@return table[] Array of player data tables for players who have RTVed
local function getPlayerRTVs()
	local parentTable = {}
	for _, v in ipairs(player.GetAll()) do
		if IsValid(v) and gmcore.RTV.RTVList[v:UserID()] then
			local pDataTable = {}
			pDataTable["steam_id"] = v:SteamID()
			pDataTable["store_rank"] = v:GetStoreRank()
			pDataTable["staff_rank"] = v:StaffRank()
			pDataTable["is_spectator"] = v:GetForceSpec()
			table.insert(parentTable, pDataTable)
		end
	end

	return parentTable
end

---@return table[] Array of player data tables for all valid players
local function createPlayerTable()
	local parentTable = {}
	for _, v in ipairs(player.GetAll()) do
		if not IsValid(v) then continue end

		local pDataTable = {}
		pDataTable["steam_id"] = v:SteamID()
		pDataTable["store_rank"] = v:GetStoreRank()
		pDataTable["staff_rank"] = v:StaffRank()
		pDataTable["is_spectator"] = v:GetForceSpec()

		table.insert(parentTable, pDataTable)
	end

	return parentTable
end

---Records player data and metadata at the start of each round.
local function recordRoundStartStats()
	-- Get current round number for round stats.
	local currentRoundNum = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6) + 1
	mapStats["player_counts"][currentRoundNum] = {}

	--Record the starting round's:
	--1. Round #
	--2. Fun round name (if any)
	--3. Number of players connected (includes spectators)
	--4. Number of RTV votes (as a list of players)
	--5. Unix timestamp
	mapStats["player_counts"][currentRoundNum]["round"] = currentRoundNum
	mapStats["player_counts"][currentRoundNum]["fun_round"] = determineFunRound()

	mapStats["player_counts"][currentRoundNum]["start_player_count"] = {}
	mapStats["player_counts"][currentRoundNum]["start_player_count"] = createPlayerTable()

	mapStats["player_counts"][currentRoundNum]["start_time"] = os.time()
end

---Records player data at the end of each round and writes JSON on final round.
local function recordRoundEndStats()
	local currentRoundNum = GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left", 6)
	--Record number of players connected again (includes spectators)
	mapStats["player_counts"][currentRoundNum]["end_player_count"] = {}
	mapStats["player_counts"][currentRoundNum]["end_player_count"] = createPlayerTable()
	mapStats["player_counts"][currentRoundNum]["RTVList"] = {}
	mapStats["player_counts"][currentRoundNum]["RTVList"] = getPlayerRTVs()
	mapStats["player_counts"][currentRoundNum]["end_time"] = os.time()

	if currentRoundNum == 6 or gmcore.MapVote.isVoting then
		local timestamp = os.date()
		--Don't mind this for now
		timestamp = timestamp:gsub("  ", "-") -- Will get rid of double spaces or dashes when date of month is single digit (i.e. Feb. 1 thru Feb. 9)
		timestamp = timestamp:gsub(" ", "-")
		timestamp = timestamp:gsub("/", "-")
		timestamp = timestamp:gsub(":", "_") --Definitely don't remove this one, will break file writing.

		if not file.Exists("gmcore/data/", "DATA") then
			file.CreateDir("gmcore/data")
		end

		--Files will show up in gl/data as something like "Sun-Jan-29-14 58 03-2023.json"
		file.Write("gmcore/data/" .. timestamp .. ".json", util.TableToJSON(mapStats))
	end
end

intializeStats()

hook.Add("TTTBeginRound", "gmcore.RecordPlayerCount.RoundStart", recordRoundStartStats)
hook.Add("TTTEndRound", "gmcore.RecordPlayerCount.RoundEnd", recordRoundEndStats)
