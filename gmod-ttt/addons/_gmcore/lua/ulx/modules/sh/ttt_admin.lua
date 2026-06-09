local CATEGORY_NAME = "TTT Admin"
local gamemode_error = "The current gamemode is not trouble in terrorist town!"
ulx.target_role = {}

local function updateRoles()
	table.Empty(ulx.target_role)
	table.insert(ulx.target_role, "traitor")
	table.insert(ulx.target_role, "detective")
	table.insert(ulx.target_role, "innocent")
end

hook.Add(ULib.HOOK_UCLCHANGED, "ULXRoleNamesUpdate", updateRoles)
updateRoles()
--[Global Helper Functions][Used by more than one command.]------------------------------------
---Sends messages to player(s)
---@param v Player|table The player(s) to send the message to
---@param message string The message that will be sent
local function send_messages(v, message)
	if type(v) == "Players" then
		v:ChatPrint(message)
	elseif type(v) == "table" then
		for i = 1, #v do
			v[i]:ChatPrint(message)
		end
	end
end

---Finds the corpse of a given player
---@param v Player The player to find the corpse for
local function corpse_find(v)
	for _, ent in pairs(ents.FindByClass("prop_ragdoll")) do
		if ent.uqid == v:UniqueID() and IsValid(ent) then return ent or false end
	end
end

---Removes the corpse given
---@param corpse Entity The corpse to be removed
local function corpse_remove(corpse)
	CORPSE.SetFound(corpse, false)

	if string.find(corpse:GetModel(), "zm_", 6, true) then
		player.GetByUniqueID(corpse.uqid):SetNWBool("body_found", false)
		corpse:Remove()
		SendFullStateUpdate()
	elseif corpse.player_ragdoll then
		player.GetByUniqueID(corpse.uqid):SetNWBool("body_found", false)
		corpse:Remove()
		SendFullStateUpdate()
	end
end

local currentround = 0
if SERVER then
	-- Migrate legacy gl_* tables to gmcore_* on first boot after rename.
	for _, t in ipairs({ "slays", "slaycount", "settings" }) do
		if sql.TableExists("gl_" .. t) and not sql.TableExists("gmcore_" .. t) then
			sql.Query(string.format("ALTER TABLE gl_%s RENAME TO gmcore_%s", t, t))
			gmcore.print("[TTT ADMIN] Migrated gl_" .. t .. " -> gmcore_" .. t)
		end
	end

	if not sql.TableExists("gmcore_slays") then
		sql.Query([[CREATE TABLE gmcore_slays (
		steamid varchar(20) NOT NULL,
		admin tinytext NOT NULL,
		slays SMALLINT UNSIGNED NOT NULL,
		reason tinytext NOT NULL,
		time BIGINT UNSIGNED NOT NULL);
		]])

		gmcore.print("[TTT ADMIN] Created slays SQL table")
	end

	if not sql.TableExists("gmcore_slaycount") then
		sql.Query([[CREATE TABLE gmcore_slaycount (
		steamid varchar(20) NOT NULL,
		round BIGINT UNSIGNED NOT NULL);
		]])

		gmcore.print("[TTT ADMIN] Created slaycount SQL table")
	end

	if not sql.TableExists("gmcore_settings") then
		sql.Query([[CREATE TABLE gmcore_settings (
		setting varchar(255) NOT NULL,
		value varchar(255) NOT NULL);
		]])
		sql.Query("INSERT INTO gmcore_settings (`setting`, `value`) VALUES ('round', 0);")


		gmcore.print("[TTT ADMIN] Created settings SQL table")
	end

	currentround = sql.QueryValue("SELECT value FROM gmcore_settings WHERE setting = 'round'")

	sql.Query(string.format("DELETE FROM gmcore_slaycount WHERE round < %s", currentround - 12))
end

hook.Add("TTTBeginRound", "gmcore.roundcounterup", function()
	currentround = currentround + 1
	sql.Query("UPDATE gmcore_settings SET value = value + 1 WHERE setting = 'round'")
	-- Note: UpdateAllReports() is a client-side method on report panels, not the main Damagelog object
	-- This call was causing errors and has been removed
end)

local function getrecentslaycount(sid)
	local existingSlays = sql.Query(string.format("SELECT * FROM gmcore_slaycount WHERE steamid = %s AND round >= %s",
		sql.SQLStr(sid), currentround - 12))
	if not existingSlays then return 0 end

	return #existingSlays
end

