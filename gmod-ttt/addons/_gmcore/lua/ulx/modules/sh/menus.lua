local CATEGORY_NAME = "Menus"

if ULib.fileExists( "lua/ulx/modules/cl/motdmenu.lua" ) or ulx.motdmenu_exists then
	--[[
		Sends Ulib client RPC to player with Spray URL.

		ply - Player ent that should receive the RPC
		isOnSpawn - If we are sending when player initially spawns. Needed because fade-in animation breaks.
	]]
	local function sendMotd(ply, isOnSpawn)
		local shouldShowMotd = GetConVar("ulx_showMotd"):GetString()

		if shouldShowMotd == "0" then return end
		if !ply:IsValid() then return end -- They left, doh!

		ULib.clientRPC(ply, "gmcore.ShowRulesMenu", GetConVar("ulx_motdurl"):GetString(), isOnSpawn)
	end

	function ulx.motd(calling_ply)
		if !calling_ply:IsValid() then
			MsgN("You can't see the rules from the console.")

			return
		end

		if GetConVar("ulx_showMotd"):GetString() == "0" then
			ULib.tsay(calling_ply, "The MOTD has been disabled on this server.")

			return
		end

		if GetConVar("ulx_showMotd"):GetString() == "1" and !ULib.fileExists(GetConVar("ulx_motdfile"):GetString()) then
			ULib.tsay(calling_ply, "The MOTD file couldn't be found.")

			return
		end

		sendMotd(calling_ply, false)
	end

	local motdmenu = ulx.command(CATEGORY_NAME, "ulx motd", ulx.motd, {"!motd", "!rules"})
	motdmenu:defaultAccess(ULib.ACCESS_ALL)
	motdmenu:help("Show TTT Rules.")

	--[[
		Specify that on spawn we set 2nd param to true so fade-in doesn't break
	]]
	hook.Add("PlayerInitialSpawn", "showMotd", function(ply)
		sendMotd(ply, true)
	end)

	if SERVER then
		ulx.convar("showMotd", "2", " <0/1/2/3> - MOTD mode. 0 is off.", ULib.ACCESS_ADMIN)
		ulx.convar("motdurl", "ulyssesmod.net", "MOTD URL to use if ulx showMotd is 3.", ULib.ACCESS_ADMIN)

		--[[
			Dummy function for ULX. This function usually gets admins and addons installed on server. We don't ever use this
		]]
		function ulx.populateMotdData()
		end
	end
end
