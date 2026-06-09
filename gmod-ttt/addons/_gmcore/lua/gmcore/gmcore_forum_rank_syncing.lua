---@class gmcore
---@field ForumDB Database Forum MySQL database connection (mysqloo)

gmcore = gmcore or {}

---@class ForumSyncConfig
---@field TTT_STAFF_GROUP string XenForo usergroup ID for TTT staff
---@field loadtime number Unix timestamp when module loaded
---@field lastlog number Last processed changelog ID
---@field staffRanks table<number, string> XenForo group ID -> ULX group name mapping
---@field globalRanks table<number, boolean> XenForo group IDs that apply to all servers
---@field storeRanks table<number, number> XenForo group ID -> store rank index mapping

---@type ForumSyncConfig
local CONFIG = {
	TTT_STAFF_GROUP = "12", -- MUST BE STRING!!! Constant for what non-global ranks can be applied to this server
	loadtime = os.time(),
	lastlog = 0,

	-- Forum rank mappings (correlates with XenForo usergroups)
	staffRanks = {
		[5] = "owner",
		[8] = "communitymanager",
		[9] = "developer",
		[6] = "leadadmin",
		[3] = "admin",
		[4] = "mod",
		[10] = "trialmod",
		[11] = "advisor"
	},

	-- Staff ranks that are shared between all server types
	globalRanks = {
		[5] = true,
		[6] = true,
		[9] = true,
		[11] = true
	},

	-- Store rank mappings
	storeRanks = {
		[15] = 1, -- Supporter
		[13] = 2, -- VIP
		[16] = 5, -- Legendary
	},

	-- -- Initial purchase point bonuses for store ranks
	-- pointBonuses = {
	-- 	[1] = 7500, -- Supporter
	-- 	[2] = 15000, -- VIP
	-- 	[3] = 30000, -- VIP+
	-- 	[4] = 75000, -- Elite
	-- 	[5] = 150000 -- Prestigious
	-- }
}

-- ============================================================================
-- DATABASE CONNECTION
-- ============================================================================
local dbInfo = gmcore.Config:GetDatabase("forums")

if not dbInfo then
	ErrorNoHaltWithStack("[GMCORE FORUM SYNC] Failed to get forum database config!")

	return
end

gmcore.ForumDB = mysqloo.connect(dbInfo.ip, dbInfo.username, dbInfo.password, dbInfo.database, dbInfo.port)
gmcore.ForumDB:connect()

function gmcore.ForumDB:onConnected()
	gmcore.print("Forum database connected")

	-- -- Get latest user change log from forums
	-- local getLastestLog = gmcore.ForumDB:prepare("SELECT log_id FROM xf_change_log ORDER BY log_id DESC LIMIT 1")
	--
	-- function getLastestLog:onSuccess(data)
	-- 	local logid = data[1]
	-- 	if !logid then return end
	--
	-- 	lastlog = logid.log_id
	-- end
	--
	-- getLastestLog:start()
end

function gmcore.ForumDB:OnConnectionFailed(err)
	gmcore.print("Forum database connection failed: " .. err)
end

-- ============================================================================
-- RANK MANAGEMENT
-- ============================================================================

---@class RankManager
---@field GetPlayerForumRank fun(ply: Player, forceUpdate?: boolean) Fetch and apply forum rank for player
---@field ProcessForumData fun(ply: Player, data: table) Process raw forum query data
---@field GetHighestStoreRank fun(secondaryGroups: string[]): number Get highest store rank from groups
---@field HandleStoreRank fun(ply: Player, storeRank: number) Apply or remove store rank
---@field ApplyStoreRank fun(ply: Player, rankId: number) Set store rank on player
---@field ApplyPrimaryRank fun(ply: Player, primaryRank: number, secondaryGroups: string[]) Apply staff rank
---@field ApplyMemberRank fun(ply: Player) Apply member rank if forum-linked
---@field RemoveStaffRank fun(ply: Player, rank: number): boolean? Remove staff rank if invalid
---@field SetStaffRank fun(ply: Player, group: string) Set ULX staff group
---@field NotifyPlayersOfRankChange fun(ply: Player, rankId: number) Notify player of rank change
---@field NotifyStaffOfRankRemoval fun(ply: Player) Notify staff of rank removal
---@field NotifyStaffOfRankUpdate fun(ply: Player, niceName: string) Notify staff of rank update
local RankManager = {}