---Handles SQL query(s) to add slays
---@param sTargetSteamId string The SteamID of the target player
---@param iSlaysAddRem number The amount of slays to increment by
---@param sReason string Reason for slay
---@param pAdmin Player Player that is adding the slay
---@param silent boolean Whether to suppress messages
local function addSlays(sTargetSteamId, iSlaysAddRem, sReason, pAdmin, silent)
	local target_ply = player.GetBySteamID(sTargetSteamId)
	--local plys = player.GetAll()

	-- for i = 1, #plys do
	--  if plys[i]:SteamID() == sTargetSteamId then
	--    target_ply = plys[i]
	--    break
	--  end
	-- end

	for i = 1, iSlaysAddRem do
		sql.Query(string.format("INSERT INTO gmcore_slaycount (steamid, round) VALUES (%s, %s);", sql.SQLStr(sTargetSteamId),
			currentround))
	end

	local existingSlays = sql.QueryRow(string.format("SELECT * FROM gmcore_slays WHERE steamid = %s LIMIT 1",
		sql.SQLStr(sTargetSteamId)))

	-- Since there are existing slays, just increment and update the reason
	if existingSlays then
		local iCurrentSlays = existingSlays["slays"]
		local iNewSlayCount = iCurrentSlays + iSlaysAddRem
		sql.Query(string.format("UPDATE gmcore_slays SET admin = %s, slays = %i, reason = %s, time = %s WHERE steamid = %s",
			sql.SQLStr(pAdmin:Nick()), iNewSlayCount, sql.SQLStr(sReason), tostring(os.time()), sql.SQLStr(sTargetSteamId)))

		if not silent then
			if target_ply then
				local sChatMessage = ""
				if iNewSlayCount == 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #T next round (#s)"
					elseif iNewSlayCount == 1 then
						sChatMessage = "#A will slay #T next round."
					end
				elseif iNewSlayCount > 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #T for the next " .. tostring(iNewSlayCount) .. " rounds (#s)"
					else
						sChatMessage = "#A will slay #T for the next " .. tostring(iNewSlayCount) .. " rounds."
					end
				end
				ulx.fancyLogAdmin(pAdmin, sChatMessage, target_ply, sReason)
			else
				local sChatMessage = ""
				if iNewSlayCount == 1 then
					if sReason != "" then
						sChatMessage = "#A has will slay to #s (#s)"
					elseif iNewSlayCount == 1 then
						sChatMessage = "#A has will slay to #s."
					end
				elseif iNewSlayCount > 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #s for the next " .. tostring(iNewSlayCount) .. " rounds (#s)"
					else
						sChatMessage = "#A will slay #s for the next " .. tostring(iNewSlayCount) .. " rounds"
					end
				end
				ulx.fancyLogAdmin(pAdmin, sChatMessage, sTargetSteamId, sReason)
			end
		end
	else
		sql.Query(string.format(
		"INSERT INTO gmcore_slays (`steamid`, `admin`, `slays`, `reason`, `time`) VALUES (%s, %s, %i, %s, %s);",
			sql.SQLStr(sTargetSteamId), sql.SQLStr(pAdmin:Nick()), iSlaysAddRem, sql.SQLStr(sReason), os.time()))
		if not silent then
			local sChatMessage = ""
			if target_ply then
				if iSlaysAddRem == 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #T next round (#s)"
					elseif iSlaysAddRem == 1 then
						sChatMessage = "#A will slay #T next round."
					end
				elseif iSlaysAddRem > 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #T for the next " .. tostring(iSlaysAddRem) .. " rounds (#s)"
					else
						sChatMessage = "#A will slay #T for the next " .. tostring(iSlaysAddRem) .. " rounds."
					end
				end
				ulx.fancyLogAdmin(pAdmin, sChatMessage, target_ply, sReason)
			else
				if iSlaysAddRem == 1 then
					if sReason != "" then
						sChatMessage = "#A has added a slay to #s (#s)"
					elseif iSlaysAddRem == 1 then
						sChatMessage = "#A has added a slay to #s."
					end
				elseif iSlaysAddRem > 1 then
					if sReason != "" then
						sChatMessage = "#A will slay #s for the next " .. tostring(iSlaysAddRem) .. " rounds (#s)"
					else
						sChatMessage = "#A will slay #s for the next " .. tostring(iSlaysAddRem) .. " rounds"
					end
				end
				ulx.fancyLogAdmin(pAdmin, sChatMessage, sTargetSteamId, sReason)
			end
		end
	end
end

