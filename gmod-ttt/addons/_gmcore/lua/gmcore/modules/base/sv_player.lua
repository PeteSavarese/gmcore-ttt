util.AddNetworkString("gmcore.PlayerFullyLoaded")
util.AddNetworkString("gmcore.PlayerSpawn")

---Sends the PlayerFullyLoaded net message to the player on initial spawn.
---This is needed since there is no client hook that is run when the player is fully loaded in.
---@param ply Player Player who has initially spawned
local function plyFullyLoadedSent(ply)
	if !IsValid(ply) then return end

	net.Start("gmcore.PlayerFullyLoaded")
	net.WriteEntity(ply)
	net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "gmcore.Player.PlayerFullyLoaded", plyFullyLoadedSent)

---Sends the PlayerSpawn net message to the player on spawn.
---@param ply Player Player who is spawning
local function playerSpawn(ply)
	if !IsValid(ply) then return end

	net.Start("gmcore.PlayerSpawn")
	net.Send(ply)
end

hook.Add("PlayerSpawn", "gmcore.Player.PlayerSpawnNet", playerSpawn)
