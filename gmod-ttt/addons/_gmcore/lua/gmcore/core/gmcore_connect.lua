---@class gmcore
---@field AddBan fun(bannedPlySteamId: string, bannedPlyName: string, reason: string, banned_on: number, unbanTime: number, adminSteamid: string, adminName: string, serverId: string|integer) Add a ban record
---@field UnbanNoType fun(steamId: string, isGlobal: boolean) Remove a ban (auto-detects local/global)
---@field RemoveLocalBan fun(sSteamID: string) Remove a local server ban
---@field RemoveGlobalBan fun(sSteamID: string) Remove a global ban
---@field CheckPlayerBan fun(steamId: string, serverName: string, callback: fun(isBanned: boolean, banInfo?: BanInfo)) Check if player is banned
---@field BanKick fun(steamId: string, banLength: number, unbanTime: number, reason: string, server: string|integer) Kick a player with ban message
---@field GetBanMessageWithParams fun(reason: string, timeLeft: string, serverName: string): string Format ban kick message
---@field FormatBanTime fun(seconds: number): string Format seconds into human-readable time

require("mysqloo")

---@class BanInfo
---@field id number Ban ID in database
---@field reason string Ban reason
---@field isGlobal boolean Whether this is a global ban
---@field isPermanent boolean Whether this ban is permanent
---@field timeLeft number Seconds remaining (-1 if permanent)
---@field bannedBy string Name of the admin who banned
---@field bannedOn number Unix timestamp of when ban was placed
---@field server string Server ID or "Global"
---@field unbanTime number Unix timestamp of when ban expires (0 if permanent)

---SteamID64s that bypass server password
---@type table<string, string>
local PASSWORD_BYPASS_STEAMID = {
	["76561198180838111"] = "Dime",
}

local BAN_MESSAGE_ON_KICK = [[

-------===== [ BANNED ] =====-------

---= Reason =---
{{REASON}}

---= Server =---
{{SERVER}}

---= Ban Time Remaining =---
{{TIME_LEFT}}

---= Appeal =---
{{APPEAL_URL}}
]]

-- ===== UTILITY FUNCTIONS =====

---Format the ban kick message template with given parameters
---@param reason string Ban reason text
---@param timeLeft string Formatted time left string
---@param serverName string Server name or "Global"
---@return string message Formatted ban message
function gmcore.GetBanMessageWithParams(reason, timeLeft, serverName)
	local appealUrl = ((gmcore.ForumsBaseUrl or ""):gsub("^https?://", ""):gsub("/+$", ""))

	return string.Replace(
		string.Replace(
			string.Replace(
				string.Replace(BAN_MESSAGE_ON_KICK, "{{REASON}}", reason),
				"{{TIME_LEFT}}", timeLeft
			),
			"{{SERVER}}", serverName == "Global" and "Global" or gmcore.serverName
		),
		"{{APPEAL_URL}}", appealUrl
	)
end

---Format seconds into a human-readable duration string
---@param seconds number Time in seconds
---@return string formatted Formatted time string (e.g. "2 days, 3 hours")
function gmcore.FormatBanTime(seconds)
	if seconds <= 0 then return "Expired" end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if days > 0 then
		return string.format("%d days, %d hours", days, hours)
	elseif hours > 0 then
		return string.format("%d hours, %d minutes", hours, minutes)
	else
		return string.format("%d minutes", minutes)
	end
end

-- ===== CORE BAN FUNCTIONS =====