local function removeSlays(sTargetSteamId, iSlaysAddRem, sReason, pAdmin)
	local target_ply = player.GetBySteamID(sTargetSteamId)

	local slayQuery = sql.QueryRow(string.format("SELECT * FROM gmcore_slays WHERE steamid = %s LIMIT 1",
		sql.SQLStr(sTargetSteamId)))

	if not slayQuery then
		-- Since there are existing slays, just increment and update the reason
		local sPlyIdentifier = (target_ply and target_ply:Nick()) or sTargetSteamId
		ULib.tsayError(pAdmin, sPlyIdentifier .. " doesn't have any pending slays.", true)

		return false
	else
		local iNewSlayCount = tonumber(slayQuery["slays"]) - iSlaysAddRem
		local newCount = getrecentslaycount(sTargetSteamId) - math.min(iSlaysAddRem, tonumber(slayQuery["slays"]))
		sql.Query(string.format("DELETE FROM gmcore_slaycount WHERE steamid = %s", sql.SQLStr(sTargetSteamId)))
		for i = 1, newCount do
			sql.Query(string.format("INSERT INTO gmcore_slaycount (steamid, round) VALUES (%s, %s);", sql.SQLStr(sTargetSteamId),
				currentround))
		end

		sql.Query(string.format("UPDATE gmcore_slays SET slays = %i WHERE steamid = %s", iNewSlayCount,
			sql.SQLStr(sTargetSteamId)))
		local sChatMessage = ""
		if target_ply then
			if iNewSlayCount >= 1 then
				sChatMessage = "#A removed " .. iSlaysAddRem .. " round(s) of slaying from #T."
			else
				sql.Query(string.format("DELETE FROM gmcore_slays WHERE steamid = %s", sql.SQLStr(sTargetSteamId)))
				sChatMessage = "#A removed all round(s) of slaying from #T."
			end

			ulx.fancyLogAdmin(pAdmin, sChatMessage, target_ply, sReason)
		else
			if iNewSlayCount >= 1 then
				sChatMessage = "#A removed " .. iSlaysAddRem .. " round(s) of slaying from #s."
			else
				sql.Query(string.format("DELETE FROM gmcore_slays WHERE steamid = %s", sql.SQLStr(sTargetSteamId)))
				sChatMessage = "#A removed all round(s) of slaying from #s."
			end

			ulx.fancyLogAdmin(pAdmin, sChatMessage, sTargetSteamId, sReason)
		end
		--sql.Query(string.format("UPDATE gmcore_slays SET slays = %i WHERE steamid = %s", iNewSlayCount, sql.SQLStr(v:SteamID())))
	end
end

function ulx.slaynr(calling_ply, target_ply, num_slay, sReason, bIsRSlaynr)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
		return
	end

	if num_slay < 0 then
		ULib.tsayError(calling_ply, "Invalid integer: " .. num_slay .. " specified.", true)

		return
	end

	if not bIsRSlaynr then
		addSlays(target_ply:SteamID(), num_slay, sReason, calling_ply)
	else
		removeSlays(target_ply:SteamID(), num_slay, sReason, calling_ply)
	end
end

local slaynr = ulx.command(CATEGORY_NAME, "ulx slaynr", ulx.slaynr, "!slaynr")
slaynr:addParam { type = ULib.cmds.PlayerArg }
slaynr:addParam { type = ULib.cmds.NumArg, default = 1, max = 16, hint = "rounds", ULib.cmds.optional, ULib.cmds.round }
slaynr:addParam { type = ULib.cmds.StringArg, hint = "reason", ULib.cmds.optional }
slaynr:addParam { type = ULib.cmds.BoolArg, invisible = true }
slaynr:defaultAccess(ULib.ACCESS_ADMIN)
slaynr:help("Slays target(s) for a number of rounds")
slaynr:setOpposite("ulx rslaynr", { _, _, _, _, true }, "!rslaynr")

function ulx.slaynrid(calling_ply, steamId, num_slay, sReason, bIsRSlaynr)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
		return
	end

	steamId = steamId:upper()

	if not ULib.isValidSteamID(steamId) then
		ULib.tsayError(calling_ply, "Invalid steamid.")

		return
	end

	if num_slay < 0 then
		ULib.tsayError(calling_ply, "Invalid integer: " .. num_slay .. " specified.", true)

		return
	end

	if not bIsRSlaynr then
		addSlays(steamId, num_slay, sReason, calling_ply)
	else
		removeSlays(steamId, num_slay, sReason, calling_ply)
	end
end

local slaynrid = ulx.command(CATEGORY_NAME, "ulx slaynrid", ulx.slaynrid, "!slaynrid")
slaynrid:addParam { type = ULib.cmds.StringArg, hint = "steamid" }
slaynrid:addParam { type = ULib.cmds.NumArg, default = 1, max = 16, hint = "rounds", ULib.cmds.optional, ULib.cmds.round }
slaynrid:addParam { type = ULib.cmds.StringArg, hint = "reason", ULib.cmds.optional }
slaynrid:addParam { type = ULib.cmds.BoolArg, invisible = true }
slaynrid:defaultAccess(ULib.ACCESS_ADMIN)
slaynrid:help("Slays target(s) for a number of rounds")
slaynrid:setOpposite("ulx rslaynrid", { _, _, _, _, true }, "!rslaynrid")