---Fetch player's forum rank from XenForo database and apply it
---@param ply Player Player to sync
---@param forceUpdate? boolean Force update even if recently loaded
function RankManager.GetPlayerForumRank(ply, forceUpdate)
	-- Skip if recently loaded and not forced
	-- if CONFIG.loadtime > os.time() - 30 and !forceUpdate then return end
	if !IsValid(ply) then return end
	if ply:IsBot() then return end

	local query = gmcore.ForumDB:prepare([[
		SELECT xf_user.*
		FROM xf_user_connected_account
		LEFT JOIN xf_user ON xf_user_connected_account.user_id = xf_user.user_id
		WHERE provider_key = ?
	]])

	function query:onError(err)
		gmcore.print("Forum rank query error: " .. err)
	end

	function query:onSuccess(data)
		RankManager.ProcessForumData(ply, data)
	end

	query:setNumber(1, tonumber(ply:SteamID64()))
	query:start()
end

---Process forum query results and apply ranks to player
---@param ply Player Player to update
---@param data table Raw query results from xf_user
function RankManager.ProcessForumData(ply, data)
	if not IsValid(ply) then return end

	local forumData = data[1]
	if !forumData then RankManager.RemoveStaffRank(ply, primaryRank) return end --Strip user of staff rank if user doesn't exist

	ply:SetNWInt("forumId", forumData.user_id)

	local secondaryGroups = string.Explode(",", forumData.secondary_group_ids or "")

	-- Apply primary rank
	RankManager.ApplyPrimaryRank(ply, forumData.user_group_id, secondaryGroups)
	RankManager.ApplyMemberRank(ply)

	-- Process store ranks
	local maxStoreRank = RankManager.GetHighestStoreRank(secondaryGroups)
	RankManager.HandleStoreRank(ply, maxStoreRank)
end

---Get the highest store rank from a player's secondary forum groups
---@param secondaryGroups string[] Array of XenForo group ID strings
---@return number maxRank Highest store rank index (0 if none)
function RankManager.GetHighestStoreRank(secondaryGroups)
	local maxRank = 0

	for _, groupId in ipairs(secondaryGroups) do
		local numericGroupId = tonumber(groupId)
		local storeRank = CONFIG.storeRanks[numericGroupId]

		if storeRank and storeRank > maxRank then
			maxRank = storeRank
		end
	end

	return maxRank
end

---Apply or remove a store rank for a player based on forum sync result
---@param ply Player Player to update
---@param storeRank number Store rank index (0 to remove)
function RankManager.HandleStoreRank(ply, storeRank)
	if storeRank > 0 then
		RankManager.ApplyStoreRank(ply, storeRank)
	elseif storeRank <= 0 and ply:IsStoreRank() then
		RunConsoleCommand("ulx", "setstorerank", ply:Nick(), 0)
		gmcore.ChatPrint(ply, "Your store rank has expired! We hope you enjoyed it. You may purchase it again if you wish.")
	end
end

---Apply a store rank to a player if different from current
---@param ply Player Player to update
---@param rankId number Store rank index to apply
function RankManager.ApplyStoreRank(ply, rankId)
	if !IsValid(ply) or ply:GetStoreRank() == rankId then return end
	RunConsoleCommand("ulx", "setstorerank", ply:Nick(), rankId)

	-- -- Give point bonus
	-- if rankId != 0 and CONFIG.pointBonuses[rankId] then
	-- 	local bonus = CONFIG.pointBonuses[rankId]

	-- 	ply:PS_GivePoints(bonus)
	-- 	ply:SendLua(string.format([[gmcore.chatprint("Thanks for purchasing a store rank! You've been given %d bonus points for your purchase.")]], bonus))
	-- end

	RankManager.NotifyPlayersOfRankChange(ply, rankId)
end

---Apply a staff rank based on forum primary group and secondary groups
---@param ply Player Player to update
---@param primaryRank number XenForo primary user group ID
---@param secondaryGroups string[] Array of secondary group ID strings
function RankManager.ApplyPrimaryRank(ply, primaryRank, secondaryGroups)
	if !IsValid(ply) then return end
	local isStaff = table.HasValue(secondaryGroups, CONFIG.TTT_STAFF_GROUP) or CONFIG.globalRanks[tonumber(primaryRank)]
	local staffGroup = CONFIG.staffRanks[tonumber(primaryRank)]

	-- Handle non-staff or registered users
	if primaryRank == 2 or !isStaff then return RankManager.RemoveStaffRank(ply, primaryRank) end

	-- Handle staff users
	if staffGroup then
		RankManager.SetStaffRank(ply, staffGroup)
	end
end

