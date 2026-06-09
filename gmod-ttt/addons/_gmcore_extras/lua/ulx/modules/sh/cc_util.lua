---------------------------------------------------
--  This file holds client and server utilities  --
---------------------------------------------------
function ulx.give(calling_ply, target_plys, entity, should_silent)
	for k, v in pairs(target_plys) do
		if (not v:Alive()) then
			ULib.tsayError(calling_ply, v:Nick() .. " is dead!", true)
			-- Is the player frozen?
			-- Is the player in a vehicle?
		elseif v:IsFrozen() then
			ULib.tsayError(calling_ply, v:Nick() .. " is frozen!", true)
		elseif v:InVehicle() then
			ULib.tsayError(calling_ply, v:Nick() .. " is in a vehicle.", true)
		else
			v:Give(entity)
		end -- Is the player dead?
	end

	if should_silent then
		ulx.fancyLogAdmin(calling_ply, true, "#A gave #T #s", target_plys, entity)
	else
		ulx.fancyLogAdmin(calling_ply, "#A gave #T #s", target_plys, entity)
	end
end

local give = ulx.command("Custom", "ulx give", ulx.give, "!give")
give:addParam{type = ULib.cmds.PlayersArg}
give:addParam{type = ULib.cmds.StringArg, hint = "entity"}
give:addParam{type = ULib.cmds.BoolArg,invisible = true}
give:defaultAccess(ULib.ACCESS_ADMIN)
give:help("Give a player an entity")
give:setOpposite("ulx sgive", {_, _, _, true}, "!sgive", true)

function ulx.maprestart(calling_ply)
	timer.Simple(1, function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end) -- Wait 1 second so players can see the log

	ulx.fancyLogAdmin(calling_ply, "#A forced a mapchange")
end

local maprestart = ulx.command("Custom", "ulx maprestart", ulx.maprestart, "!maprestart")
maprestart:defaultAccess(ULib.ACCESS_SUPERADMIN)
maprestart:help("Forces a mapchange to the current map.")

function ulx.stopsounds(calling_ply)
	for _, v in ipairs(player.GetAll()) do
		v:SendLua([[RunConsoleCommand("stopsound")]])
	end

	ulx.fancyLogAdmin(calling_ply, "#A stopped sounds")
end

local stopsounds = ulx.command("Custom", "ulx stopsounds", ulx.stopsounds, {"!ss", "!stopsounds"})
stopsounds:defaultAccess(ULib.ACCESS_SUPERADMIN)
stopsounds:help("Stops sounds/music of everyone in the server.")

function ulx.multiban(calling_ply, target_ply, minutes, reason)
	local affected_plys = {}

	for i = 1, #target_ply do
		local v = target_ply[i]

		if v:IsBot() then
			ULib.tsayError(calling_ply, "Cannot ban a bot", true)

			return
		end

		table.insert(affected_plys, v)
		ULib.kickban(v, minutes, reason, calling_ply)
	end

	local time = "for #i minute(s)"

	if minutes == 0 then
		time = "permanently"
	end

	local str = "#A banned #T " .. time

	if reason and reason ~= "" then
		str = str .. " (#s)"
	end

	ulx.fancyLogAdmin(calling_ply, str, affected_plys, minutes ~= 0 and minutes or reason, reason)
end

