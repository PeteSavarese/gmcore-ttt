if not SERVER then return end

---Overrides ulx.fancyLogAdmin to use ULX/store-rank colors for player names.
local function applyFancyLogOverride()
	if not ulx or not ULib then return end

	---@param command string|ConVar ULX command name or ConVar to resolve
	---@return ConVar|nil cvar ConVar, or nil if not found
	local function getCvarObj(command)
		if ulx.cvars then
			local entry = ulx.cvars[ tostring(command):lower() ]
			if entry and entry.obj then
				return entry.obj
			end
		end

		local nospaceCommand = tostring(command):gsub(" ", "_")

		return GetConVar("ulx_" .. nospaceCommand)
	end

	local logEcho = getCvarObj("logEcho")
	local logEchoColors = getCvarObj("logEchoColors")
	local logEchoColorDefault = getCvarObj("logEchoColorDefault")
	local logEchoColorConsole = getCvarObj("logEchoColorConsole")
	local logEchoColorSelf = getCvarObj("logEchoColorSelf")
	local logEchoColorEveryone = getCvarObj("logEchoColorEveryone")
	local logEchoColorPlayerAsGroup = getCvarObj("logEchoColorPlayerAsGroup")
	local logEchoColorPlayer = getCvarObj("logEchoColorPlayer")
	local logEchoColorMisc = getCvarObj("logEchoColorMisc")

	local hiddenechoAccess = "ulx hiddenecho"
	local seeanonymousechoAccess = "ulx seeanonymousechoes"

	local default_color
	local console_color
	local self_color
	local misc_color
	local everyone_color
	local player_color

	---Updates color variables from ULX log echo color ConVars.
	local function updateColors()
		if not ULib or not ULib.explode then return end

		local cvars = { logEchoColorDefault, logEchoColorConsole, logEchoColorSelf, logEchoColorEveryone, logEchoColorPlayer, logEchoColorMisc }
		for i = 1, #cvars do
			local cvar = cvars[i]
			if cvar then
				local pieces = ULib.explode("%s+", cvar:GetString() or "")
				if #pieces ~= 3 then
					Msg("Warning: Tried to set ulx log color cvar with bad data\n")

					return
				end
				local color = Color(tonumber(pieces[1]) or 0, tonumber(pieces[2]) or 0, tonumber(pieces[3]) or 0)

				if cvar == logEchoColorDefault then
					default_color = color
				elseif cvar == logEchoColorConsole then
					console_color = color
				elseif cvar == logEchoColorSelf then
					self_color = color
				elseif cvar == logEchoColorEveryone then
					everyone_color = color
				elseif cvar == logEchoColorPlayer then
					player_color = color
				elseif cvar == logEchoColorMisc then
					misc_color = color
				end
			end
		end
	end

	updateColors()

	hook.Add(ULib.HOOK_REPCVARCHANGED, "GL_ULXCheckLogColorCvar", function(sv_cvar)
		sv_cvar = tostring(sv_cvar):lower()
		if not sv_cvar:find("^ulx_logechocolor") then return end
		if sv_cvar ~= "ulx_logechocolorplayerasgroup" then
			timer.Simple(0.1, updateColors)
		end
	end)

	---@param target_ply Player|Entity Player whose name color is being determined
	---@param showing_ply Player|string Player viewing the log message, or "CONSOLE"
	---@return Color color Rank-based or ULX group color for player's name
	local function plyColor(target_ply, showing_ply)
		if not IsValid(target_ply) then
			return console_color
		end

		-- GL rank/store-rank based colors
		if gmcore and gmcore.Ranks and gmcore.StoreRank and gmcore.StoreRank.Ranks
			and isfunction(target_ply.IsStaffRank)
			and isfunction(target_ply.IsStoreRank)
			and isfunction(target_ply.GetStoreRank)
			and isfunction(target_ply.IsUserGroup) then
			if target_ply:IsUserGroup("user") and not target_ply:IsStoreRank() then
				return Color(255, 255, 255)
			elseif target_ply:IsStaffRank() then
				local rank = gmcore.Ranks[target_ply:GetUserGroup()]

				return (rank and rank.color) or Color(255, 255, 255)
			elseif target_ply:IsStoreRank() then
				local storeRank = gmcore.StoreRank.Ranks[target_ply:GetStoreRank()]

				return (storeRank and storeRank.color) or Color(255, 255, 255)
			end

			return Color(255, 255, 255)
		end

		if showing_ply == target_ply then
			return self_color
		elseif logEchoColorPlayerAsGroup and logEchoColorPlayerAsGroup.GetBool and logEchoColorPlayerAsGroup:GetBool() then
			return team.GetColor(target_ply:Team())
		end

		return player_color
	end

	---@param calling_ply Player Player who executed the ULX command
	---@param target_list Player[] List of targeted players
	---@param showing_ply Player|string Player viewing the log message, or "CONSOLE"
	---@param use_self_suffix boolean Whether to append "(self)" when target is the caller
	---@param is_admin_part boolean Whether this list is for the admin portion of the log
	---@return table playerList Alternating color and name entries for colored log output
	local function makePlayerList(calling_ply, target_list, showing_ply, use_self_suffix, is_admin_part)
		local players = player.GetAll()
		local anonymous = showing_ply ~= "CONSOLE" and not ULib.ucl.query(showing_ply, seeanonymousechoAccess) and logEcho and logEcho.GetInt and logEcho:GetInt() == 1

		if #players > 1 and #target_list == #players then
			return { everyone_color, "Everyone" }
		elseif is_admin_part then
			local target = target_list[1]
			if anonymous and target ~= showing_ply then
				return { everyone_color, "(Someone)" }
			elseif not IsValid(target) then
				return { console_color, "(Console)" }
			end
		end

		local strs = {}

		table.sort(target_list, function(ply_a, ply_b)
			if ply_a == showing_ply then return true end
			if ply_b == showing_ply then return false end
			if ply_a == calling_ply then return true end
			if ply_b == calling_ply then return false end

			return ply_a:Nick() < ply_b:Nick()
		end)

		for i = 1, #target_list do
			local target = target_list[i]
			table.insert(strs, plyColor(target, showing_ply))
			if target == showing_ply then
				if not use_self_suffix or calling_ply ~= showing_ply then
					table.insert(strs, "You")
				else
					table.insert(strs, "Yourself")
				end
			elseif not use_self_suffix or calling_ply ~= target_list[i] or anonymous then
				table.insert(strs, IsValid(target_list[i]) and target_list[i]:Nick() or "(Console)")
			else
				table.insert(strs, "Themself")
			end
			table.insert(strs, default_color)
			table.insert(strs, ",")
		end

		table.remove(strs)
		table.remove(strs)

		return strs
	end

	local function insertToAll(t, data)
		for i = 1, #t do
			table.insert(t[i], data)
		end
	end

	---@param calling_ply Player The player who executed the ULX command
	---@param format boolean|table|string The log format string, or a boolean/table controlling echo behavior
	---@param ... any
	function ulx.fancyLogAdmin(calling_ply, format, ...)
		local use_self_suffix = false
		local hide_echo = false
		local players = {}
		if logEcho and logEcho.GetInt and logEcho:GetInt() ~= 0 then
			players = player.GetAll()
		end

		local arg_pos = 1
		local args = { ... }
		if type(format) == "boolean" then
			hide_echo = format
			format = args[1]
			arg_pos = arg_pos + 1
		end

		if type(format) == "table" then
			players = format
			format = args[1]
			arg_pos = arg_pos + 1
		end

		if hide_echo then
			for i = #players, 1, -1 do
				if not ULib.ucl.query(players[i], hiddenechoAccess) and players[i] ~= calling_ply then
					table.remove(players, i)
				end
			end
		end
		table.insert(players, "CONSOLE")

		local playerStrs = {}
		for i = 1, #players do
			playerStrs[i] = {}
		end

		if hide_echo then
			insertToAll(playerStrs, default_color)
			insertToAll(playerStrs, "(SILENT) ")
		end

		local no_targets = false
		tostring(format):gsub("([^#]*)#([%.%d]*[%a])([^#]*)", function(prefix, tag, postfix)
			local arg = args[arg_pos]
			arg_pos = arg_pos + 1

			if prefix and prefix ~= "" then
				insertToAll(playerStrs, default_color)
				insertToAll(playerStrs, prefix)
			end

			local specifier = tag:sub(-1, -1)
			local isAdminArg = specifier == "A" and calling_ply
			if not (arg or isAdminArg) then
				insertToAll(playerStrs, "#" .. tag)
			elseif specifier == "T" or specifier == "P" or isAdminArg then
				if isAdminArg then
					arg_pos = arg_pos - 1
					arg = { calling_ply }
				elseif type(arg) ~= "table" then
					arg = { arg }
				end

				if #arg == 0 then no_targets = true end

				for i = 1, #players do
					table.Add(playerStrs[i], makePlayerList(calling_ply, arg, players[i], use_self_suffix, specifier == "A"))
				end
				use_self_suffix = true
			else
				insertToAll(playerStrs, misc_color)
				insertToAll(playerStrs, string.format("%" .. tag, arg))
			end

			if postfix and postfix ~= "" then
				insertToAll(playerStrs, default_color)
				insertToAll(playerStrs, postfix)
			end
		end)

		if no_targets then return end

		for i = 1, #players do
			if (not logEchoColors) or (logEchoColors.GetBool and not logEchoColors:GetBool()) or players[i] == "CONSOLE" then
				for j = #playerStrs[i], 1, -1 do
					if type(playerStrs[i][j]) == "table" then
						table.remove(playerStrs[i], j)
					end
				end
			end

			if players[i] ~= "CONSOLE" then
				ULib.tsayColor(players[i], true, unpack(playerStrs[i]))
			else
				local msg = table.concat(playerStrs[i])
				if game.IsDedicated() then
					Msg(msg .. "\n")
				end

				local logFile = getCvarObj("logFile")
				if logFile and logFile.GetBool and logFile:GetBool() and ulx.logString then
					ulx.logString(msg, true)
				end
			end
		end
	end

	function ulx.fancyLog(format, ...)
		ulx.fancyLogAdmin(_, format, ...)
	end
end

hook.Add("ULXLoaded", "GL_ULXFancyLogOverride", function()
	applyFancyLogOverride()
	gmcore.DebugPrint("Overrode ULX logging color")
end)

-- If ULX already loaded before this file executed.
if ulx and ULib then
	timer.Simple(0, applyFancyLogOverride)
end
