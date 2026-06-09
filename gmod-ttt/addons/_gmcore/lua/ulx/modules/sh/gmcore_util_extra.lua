function ulx.stats(calling_ply)
	local base = ((gmcore.ForumsBaseUrl or ""):gsub("/+$", ""))
	calling_ply:SendLua(string.format([[gui.OpenURL(%q .. LocalPlayer():SteamID64())]], base .. "/gl/stats?steamid="))
end

local stats = ulx.command("GL", "ulx stats", ulx.stats, "!stats")
stats:defaultAccess(ULib.ACCESS_ALL)
stats:help("Display your TTT stats.")

local function getrtttime()
	local tmp = Damagelog.Time
	local s = tmp % 60
	tmp = math.floor(tmp / 60)
	local m = tmp % 60

	return string.format("Round started %02i minutes and %02i seconds ago", m, s)
end

function ulx.rtt(calling_ply)
	if GetRoundState() ~= ROUND_ACTIVE then
		calling_ply:ChatPrint("The round is not active right now!")
	else
		calling_ply:ChatPrint(getrtttime())
	end
end
local rtt = ulx.command( "TTT", "ulx rtt", ulx.rtt, "!rtt")
rtt:defaultAccess( ULib.ACCESS_SUPERADMIN )
rtt:help( "Checks how long the round has been going." )

function ulx.unstuck(calling_ply, target_ply)
	if !target_ply:Alive() or target_ply:IsSpec() then -- If STILL not available...
		ULib.tsayError(calling_ply, "Target is not alive.", true)
		return
	end

	local tMapSpawnPositions = ents.FindByClass("info_player_*")
	local randomChosenSpawn = tMapSpawnPositions[math.random(1, #tMapSpawnPositions)]
	target_ply:SetPos(randomChosenSpawn:GetPos())
	target_ply:SetEyeAngles(randomChosenSpawn:GetAngles())

	ulx.fancyLogAdmin(calling_ply, "#A unstucked #T", target_ply)
end

local unstuck = ulx.command("GL Utility", "ulx unstuck", ulx.unstuck, "!unstuck")
unstuck:addParam{type=ULib.cmds.PlayerArg}
unstuck:defaultAccess(ULib.ACCESS_ADMIN)
unstuck:help("If a player is stuck in the map, moves them to a proper place.")

function ulx.gban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Cannot ban a bot", true )
		return
	end

	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned #T globally " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.kickban, target_ply, minutes, reason, calling_ply, true )
end

local gban = ulx.command( "Utility", "ulx gban", ulx.gban, "!gban" )
gban:addParam{ type=ULib.cmds.PlayerArg }
gban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
gban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
gban:defaultAccess( ULib.ACCESS_SUPERADMIN )
gban:help( "Bans target globally (All GL Servers)." )

function ulx.gbanid( calling_ply, steamid, minutes, reason )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	local name, target_ply
	local plys = player.GetAll()
	for i=1, #plys do
		if plys[ i ]:SteamID() == steamid then
			target_ply = plys[ i ]
			name = plys[ i ]:Nick()
			break
		end
	end

	if target_ply and (target_ply:IsListenServerHost() or target_ply:IsBot()) then
		ULib.tsayError( calling_ply, "This player is immune to banning", true )
		return
	end

	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned steamid #s globally "
	local displayid = steamid
	if name then
		displayid = displayid .. "(" .. name .. ") "
	end
	str = str .. time
	if reason and reason ~= "" then str = str .. " (#4s)" end
	ulx.fancyLogAdmin(calling_ply, str, steamid, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall(ULib.addBan, steamid, minutes, reason, name, calling_ply, true)
end

local gbanid = ulx.command( "Utility", "ulx gbanid", ulx.gbanid )
gbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
gbanid:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
gbanid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
gbanid:defaultAccess( ULib.ACCESS_SUPERADMIN )
gbanid:help( "Bans steamid globally (All GL Servers)." )

function ulx.ungban(calling_ply, steamid)
	steamid = steamid:upper()

	if !ULib.isValidSteamID(steamid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")

		return
	end

	gmcore.RemoveGlobalBan(steamid)

	if name then
		ulx.fancyLogAdmin(calling_ply, "#A globally unbanned steamid #s", steamid .. " (" .. name .. ")")
	else
		ulx.fancyLogAdmin(calling_ply, "#A globally unbanned steamid #s", steamid)
	end
end

local ungban = ulx.command(CATEGORY_NAME, "ulx ungban", ulx.ungban, "!ungban", false, false, true)
ungban:addParam{type = ULib.cmds.StringArg, hint = "steamid"}
ungban:defaultAccess(ULib.ACCESS_ADMIN)
ungban:help("Unbans steamid from al GL servers.")