hook.Add("TTTBeginRound", "gmcore.ULX.TTTAdmin.SlaysCheck", function()
	local affected_plys = {}

	for _, ply in player.Iterator() do
		local slayQuery = sql.QueryRow(string.format("SELECT * FROM gmcore_slays WHERE steamid = %s AND time < %s LIMIT 1",
			sql.SQLStr(ply:SteamID()), os.time() - 30))                                                                                                             -- Give 30 second delay for slays recently added

		if not slayQuery then continue end                                                                                                                        -- No currently pending slays
		if gmcore.FunRounds.IsRoundFun then
			-- Notify ply their slay is postponed until the next round due to active fun round
			gmcore.chatprint(ply, "Your slay has been postponed until the following round due to an active fun round.")
			continue
		end

		ply:StripWeapons()
		table.insert(affected_plys, ply)

		ply:Kill()
		ply.curSlayRound = true
		ply.curSlayRoundReason = slayQuery["reason"]

		-- Set body to be ID in scoreboard
		local corpse = corpse_find(ply)

		if corpse then
			ply:SetNWBool("body_found", true)

			if string.find(corpse:GetModel(), "zm_", 6, true) then
				corpse:Remove()
			elseif corpse.player_ragdoll then
				corpse:Remove()
			end
		end

		-- Add punishment
		gmcore.AddPunishment(ply, "ASlay", tostring(slayQuery["reason"]), tostring(slayQuery["admin"]))

		-- Check if we need to deincrement slay or if they no longer have any pending slays left
		if tonumber(slayQuery["slays"]) <= 1 then
			-- Nore more pending slays. Delete them from SQL
			sql.Query(string.format("DELETE FROM gmcore_slays WHERE steamid = %s", sql.SQLStr(ply:SteamID())))
		else
			local iNewSlayCount = tonumber(slayQuery["slays"]) - 1
			sql.Query(string.format("UPDATE gmcore_slays SET slays = %i WHERE steamid = %s", iNewSlayCount,
				sql.SQLStr(ply:SteamID())))
		end
	end

	local slay_message

	for i = 1, #affected_plys do
		local ply = affected_plys[i]
		local string_inbetween

		if i > 1 and #affected_plys == i then
			string_inbetween = " and "
		elseif i > 1 then
			string_inbetween = ", "
		end

		string_inbetween = string_inbetween or ""
		slay_message = (slay_message or "") .. string_inbetween
		slay_message = (slay_message or "") .. ply:Nick()
	end

	local slay_message_context

	if #affected_plys == 1 then
		slay_message_context = "was"
	else
		slay_message_context = "were"
	end

	if #affected_plys != 0 then
		ulx.fancyLog("#T " .. slay_message_context .. " slain.", affected_plys)
	end
end)

---Sets 'curSlayRound', which tracks if a player left during a round of slaying, to false if there are no more slays
hook.Add("TTTEndRound", "gmcore.ULX.TTTAdmin.CurSlayRemoval", function()
	for _, v in pairs(player.GetHumans()) do
		local slayQuery = sql.QueryRow(string.format("SELECT * FROM gmcore_slays WHERE steamid = %s LIMIT 1",
			sql.SQLStr(v:SteamID())))

		if not slayQuery then
			v.curSlayRound = false
		end
	end
end)

hook.Add("PlayerDisconnected", "gmcore.TTTAdmin.SlayCurRoundAlert", function(ply)
	if ply.curSlayRound and GetRoundState() == ROUND_ACTIVE then
		-- Reapply the slay for next round using addSlays helper, silent mode
		local reason = ply.curSlayRoundReason or "Left during slay round"
		addSlays(ply:SteamID(), 1, reason, { Nick = function() return "SLAY VOID" end }, true) -- Hacky way to pass a Nick

		for _, a in ipairs(player.GetAll()) do
			if a:HasStaffPerms() then
				ULib.tsayColor(a, true, Color(60, 60, 60), "[", Color(30, 90, 150), "SLAY VOID", Color(60, 60, 60), "]",
					color_white, " Player ", Color(150, 40, 40), ply:Nick(), Color(60, 60, 60), " [", Color(150, 40, 40),
					ply:SteamID(), Color(60, 60, 60), "] ", color_white, "left the server while slain. Slay Reason: ",
					Color(150, 40, 40), reason)
			end
		end
	end
end)