local multiban = ulx.command("Custom", "ulx multiban", ulx.multiban)
multiban:addParam{type = ULib.cmds.PlayersArg}
multiban:addParam{type = ULib.cmds.NumArg, hint = "minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString,min = 0}
multiban:addParam{type = ULib.cmds.StringArg, hint = "reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes = ulx.common_kick_reasons}
multiban:defaultAccess(ULib.ACCESS_ADMIN)
multiban:help("Bans multiple targets.")

if (CLIENT) then
	local on = false -- default off

	local function toggle()
		on = not on

		if on == true then
			print('enabled')
			LocalPlayer():PrintMessage(HUD_PRINTTALK, "Third person mode enabled.")
		else
			print('disabled')
			LocalPlayer():PrintMessage(HUD_PRINTTALK, "Third person mode disabled.")
		end
	end

	hook.Add("ShouldDrawLocalPlayer", "ThirdPersonDrawPlayer", function()
		if on and LocalPlayer():Alive() then
			return true
		end
	end)

	hook.Add("CalcView", "ThirdPersonView", function(ply, pos, angles, fov)
		if on and ply:Alive() then
			local view = {}
			view.origin = pos - (angles:Forward() * 70) + (angles:Right() * 20) + (angles:Up() * 5)
			--view.origin = pos - ( angles:Forward() * 70 )
			view.angles = ply:EyeAngles() + Angle(1, 1, 0)
			view.fov = fov

			return GAMEMODE:CalcView(ply, view.origin, view.angles, view.fov)
		end
	end)

	net.Receive("cc_thirdperson_toggle", function(len, ply)
		toggle()
	end)
end

if (SERVER) then
	util.AddNetworkString("cc_thirdperson_toggle")

	function ulx.thirdperson(calling_ply)
		net.Start("cc_thirdperson_toggle")
		net.Send(calling_ply)
	end

	local thirdperson = ulx.command("Custom", "ulx thirdperson", ulx.thirdperson, {"!thirdperson", "!3p"}, true)
	thirdperson:defaultAccess(ULib.ACCESS_ALL)
	thirdperson:help("Toggles third person mode")
end

function ulx.cleardecals(calling_ply)
	for _, v in ipairs(player.GetAll()) do
		v:ConCommand("r_cleardecals")
	end

	ulx.fancyLogAdmin(calling_ply, "#A cleared decals")
end

local cleardecals = ulx.command("Custom", "ulx cleardecals", ulx.cleardecals, "!cleardecals")
cleardecals:defaultAccess(ULib.ACCESS_ADMIN)
cleardecals:help("Clear decals for all players.")

function ulx.resetmap(calling_ply)
	game.CleanUpMap()
	ulx.fancyLogAdmin(calling_ply, "#A reset the map to its original state")
end

local resetmap = ulx.command("Custom", "ulx resetmap", ulx.resetmap, "!resetmap")
resetmap:defaultAccess(ULib.ACCESS_SUPERADMIN)
resetmap:help("Resets the map to its original state.")

function ulx.bot(calling_ply, number, should_kick)
	if (not should_kick) then
		if number == 0 then
			for i = 1, 256 do
				RunConsoleCommand("bot")
			end
		elseif number > 0 then
			for i = 1, number do
				RunConsoleCommand("bot")
			end
		end

		if number == 0 then
			ulx.fancyLogAdmin(calling_ply, "#A filled the server with bots")
		elseif number == 1 then
			ulx.fancyLogAdmin(calling_ply, "#A spawned #i bot", number)
		elseif number > 1 then
			ulx.fancyLogAdmin(calling_ply, "#A spawned #i bots", number)
		end
	elseif should_kick then
		for k, v in pairs(player.GetAll()) do
			if v:IsBot() then
				v:Kick("")
			end
		end

		ulx.fancyLogAdmin(calling_ply, "#A kicked all bots from the server")
	end
end

local bot = ulx.command("Custom", "ulx bot", ulx.bot, "!bot")
bot:addParam{type = ULib.cmds.NumArg, default = 0, hint = "number", ULib.cmds.optional}
bot:addParam{type = ULib.cmds.BoolArg, invisible = true}
bot:defaultAccess(ULib.ACCESS_ADMIN)
bot:help("Spawn or remove bots.")
bot:setOpposite("ulx kickbots", {_, _, true}, "!kickbots")

function ulx.ip(calling_ply, target_ply)
	calling_ply:SendLua([[SetClipboardText("]] .. tostring(string.sub(tostring(target_ply:IPAddress()), 1, string.len(tostring(target_ply:IPAddress())) - 6)) .. [[")]])
	ulx.fancyLog({calling_ply}, "Copied IP Address of #T", target_ply)
end

local ip = ulx.command("Custom", "ulx ip", ulx.ip, "!copyip", true)
ip:addParam{type = ULib.cmds.PlayerArg}
ip:defaultAccess(ULib.ACCESS_SUPERADMIN)
ip:help("Copies a player's IP address.")

function ulx.fakeban(calling_ply, target_ply, minutes, reason)
	if target_ply:IsBot() then
		ULib.tsayError(calling_ply, "Cannot ban a bot", true)

		return
	end

	local time = "for #i minute(s)"

	if minutes == 0 then
		time = "permanently"
	end

	local str = "#A banned #T " .. time

	if reason and reason ~= "" then
		str = str .. " (#s)"
	end

	ulx.fancyLogAdmin(calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason)
end

local fakeban = ulx.command("Custom", "ulx fakeban", ulx.fakeban, "!fakeban", true)
fakeban:addParam{type = ULib.cmds.PlayerArg}
fakeban:addParam{type = ULib.cmds.NumArg, hint = "minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString,min = 0}
fakeban:addParam{type = ULib.cmds.StringArg, hint = "reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes = ulx.common_kick_reasons}
fakeban:defaultAccess(ULib.ACCESS_SUPERADMIN)
fakeban:help("Doesn't actually ban the target.")

function ulx.profile(calling_ply, target_ply)
	calling_ply:SendLua("gui.OpenURL('http://steamcommunity.com/profiles/" .. target_ply:SteamID64() .. "')")
	ulx.fancyLogAdmin(calling_ply, true, "#A opened the profile of #T", target_ply)
end

local profile = ulx.command("Custom", "ulx profile", ulx.profile, "!profile", true)
profile:addParam{type = ULib.cmds.PlayerArg}
profile:addParam{type = ULib.cmds.BoolArg, invisible = true}
profile:defaultAccess(ULib.ACCESS_ALL)
profile:help("Opens target's profile")

function ulx.dban(calling_ply)
	calling_ply:ConCommand("xgui hide")
	calling_ply:ConCommand("menu_disc")
end

local dban = ulx.command("Custom", "ulx dban", ulx.dban, "!dban")
dban:defaultAccess(ULib.ACCESS_ADMIN)
dban:help("Open the disconnected players menu")

CreateConVar("ulx_hide_notify_superadmins", 0)

function ulx.hide(calling_ply, command)
	if GetConVarNumber("ulx_logecho") == 0 then
		ULib.tsayError(calling_ply, "ULX Logecho is already set to 0. Your commands are hidden!")

		return
	end

	local strexc = false
	local newstr

	if string.find(command, "!") then
		newstr = string.gsub(command, "!", "ulx ")
		strexc = true
	end

	if strexc == false and not string.find(command, "ulx") then
		ULib.tsayError(calling_ply, "Invalid ULX command!")

		return
	end

	local prevecho = GetConVarNumber("ulx_logecho")
	game.ConsoleCommand("ulx logecho 0\n")

	if IsValid(calling_ply) then
		if strexc == false then
			calling_ply:ConCommand(command)
		else
			string.gsub(newstr, "ulx ", "!")
			calling_ply:ConCommand(newstr)
		end
	else
		if strexc == false then
			game.ConsoleCommand(command)
		else
			string.gsub(newstr, "ulx ", "!")
			game.ConsoleCommand(newstr)
		end
	end

	timer.Simple(1, function()
		game.ConsoleCommand("ulx logecho " .. prevecho .. "\n")
	end)

	ulx.fancyLog({calling_ply}, "(HIDDEN) You ran command #s", command)

	if GetConVarNumber("ulx_hide_notify_superadmins") == 1 then
		if calling_ply:IsValid() then
			for k, v in pairs(player.GetAll()) do
				if v:IsSuperAdmin() and v ~= calling_ply then
					ULib.tsayColor(v, false, Color(151, 211, 255), "(HIDDEN) ", Color(0, 255, 0), calling_ply:Nick(), Color(151, 211, 255), " ran hidden command ", Color(0, 255, 0), command)
				end
			end
		end
	end
end

local hide = ulx.command("Custom", "ulx hide", ulx.hide, "!hide", true)
hide:addParam{type = ULib.cmds.StringArg, hint = "command", ULib.cmds.takeRestOfLine}
hide:defaultAccess(ULib.ACCESS_SUPERADMIN)
hide:help("Run a command without it displaying the log echo.")

function ulx.timescale(calling_ply, number, should_reset)
	if not should_reset then
		if number <= 0.1 then
			ULib.tsayError(calling_ply, "Cannot set the timescale at or below 0.1, doing so will cause instability.")

			return
		end

		if number >= 5 then
			ULib.tsayError(calling_ply, "Cannot set the timescale at or above 5, doing so will cause instability")

			return
		end

		game.SetTimeScale(number)
		ulx.fancyLogAdmin(calling_ply, "#A set the game timescale to #i", number)
	else
		game.SetTimeScale(1)
		ulx.fancyLogAdmin(calling_ply, "#A reset the game timescale")
	end
end

local timescale = ulx.command("Custom", "ulx timescale", ulx.timescale, "!timescale")
timescale:addParam{type = ULib.cmds.NumArg, default = 1, hint = "multiplier"}
timescale:addParam{type = ULib.cmds.BoolArg, invisible = true}
timescale:defaultAccess(ULib.ACCESS_SUPERADMIN)
timescale:help("Set the server timescale.")
timescale:setOpposite("ulx resettimescale", {_, _, true})

if (SERVER) then
	hook.Add("ShutDown", "reallyimportanthook", function()
		if game.GetTimeScale() ~= 1 then
			game.SetTimeScale(1)
		end
	end)
end

function ulx.removeragdolls(calling_ply)
	for k, v in pairs(player.GetAll()) do
		v:SendLua([[game.RemoveRagdolls()]])
	end

	ulx.fancyLogAdmin(calling_ply, "#A removed ragdolls")
end

local removeragdolls = ulx.command("Custom", "ulx removeragdolls", ulx.removeragdolls, "!removeragdolls")
removeragdolls:defaultAccess(ULib.ACCESS_ADMIN)
removeragdolls:help("Remove all ragdolls.")

function ulx.friends(calling_ply, target_ply)
	umsg.Start("getfriends", target_ply)
	umsg.Entity(calling_ply)
	umsg.End()
end

local friends = ulx.command("Custom", "ulx friends", ulx.friends, {"!friends", "!listfriends"}, true)
friends:addParam{type = ULib.cmds.PlayerArg}
friends:defaultAccess(ULib.ACCESS_ADMIN)
friends:help("Print a player's connected steam friends.")

if (CLIENT) then
	local friendstab = {}

	usermessage.Hook("getfriends", function(um)
		for k, v in pairs(player.GetAll()) do
			if v:GetFriendStatus() == "friend" then
				table.insert(friendstab, v:Nick())
			end
		end

		net.Start("sendtable")
		net.WriteEntity(um:ReadEntity())
		net.WriteTable(friendstab)
		net.SendToServer()
		table.Empty(friendstab)
	end)
end

if (SERVER) then
	util.AddNetworkString("sendtable")

	net.Receive("sendtable", function(len, ply)
		local calling, tabl = net.ReadEntity(), net.ReadTable()
		local tab = table.concat(tabl, ", ")

		if (string.len(tab) == 0 and table.Count(tabl) == 0) then
			ulx.fancyLog({calling}, "#T is not friends with anyone on the server", ply)
		else
			ulx.fancyLog({calling}, "#T is friends with #s", ply, tab)
		end
	end)
end