---Add a ban record to the database. Supports local and global bans.
---Global bans disable existing local bans before inserting.
---@param bannedPlySteamId string SteamID of the banned player
---@param bannedPlyName string Name of the banned player
---@param reason string Ban reason
---@param banned_on number Unix timestamp of ban
---@param unbanTime number Unix timestamp of unban (0 for permanent)
---@param adminSteamid string SteamID of the banning admin
---@param adminName string Name of the banning admin
---@param serverId string|integer Server ID or "Global"
function gmcore.AddBan(bannedPlySteamId, bannedPlyName, reason, banned_on, unbanTime, adminSteamid, adminName, serverId)
	if bannedPlyName == nil then bannedPlyName = "" end

	local isGlobalBan = (serverId == "Global")

	if isGlobalBan then
		-- Global ban logic: Set existing local bans to status 0, then add global ban
		local updateLocalQuery = gmcore.Database:prepare([[
			UPDATE bans
			SET status = 0
			WHERE steamid = ? AND server != 'Global' AND status = 1
		]])

		function updateLocalQuery:onSuccess(data)
			gmcore.print(string.format("Disabled local bans for %s (%s)", bannedPlyName, bannedPlySteamId))

			local insertGlobalQuery = gmcore.Database:prepare([[
				INSERT INTO bans (steamid, name, reason, banned_on, unban_time, banned_by, banned_by_steamid, server, status, void)
				VALUES (?, ?, ?, ?, ?, ?, ?, 'Global', 1, 'N')
				ON DUPLICATE KEY UPDATE
					reason = VALUES(reason),
					banned_on = VALUES(banned_on),
					unban_time = VALUES(unban_time),
					status = 1,
					void = 'N',
					unbanned_at = NULL
			]])

			function insertGlobalQuery:onSuccess(data)
				gmcore.print(string.format("Global ban processed for %s (%s): %s",
					bannedPlyName, bannedPlySteamId, reason))
			end

			function insertGlobalQuery:onError(err)
				gmcore.print("Error adding global ban: " .. err)
			end

			insertGlobalQuery:setString(1, bannedPlySteamId)
			insertGlobalQuery:setString(2, bannedPlyName)
			insertGlobalQuery:setString(3, reason)
			insertGlobalQuery:setNumber(4, banned_on)
			insertGlobalQuery:setNumber(5, unbanTime)
			insertGlobalQuery:setString(6, adminName)
			insertGlobalQuery:setString(7, adminSteamid)
			insertGlobalQuery:start()
		end

		function updateLocalQuery:onError(err)
			gmcore.print("Error updating local bans: " .. err)
		end

		updateLocalQuery:setString(1, bannedPlySteamId)
		updateLocalQuery:start()
	else
		local upsertQuery = gmcore.Database:prepare([[
			INSERT INTO bans (steamid, name, reason, banned_on, unban_time, banned_by, banned_by_steamid, server, status, void)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 'N')
			ON DUPLICATE KEY UPDATE
				name = CASE WHEN server = VALUES(server) THEN VALUES(name) ELSE name END,
				reason = CASE WHEN server = VALUES(server) THEN VALUES(reason) ELSE reason END,
				banned_on = CASE WHEN server = VALUES(server) THEN VALUES(banned_on) ELSE banned_on END,
				unban_time = CASE WHEN server = VALUES(server) THEN VALUES(unban_time) ELSE unban_time END,
				banned_by = CASE WHEN server = VALUES(server) THEN VALUES(banned_by) ELSE banned_by END,
				banned_by_steamid = CASE WHEN server = VALUES(server) THEN VALUES(banned_by_steamid) ELSE banned_by_steamid END,
				status = CASE WHEN server = VALUES(server) THEN 1 ELSE status END,
				void = CASE WHEN server = VALUES(server) THEN 'N' ELSE void END,
				unbanned_at = CASE WHEN server = VALUES(server) THEN NULL ELSE unbanned_at END
		]])

		function upsertQuery:onSuccess(data)
			gmcore.print(string.format("Local ban processed for %s (%s) on %s: %s",
				bannedPlyName, bannedPlySteamId, serverId, reason))
		end

		function upsertQuery:onError(err)
			gmcore.print("Error adding/updating local ban: " .. err)
		end

		upsertQuery:setString(1, bannedPlySteamId)
		upsertQuery:setString(2, bannedPlyName)
		upsertQuery:setString(3, reason)
		upsertQuery:setNumber(4, banned_on)
		upsertQuery:setNumber(5, unbanTime)
		upsertQuery:setString(6, adminName)
		upsertQuery:setString(7, adminSteamid)
		upsertQuery:setString(8, tostring(serverId))
		upsertQuery:start()
	end