---Forces target(s) to become a specified role
---@param calling_ply Player The player who used the command
---@param target_plys table The player(s) who will have the effects of the command applied to them
---@param target_role string The role that target player(s) will have set
---@param should_silent boolean Hidden, determines whether the output will be silent or not
function ulx.force(calling_ply, target_plys, target_role, should_silent)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_plys = {}
		local starting_credits = GetConVar("ttt_credits_starting"):GetFloat()
		local role
		local role_grammar
		local role_string
		local role_credits

		if target_role == "traitor" or target_role == "t" then
			role, role_grammar, role_string, role_credits = ROLE_TRAITOR, "a ", "traitor", starting_credits
		end

		if target_role == "detective" or target_role == "d" then
			role, role_grammar, role_string, role_credits = ROLE_DETECTIVE, "a ", "detective", starting_credits
		end

		if target_role == "innocent" or target_role == "i" then
			role, role_grammar, role_string, role_credits = ROLE_INNOCENT, "an ", "innocent", 0
		end

		for i = 1, #target_plys do
			local v = target_plys[i]
			local current_role = v:GetRole()

			if ulx.getExclusive(v, calling_ply) then
				ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
			elseif GetRoundState() == 1 or GetRoundState() == 2 then
				ULib.tsayError(calling_ply, "The round has not begun!", true)
			elseif role == nil then
				ULib.tsayError(calling_ply, "Invalid role :\"" .. target_role .. "\" specified", true)
			elseif not v:Alive() then
				ULib.tsayError(calling_ply, v:Nick() .. " is dead!", true)
			elseif current_role == role then
				ULib.tsayError(calling_ply, v:Nick() .. " is already " .. role_string, true)
			else
				v:ResetEquipment()
				RemoveBoughtWeapons(v)
				v:SetRole(role)
				v:SetCredits(role_credits)
				SendFullStateUpdate()
				table.insert(affected_plys, v)
			end
		end

		ulx.fancyLogAdmin(calling_ply, should_silent, "#A forced #T to become the role of " .. role_grammar .. "#s.",
			affected_plys, role_string)
		send_messages(affected_plys, "Your role has been set to " .. role_string .. ".")
	end
end

local force = ulx.command(CATEGORY_NAME, "ulx force", ulx.force, "!force")
force:addParam { type = ULib.cmds.PlayersArg }
force:addParam { type = ULib.cmds.StringArg, completes = ulx.target_role, hint = "Role" }
force:addParam { type = ULib.cmds.BoolArg, invisible = true }
force:defaultAccess(ULib.ACCESS_SUPERADMIN)
force:setOpposite("ulx sforce", { _, _, _, true }, "!sforce", true)
force:help("Force <target(s)> to become a specified role.")

---Returns the loadout weapons for a given role
---@param r number The role of the loadout weapons to be returned
---@return table A table of loadout weapons for the given role
function GetLoadoutWeapons(r)
	local tbl = {
		[ROLE_INNOCENT] = {},
		[ROLE_TRAITOR] = {},
		[ROLE_DETECTIVE] = {}
	}

	for k, w in pairs(weapons.GetList()) do
		if w and type(w.InLoadoutFor) == "table" then
			for _, wrole in pairs(w.InLoadoutFor) do
				table.insert(tbl[wrole], WEPS.GetClass(w))
			end
		end
	end

	return tbl[r]
end

---Removes previously bought weapons from the shop
---@param ply Player The player who will have their bought weapons removed
function RemoveBoughtWeapons(ply)
	for _, wep in pairs(weapons.GetList()) do
		local wep_class = WEPS.GetClass(wep)

		if wep and type(wep.CanBuy) == "table" then
			for _, weprole in pairs(wep.CanBuy) do
				if weprole == ply:GetRole() and ply:HasWeapon(wep_class) then
					ply:StripWeapon(wep_class)
				end
			end
		end
	end
end