---Apply "member" ULX group if player has a forum account but no staff rank
---@param ply Player Player to update
function RankManager.ApplyMemberRank(ply)
	if ply:GetNWInt("forumId", false) and !ply:IsStaffRank() and !ply:IsUserGroup("member") then
		ulx.adduserid(Entity(0), ply:SteamID(), "member")

		gmcore.ChatPrintAll(Color(66, 128, 227), ply:Nick(), Color(255, 255, 255), " has received their rank of Member for joining the forums! Join with !website")
	end
end

---Remove staff rank from player if they shouldn't have it
---@param ply Player Player to update
---@param rank number XenForo primary group ID
---@return boolean? skipped True if already properly ranked
function RankManager.RemoveStaffRank(ply, rank)
	if !ply:IsStaffRank() or tonumber(rank) == 25 then return true end -- User is already properly ranked

	-- Remove staff rank if user shouldn't have it
	if ply:IsStaffRank() then
		ulx.removeuserid(Entity(0), ply:SteamID())
		gmcore.ChatPrint(ply, "Your staff role has been removed. Contact your admin or higher incase of a problem.")
		RankManager.NotifyStaffOfRankRemoval(ply)
	end
end

---Set a player's ULX staff group and notify
---@param ply Player Player to update
---@param group string ULX group name
function RankManager.SetStaffRank(ply, group)
	if ply:GetUserGroup() == group then return end -- Already has correct rank
	local niceName = gmcore.Ranks[group] and gmcore.Ranks[group].niceName or group

	ulx.adduserid(Entity(0), ply:SteamID(), group)
	gmcore.ChatPrint(ply, "Your staff rank has been updated to ", niceName, ". Contact your admin or higher incase of a problem.")
	RankManager.NotifyStaffOfRankUpdate(ply, niceName)
end

-- ============================================================================
-- NOTIFICATION SYSTEM
-- ============================================================================

---Notify a player about their store rank change
---@param ply Player Player whose rank changed
---@param rankId number New store rank index
function RankManager.NotifyPlayersOfRankChange(ply, rankId)
	for _, v in player.Iterator() do
		if v:SteamID() != ply:SteamID() then continue end

		if rankId == 0 then
			gmcore.ChatPrint(v, "Your monthly store rank is up!")
		else
			local rankData = gmcore.StoreRank.Ranks[rankId]

			if rankData then
				gmcore.ChatPrint(v, "Thanks for purchasing a store rank! You've been added to: ", rankData.color, rankData.name)
			end
		end
	end
end

---Notify all online staff about a staff rank removal
---@param ply Player Player whose rank was removed
function RankManager.NotifyStaffOfRankRemoval(ply)
	for _, v in player.Iterator() do
		if v:IsStaffRank() then
			gmcore.ChatPrint(v, ply:Nick(), " has had their staff rank removed. Report to an admin or higher incase of a problem.")
		end
	end
end

---Notify all online staff about a staff rank update
---@param ply Player Player whose rank was updated
---@param niceName string Human-readable name of the new rank
function RankManager.NotifyStaffOfRankUpdate(ply, niceName)
	for _, v in player.Iterator() do
		if v:IsStaffRank() then
			gmcore.ChatPrint(v, ply:Nick(), " has had their staff rank updated to ", niceName, ". Contact an admin or higher up incase of a problem.")
		end
	end
end

-- -- ============================================================================
-- -- CHANGE MONITORING
-- -- ============================================================================
-- local ChangeMonitor = {}
--
-- function ChangeMonitor.CheckForRankChanges()
-- 	local query = gmcore.ForumDB:prepare([[
-- 		SELECT log_id, provider_key
-- 		FROM xf_change_log
-- 		RIGHT JOIN xf_user_connected_account ON xf_user_connected_account.user_id = xf_change_log.content_id
-- 		WHERE log_id > ? AND (field = 'user_group_id' OR field = 'secondary_group_ids')
-- 		ORDER BY log_id
-- 	]])
--
-- 	function query:onSuccess(data)
-- 		if !data[1] then return end
--
-- 		for _, logEntry in pairs(data) do
-- 			local ply = player.GetBySteamID64(logEntry.provider_key)
-- 			print(logEntry.provider_key)
--
-- 			if ply then
-- 				RankManager.GetPlayerForumRank(ply, true)
-- 			end
--
-- 			CONFIG.lastlog = logEntry.log_id
-- 		end
-- 	end
--
-- 	query:setNumber(1, CONFIG.lastlog)
-- 	query:start()
-- end

hook.Add("PlayerSpawn", "gmcore.Forums.SyncForumRanks", RankManager.GetPlayerForumRank)
-- timer.Create("gmcore.Forums.CheckForRankChanges", 10, 0, ChangeMonitor.CheckForRankChanges)