end

---Remove a ban by SteamID, auto-routing to local or global removal
---@param steamId string SteamID of the player
---@param isGlobal boolean Whether to remove a global ban
function gmcore.UnbanNoType(steamId, isGlobal)
	return isGlobal and gmcore.RemoveGlobalBan(steamId) or gmcore.RemoveLocalBan(steamId)
end

---Remove a local server ban by SteamID
---@param sSteamID string SteamID of the player
function gmcore.RemoveLocalBan(sSteamID)
	local removeBan = gmcore.Database:prepare([[
		UPDATE bans
		SET
		status = 0,
		unbanned_at = CURRENT_TIMESTAMP()
		WHERE steamid = ?
			AND server = ?
			AND status = 1
			AND void = 'N'
			AND (unban_time > UNIX_TIMESTAMP() OR unban_time = 0)
		LIMIT 1
	]])

	function removeBan:onError(err)
		gmcore.print("Error removing local ban: " .. err)
	end

	removeBan:setString(1, sSteamID)
	removeBan:setString(2, tostring(gmcore.ServerId))
	removeBan:start()
end

---Remove a global ban by SteamID
---@param sSteamID string SteamID of the player
function gmcore.RemoveGlobalBan(sSteamID)
	local removeBan = gmcore.Database:prepare([[
		UPDATE bans
		SET
			status = 0,
			unbanned_at = CURRENT_TIMESTAMP()
		WHERE steamid = ?
			AND server = 'Global'
			AND status = 1
			AND void = 'N'
			AND (unban_time > UNIX_TIMESTAMP() OR unban_time = 0)
		LIMIT 1
	]])

	function removeBan:onError(err)
		gmcore.print("Error removing global ban: " .. err)
	end

	removeBan:setString(1, sSteamID)
	removeBan:start()
end

---Check if a player has an active ban via stored procedure
---@param steamId string SteamID of the player
---@param serverName string Server name to check against
---@param callback fun(isBanned: boolean, banInfo?: BanInfo) Callback with ban status
function gmcore.CheckPlayerBan(steamId, serverName, callback)
	local checkBan = gmcore.Database:prepare("CALL GetPlayerBan(?, ?)")

	function checkBan:onSuccess(data)
		if #data > 0 then
			local ban = data[1]
			local isGlobal = ban.server == "Global"
			local isPermanent = ban.unban_time == 0
			local timeLeft = isPermanent and -1 or (ban.unban_time - os.time())

			callback(true, {
				id = ban.id,
				reason = ban.reason,
				isGlobal = isGlobal,
				isPermanent = isPermanent,
				timeLeft = timeLeft,
				bannedBy = ban.banned_by,
				bannedOn = ban.banned_on,
				server = ban.server,
				unbanTime = ban.unban_time
			})
		else
			callback(false, nil)
		end
	end

	function checkBan:onError(err)
		gmcore.print("Error checking ban: " .. err)
		callback(false, nil)
	end

	checkBan:setString(1, steamId)
	checkBan:setString(2, serverName)
	checkBan:start()
end