---Respawns target(s)
---@param calling_ply Player The player who used the command
---@param target_plys table The player(s) who will have the effects of the command applied to them
---@param should_silent boolean Hidden, determines whether the output will be silent or not
function ulx.respawn(calling_ply, target_plys, should_silent)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_plys = {}

		for i = 1, #target_plys do
			local v = target_plys[i]

			if ulx.getExclusive(v, calling_ply) then
				ULib.tsayError(calling_ply, ulx.getExclusive(v, calling_ply), true)
			elseif GetRoundState() == 1 then
				ULib.tsayError(calling_ply, "Waiting for players!", true)
			elseif v:Alive() and v:IsSpec() then
				-- players arent really dead when they are spectating, we need to handle that correctly
				timer.Remove("traitorcheck" .. v:SteamID())
				v:ConCommand("ttt_spectator_mode 0") -- just incase they are in spectator mode take them out of it  --seems to be a slight delay from when you leave spec and when you can spawn this should get us around that

				timer.Create("respawndelay", 0.1, 0, function()
					local corpse = corpse_find(v) -- run the normal respawn code now

					if corpse then
						corpse_remove(corpse)
					end

					v:SpawnForRound(true)
					v:SetCredits(((v:GetRole() == ROLE_INNOCENT) and 0) or GetConVar("ttt_credits_starting"):GetFloat())
					table.insert(affected_plys, v)
					ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned #T!", affected_plys)
					send_messages(affected_plys, "You have been respawned.")

					if v:Alive() then
						timer.Remove("respawndelay")

						return
					end
				end)
			elseif v:Alive() then
				ULib.tsayError(calling_ply, v:Nick() .. " is already alive!", true)
			else
				timer.Remove("traitorcheck" .. v:SteamID())
				local corpse = corpse_find(v)

				if corpse then
					corpse_remove(corpse)
				end

				v:SpawnForRound(true)
				v:SetCredits(((v:GetRole() == ROLE_INNOCENT) and 0) or GetConVar("ttt_credits_starting"):GetFloat())
				table.insert(affected_plys, v)
			end
		end

		ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned #T!", affected_plys)
		send_messages(affected_plys, "You have been respawned.")
	end
end

