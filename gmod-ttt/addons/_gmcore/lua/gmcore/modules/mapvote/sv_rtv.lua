gmcore.RTV = {}

---@type table<integer, integer> UserID -> vote power
gmcore.RTV.RTVList = {}
---@type boolean
gmcore.RTV.RTVSuccess = false
---@type boolean
gmcore.RTV.CanRTV = false
---@type boolean
gmcore.RTV.MapBegan = false

---@type table<integer, Player>
local activePlayerList = {}

---Removes a player's vote from the RTV list.
---@param ply Player The player whose RTV vote to remove
local function removeVote(ply)
	if gmcore.RTV.RTVList[ply:UserID()] then
		gmcore.RTV.RTVList[ply:UserID()] = nil
	end
	activePlayerList[ply:UserID()] = nil
end

--[[
local function removeDisconnectedVote(data)
	if gmcore.RTV.RTVList[data.userid] then
		table.remove(gmcore.RTV.RTVList, data.userid)
	end
end
]]


---@type table<Player, boolean>
local activePlayers = {}

---Records all active terror players at round start.
local function getActivePlayersOnRoundStart()
	activePlayers = {}

		for _, ply in ipairs(player.GetAll()) do
				if ply:IsTerror() then
						activePlayers[ply] = true
				end
		end
end

-- Log active players on round start
hook.Add("TTTBeginRound", "gmcore.rtv.LogActivePlayers", getActivePlayersOnRoundStart)

-- Add late joiners to the RTV list
hook.Add("TTTPlayerSpawnForRound", "gmcore.rtv.TrackLateJoiners", function(ply, late)
		if GetRoundState() == ROUND_ACTIVE then
				activePlayers[ply] = true
		end
end)

---Returns the number of votes needed for a successful RTV (75% of active players).
---@return integer threshold The number of votes required for RTV to pass
local function getRTVThreshold()
		return math.Round(table.Count(activePlayers) * 0.75)
end

---Checks if RTV is allowed based on the rtvlock file. Prevents RTVing two maps in a row.
---@return boolean canRTV True if RTV is not locked out for this map
local function canRTVThisMap()
	if not file.Exists("gmcore/rtvlock.txt", "DATA") then
		file.Write("gmcore/rtvlock.txt", tostring(gmcore.RTV.RTVSuccess))
	elseif file.Read("gmcore/rtvlock.txt", "DATA") == "true" then
		return false
	end

	return true
end

---Called by gmcore.MapVote, checks if RTV should be unlocked for the next map.
function gmcore.RTV.updateRTVLock()
	if not gmcore.RTV.canRTV and not gmcore.RTV.RTVSuccess then
		file.Write("gmcore/rtvlock.txt", "false")
	end
end

---Compiles a list of all non-spectator players. First call initializes the table.
local function getPlayerList()
	for _, v in player.Iterator() do
		if v:IsTerror() and IsValid(v) and not activePlayerList[v:UserID()] then
			table.insert(activePlayerList[v:UserID()], v)
		end
	end
end

---Returns the current number of valid RTVs. Prunes votes from disconnected players.
---@return integer count The total RTV vote power from connected players
local function getRTVCount()
	local rtvCount = 0

	for userID, votePower in pairs(gmcore.RTV.RTVList) do
		if not IsValid(Player(userID)) then
			table.remove(gmcore.RTV.RTVList, userID)
			continue
		end
		rtvCount = rtvCount + votePower
	end

	return rtvCount
end

---Called at the end of every round, triggers map vote if RTV was successful.
local function checkRTVSuccess()
	if gmcore.RTV.RTVSuccess and not gmcore.MapVote.isVoting then
		gmcore.MapVote.initializeMapVote()
	end
end

---Adds a player's vote (multiplied by store rank power) to the RTV list.
---@param ply Player The player requesting to rock the vote
function gmcore.RTV:AddToRTV(ply)
	if gmcore.MapVote.isVoting then
		net.Start("gmcore.MapVote.StartVoting")
		net.WriteFloat(gmcore.MapVote.voteTimeBegin)
		net.WriteTable(gmcore.MapVote.voteList)
		net.Send(ply)

		return
	end

	if not gmcore.RTV.CanRTV then
		if gmcore.RTV.MapBegan then
			gmcore.chatprint(ply, "There was a successful RTV last map! You must wait for another map change to start an RTV vote.")
		else
			gmcore.chatprint(ply, "You cannot RTV until the first round of the map has begun!")
		end

		return
	end

	if GetGlobalInt("ttt_rounds_left", 6) <= 1 then
		gmcore.chatprint(ply, "You cannot RTV on the last round of a map!")

		return
	end

	if gmcore.RTV.RTVList[ply:UserID()] then
		gmcore.chatprint(ply, "You have already been added to rock the vote list!")

		return
	end

	gmcore.RTV.RTVList[ply:UserID()] = gmcore.MapVote:GetVoteMultiplier(ply) -- Add their vote * donor scaler to the RTV list
	local threshold = getRTVThreshold()

	local totalRTVs = getRTVCount()

	if totalRTVs >= threshold then
		gmcore.RTV.RTVSuccess = true
		file.Write("gmcore/rtvlock.txt", tostring(gmcore.RTV.RTVSuccess))
		gmcore.chatprintAll(CHAT_PRINT_BLUE, ply:Nick(), color_white, " has voted to rock the vote! Enough votes to rock the vote! MapVote will begin when round ends!")
	else
		gmcore.chatprintAll(CHAT_PRINT_BLUE, ply:Nick(), color_white, " has voted to rock the vote (" .. totalRTVs .. "/" .. threshold .. ") Type ", CHAT_PRINT_BLUE, "!rtv ", color_white, "to add your vote!")
	end
end

--gmcore.RTV.CanRTV = canRTVThisMap()
getPlayerList()

hook.Add("PlayerInitialSpawn", "gmcore.RTV.InitializePlayerRTVStatus", function(ply)
	if (IsValid(ply)) and not activePlayerList[ply:UserID()] then
		activePlayerList[ply:UserID()] = ply
	end
end)

hook.Add("PlayerChangedTeam", "gmcore.RTV.MoveSpectateRemoveVote", function(ply, _, newTeam)
	timer.Simple(1, function()
		if not IsValid(ply) then return end

		if ply:GetNWBool("TTTIsForceSpec") then
			if gmcore.RTV.RTVList[ply:UserID()] then
				removeVote(ply)
			end

			if activePlayerList[ply:UserID()] then
				activePlayerList[ply:UserID()] = nil
			end
		else
			if not activePlayerList[ply:UserID()] and IsValid(ply) then
				activePlayerList[ply:UserID()] = ply
			end
		end
	end)
end)

hook.Add("PlayerDisconnected", "gmcore.RTV.DisconnectRemoveVote", removeVote)
hook.Add("TTTEndRound", "gmcore.RTV.RTVCheck", checkRTVSuccess)


local function openVotingIfCanRTV()
	if canRTVThisMap() then
		gmcore.RTV.CanRTV = true
	end

	gmcore.RTV.MapBegan = true
end

hook.Add("TTTBeginRound", "gmcore.RTV.EnableRTV", openVotingIfCanRTV)


gmcore.print("RTV loaded")