---Kick a player with a formatted ban message
---@param steamId string SteamID of the player to kick
---@param banLength number Ban duration in seconds (0 for permanent)
---@param unbanTime number Unix timestamp of unban
---@param reason string Ban reason
---@param server string|integer Server name or ID
function gmcore.BanKick(steamId, banLength, unbanTime, reason, server)
	local ply = player.GetBySteamID(steamId)
	local strTime = banLength != 0 and ULib.secondsToStringTime(banLength) or "Permanent"
	local shortReason = strTime

	local longReason = gmcore.GetBanMessageWithParams(reason, shortReason, server)

	if IsValid(ply) then
		ULib.kick(ply, longReason, nil, true)
	end

	-- This redundant kick is to ensure they're kicked even if they're joining
	game.KickID(steamId, longReason or "")
	hook.Call(ULib.HOOK_USER_BANNED, _, steamId, banLength)
end

-- ===== PLAYER CONNECTION HANDLER =====

---CheckPassword hook handler - checks if connecting player is banned
---@param steamId64 string SteamID64 of the connecting player
local function onAuthCheckBan(steamId64)
	local steamId = util.SteamIDFrom64(steamId64)

	gmcore.CheckPlayerBan(steamId, tostring(gmcore.ServerId), function(isBanned, banInfo)
		if !isBanned then return end

		gmcore.print(string.format("Player %s is banned: %s", steamId, banInfo.reason))

		if !banInfo.isPermanent and banInfo.timeLeft <= 0 then
			gmcore.print(string.format("Removing expired ban for %s", steamId))
			gmcore.UnbanNoType(steamId, banInfo.isGlobal)
			return
		end

		local timeLeft = banInfo.isPermanent and 0 or banInfo.timeLeft

		gmcore.BanKick(steamId, timeLeft, banInfo.unbanTime, banInfo.reason, banInfo.server)
	end)

	-- TODO: Add family share checking here
end

-- ===== OVERRIDE ULIB =====

---Override default ULib ban functions with GL's MySQL-backed implementation
local function overrideULibFuncs()
	function ULib.refreshBans()
		gmcore.print("Ban refresh called")
	end

	-- Override the default ULib functions
	function ULib.addBan(steamID, banTime, banReason, plyNick, staffIssuer, isGlobal)
		if isGlobal == nil then isGlobal = false end

		banTime = banTime * 60 -- Convert to seconds since ULib uses minutes

		local unbanTime = banTime == 0 and 0 or (os.time() + banTime)
		local adminNick = "(Console)"
		local adminSteamID = "(Console)"

		if IsValid(staffIssuer) and staffIssuer:IsPlayer() then
			adminNick = staffIssuer:Name()
			adminSteamID = staffIssuer:SteamID()
		end

		local serverName = isGlobal and "Global" or gmcore.ServerId

		gmcore.AddBan(steamID, plyNick, banReason, os.time(), unbanTime, adminSteamID, adminNick, serverName)
		gmcore.BanKick(steamID, banTime, unbanTime, banReason, serverName)
	end

	function ULib.kickban(ply, time, reason, admin, bIsGlobal)
		if !time or type(time) != "number" then
			time = 0
		end

		if ply:IsListenServerHost() then return end
		ULib.addBan(ply:SteamID(), time, reason, ply:Name(), admin, bIsGlobal)
	end

	function ULib.unban(steamId, staffPly)
		gmcore.UnbanNoType(steamId, false)
	end

	gmcore.print("Override ULib ban funcs success")
end

-- ===== HOOKS =====

hook.Add("CheckPassword", "gmcore.Bans.CheckBan", onAuthCheckBan)
hook.Add("PostGamemodeLoaded", "gmcore.Bans.OverrideULibBans", overrideULibFuncs)
hook.Remove("CheckPassword", "ULibBanCheck")

-- Initialize on load
timer.Simple(5, overrideULibFuncs)

gmcore.print("Bans Module Loaded Successfully")

hook.Add("CheckPassword", "JoinBanCheck", function(sid64, ip, svp, clp, name)
	local sid = util.SteamIDFrom64(sid64)

	if svp == "" then
		return true
	elseif PASSWORD_BYPASS_STEAMID[sid64] then
		return true
	elseif svp == clp then
		return true
	else
		return false, "Access DENIED"
	end
end)