local respawn = ulx.command(CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn")
respawn:addParam { type = ULib.cmds.PlayersArg }
respawn:addParam { type = ULib.cmds.BoolArg, invisible = true }
respawn:defaultAccess(ULib.ACCESS_SUPERADMIN)
respawn:setOpposite("ulx srespawn", { _, _, true }, "!srespawn", true)
respawn:help("Respawns <target(s)>.")

---Respawns and teleports target to caller position
---@param calling_ply Player The player who used the command
---@param target_ply Player The player who will have the effects of the command applied to them
---@param should_silent boolean Hidden, determines whether the output will be silent or not
function ulx.respawntp(calling_ply, target_ply, should_silent)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		local affected_ply = {}

		if not calling_ply:IsValid() then
			Msg("You are the console, you can't teleport or teleport others since you can't see the world!\n")

			return
		elseif ulx.getExclusive(target_ply, calling_ply) then
			ULib.tsayError(calling_ply, ulx.getExclusive(target_ply, calling_ply), true)
		elseif GetRoundState() == 1 then
			ULib.tsayError(calling_ply, "Waiting for players!", true)
		elseif target_ply:Alive() and target_ply:IsSpec() then
			timer.Remove("traitorcheck" .. target_ply:SteamID())
			target_ply:ConCommand("ttt_spectator_mode 0") --have to wait for gamemode before doing this

			timer.Create("respawntpdelay", 0.1, 0, function()
				local t = {}
				t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
				t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
				t.filter = target_ply

				if target_ply != calling_ply then
					t.filter = { target_ply, calling_ply }
				end

				local tr = util.TraceEntity(t, target_ply)
				local pos = tr.HitPos
				local corpse = corpse_find(target_ply)

				if corpse then
					corpse_remove(corpse)
				end

				target_ply:SpawnForRound(true)
				target_ply:SetCredits(((target_ply:GetRole() == ROLE_INNOCENT) and 0) or
				GetConVar("ttt_credits_starting"):GetFloat())
				target_ply:SetPos(pos)
				table.insert(affected_ply, target_ply)
				ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned and teleported #T!", affected_ply)
				send_messages(target_ply, "You have been respawned and teleported.")

				if target_ply:Alive() then
					timer.Remove("respawntpdelay")

					return
				end
			end)
		elseif target_ply:Alive() then
			ULib.tsayError(calling_ply, target_ply:Nick() .. " is already alive!", true)
		else
			timer.Remove("traitorcheck" .. target_ply:SteamID())
			local t = {}
			t.start = calling_ply:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
			t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
			t.filter = target_ply

			if target_ply != calling_ply then
				t.filter = { target_ply, calling_ply }
			end

			local tr = util.TraceEntity(t, target_ply)
			local pos = tr.HitPos
			local corpse = corpse_find(target_ply)

			if corpse then
				corpse_remove(corpse)
			end

			target_ply:SpawnForRound(true)
			target_ply:SetCredits(((target_ply:GetRole() == ROLE_INNOCENT) and 0) or
			GetConVar("ttt_credits_starting"):GetFloat())
			target_ply:SetPos(pos)
			table.insert(affected_ply, target_ply)
		end

		ulx.fancyLogAdmin(calling_ply, should_silent, "#A respawned and teleported #T!", affected_ply)
		send_messages(affected_plys, "You have been respawned and teleported.")
	end
end

local respawntp = ulx.command(CATEGORY_NAME, "ulx respawntp", ulx.respawntp, "!respawntp")
respawntp:addParam { type = ULib.cmds.PlayerArg }
respawntp:addParam { type = ULib.cmds.BoolArg, invisible = true }
respawntp:defaultAccess(ULib.ACCESS_SUPERADMIN)
respawntp:setOpposite("ulx srespawntp", { _, _, true }, "!srespawntp", true)
respawntp:help("Respawns <target> to a specific location.")

---Sets the target(s) karma to a given amount
---@param calling_ply Player The player who used the command
---@param target_plys table The player(s) who will have the effects of the command applied to them
---@param amount number The number the target's karma will be set to
function ulx.karma(calling_ply, target_plys, amount)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		for i = 1, #target_plys do
			target_plys[i]:SetBaseKarma(amount)
			target_plys[i]:SetLiveKarma(amount)
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A set the karma for #T to #i", target_plys, amount)
end

local karma = ulx.command(CATEGORY_NAME, "ulx karma", ulx.karma, "!karma")
karma:addParam { type = ULib.cmds.PlayersArg }
karma:addParam { type = ULib.cmds.NumArg, min = 0, max = 10000, default = 1000, hint = "Karma", ULib.cmds.optional, ULib.cmds.round }
karma:defaultAccess(ULib.ACCESS_ADMIN)
karma:help("Changes the <target(s)> Karma.")

---Forces target(s) to and from spectator
---@param calling_ply Player The player who used the command
---@param target_plys table The player(s) who will have the effects of the command applied to them
---@param should_unspec boolean Whether to remove from spectator or add to spectator
function ulx.tttspec(calling_ply, target_plys, should_unspec)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		for i = 1, #target_plys do
			local v = target_plys[i]

			if should_unspec then
				v:ConCommand("ttt_spectator_mode 0")
			else
				v:ConCommand("ttt_spectate")
				v:ConCommand("ttt_spectator_mode 1")
				v:ConCommand("ttt_cl_idlepopup")
			end
		end

		if should_unspec then
			ulx.fancyLogAdmin(calling_ply, "#A forced #T out of spectator.", target_plys)
		else
			ulx.fancyLogAdmin(calling_ply, "#A forced #T to spectate.", target_plys)
		end
	end
end

local tttspec = ulx.command(CATEGORY_NAME, "ulx fspec", ulx.tttspec, "!fspec", true)
tttspec:addParam { type = ULib.cmds.PlayersArg }
tttspec:addParam { type = ULib.cmds.BoolArg, invisible = true }
tttspec:defaultAccess(ULib.ACCESS_ADMIN)
tttspec:setOpposite("ulx unspec", { _, _, true }, "!unspec")
tttspec:help("Forces the <target(s)> to/from spectator.")
------------------------------ Next Round  ------------------------------
ulx.next_round = {}

local function updateNextround()
	table.Empty(ulx.next_round)              -- Don't reassign so we don't lose our refs
	table.insert(ulx.next_round, "traitor")  -- Add "traitor" to the table.
	table.insert(ulx.next_round, "detective") -- Add "detective" to the table.
	table.insert(ulx.next_round, "unmark")
end

-- Add "unmark" to the table.
hook.Add(ULib.HOOK_UCLCHANGED, "ULXNextRoundUpdate", updateNextround)
updateNextround() -- Init
local PlysMarkedForTraitor = {}
local PlysMarkedForDetective = {}

function ulx.nextround(calling_ply, target_plys, next_round)
	local affected_plys = {}
	local unaffected_plys = {}

	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		for i = 1, #target_plys do
			local v = target_plys[i]
			local ID = v:UniqueID()

			if next_round == "traitor" then
				if PlysMarkedForTraitor[ID] == true or PlysMarkedForDetective[ID] == true then
					ULib.tsayError(calling_ply, "that player is already marked for the next round", true)
				else
					PlysMarkedForTraitor[ID] = true
					table.insert(affected_plys, v)
				end
			end

			if next_round == "detective" then
				if PlysMarkedForTraitor[ID] == true or PlysMarkedForDetective[ID] == true then
					ULib.tsayError(calling_ply, "that player is already marked for the next round!", true)
				else
					PlysMarkedForDetective[ID] = true
					table.insert(affected_plys, v)
				end
			end

			if next_round == "unmark" then
				if PlysMarkedForTraitor[ID] == true then
					PlysMarkedForTraitor[ID] = false
					table.insert(affected_plys, v)
				end

				if PlysMarkedForDetective[ID] == true then
					PlysMarkedForDetective[ID] = false
					table.insert(affected_plys, v)
				end
			end
		end

		if next_round == "unmark" then
			ulx.fancyLogAdmin(calling_ply, true, "#A has unmarked #T ", affected_plys)
		else
			ulx.fancyLogAdmin(calling_ply, true, "#A marked #T to be #s next round.", affected_plys, next_round)
		end
	end
end

local nxtr = ulx.command(CATEGORY_NAME, "ulx forcenr", ulx.nextround, "!forcenr")
nxtr:addParam { type = ULib.cmds.PlayersArg }
nxtr:addParam { type = ULib.cmds.StringArg, completes = ulx.next_round, hint = "Next Round", error = "invalid role \"%s\" specified", ULib.cmds.restrictToCompletes }
nxtr:defaultAccess(ULib.ACCESS_SUPERADMIN)
nxtr:help("Forces the target to be a detective/traitor in the following round.")

local function TraitorMarkedPlayers()
	for k, v in pairs(PlysMarkedForTraitor) do
		if v then
			ply = player.GetByUniqueID(k)
			ply:SetRole(ROLE_TRAITOR)
			ply:AddCredits(GetConVar("ttt_credits_starting"):GetFloat())
			ply:ChatPrint("You have been made a traitor by an admin this round.")
			PlysMarkedForTraitor[k] = false
		end
	end
end

hook.Add("TTTBeginRound", "Admin_Round_Traitor", TraitorMarkedPlayers)

local function DetectiveMarkedPlayers()
	for k, v in pairs(PlysMarkedForDetective) do
		if v then
			ply = player.GetByUniqueID(k)
			ply:SetRole(ROLE_DETECTIVE)
			ply:AddCredits(GetConVar("ttt_credits_starting"):GetFloat())
			ply:Give("weapon_ttt_wtester")
			ply:ChatPrint("You have been made a detective by an admin this round.")
			PlysMarkedForDetective[k] = false
		end
	end
end

hook.Add("TTTBeginRound", "Admin_Round_Detective", DetectiveMarkedPlayers)
function ulx.identify(calling_ply, target_ply, unidentify)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		body = corpse_find(target_ply)

		if not body then
			ULib.tsayError(calling_ply, "This player's corpse does not exist!", true)

			return
		end

		if not unidentify then
			ulx.fancyLogAdmin(calling_ply, "#A identified #T's body!", target_ply)
			CORPSE.SetFound(body, true)
			target_ply:SetNWBool("body_found", true)

			if target_ply:GetRole() == ROLE_TRAITOR then
				-- update innocent's list of traitors
				SendConfirmedTraitors(GetInnocentFilter(false))
				SCORE:HandleBodyFound(calling_ply, target_ply)
			end
		else
			ulx.fancyLogAdmin(calling_ply, "#A unidentified #T's body!", target_ply)
			CORPSE.SetFound(body, false)
			target_ply:SetNWBool("body_found", false)
			SendFullStateUpdate()
		end
	end
end

local identify = ulx.command(CATEGORY_NAME, "ulx identify", ulx.identify, "!identify")
identify:addParam { type = ULib.cmds.PlayerArg }
identify:addParam { type = ULib.cmds.BoolArg, invisible = true }
identify:defaultAccess(ULib.ACCESS_SUPERADMIN)
identify:setOpposite("ulx unidentify", { _, _, true }, "!unidentify", true)
identify:help("Identifies a target's body.")

function ulx.removebody(calling_ply, target_ply)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		body = corpse_find(target_ply)

		if not body then
			ULib.tsayError(calling_ply, "This player's corpse does not exist!", true)

			return
		end

		ulx.fancyLogAdmin(calling_ply, "#A removed #T's body!", target_ply)

		if string.find(body:GetModel(), "zm_", 6, true) then
			body:Remove()
		elseif body.player_ragdoll then
			body:Remove()
		end
	end
end

local removebody = ulx.command(CATEGORY_NAME, "ulx removebody", ulx.removebody, "!removebody")
removebody:addParam { type = ULib.cmds.PlayerArg }
removebody:defaultAccess(ULib.ACCESS_SUPERADMIN)
removebody:help("Removes a target's body.")
---[Round Restart]-------------------------------------------------------------------------

function ulx.roundrestart(calling_ply)
	if GetConVar("gamemode"):GetString() != "terrortown" then
		ULib.tsayError(calling_ply, gamemode_error, true)
	else
		ULib.consoleCommand("ttt_roundrestart" .. "\n")
		ulx.fancyLogAdmin(calling_ply, "#A has restarted the round.")
	end
end

local restartround = ulx.command(CATEGORY_NAME, "ulx roundrestart", ulx.roundrestart)
restartround:defaultAccess(ULib.ACCESS_SUPERADMIN)
restartround:help("Restarts the round.")
