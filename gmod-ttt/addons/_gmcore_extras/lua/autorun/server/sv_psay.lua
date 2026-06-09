util.AddNetworkString("gmcore.RequestPSays")

local allowedRanks = {
	["admin"] = true,
	["leadadmin"] = true,
	["developer"] = true,
	["communitymanager"] = true,
	["owner"] = true
}

local allPsay = {}
local i = 1

local function plyPrivateMessageLog(from, to, message)
	allPsay[i] = {
			["fromSteamID"] = tostring(from:SteamID()),
			["toSteamID"] = tostring(to:SteamID()),
			["fromNick"] = tostring(from:Nick()),
			["toNick"] = tostring(to:Nick()),
			["message"] = tostring(message),
			["ostime"] = 	os.time()
		}
	i = i + 1
end

hook.Add("gmcore.Admin.PSayTracker", "plyPsayTrack", plyPrivateMessageLog)


net.Receive("gmcore.RequestPSays", function(len, ply)
	if !allowedRanks[ply:GetUserGroup()] then return end

	net.Start("gmcore.RequestPSays")
	net.WriteTable(allPsay)
	net.Send(ply)
end)
