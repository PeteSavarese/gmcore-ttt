---AFK alert module: notifies staff when the last remaining traitor is AFK.

util.AddNetworkString("gmcore.afk.alert")
util.AddNetworkString("gmcore.afk.alert.reject")

net.Receive("gmcore.afk.alert", function(len, ply)
	if !IsValid(ply) or !ply:IsPlayer() then return end

	local plyAll = player.GetAll() -- Cache since we don't need to call this twice on pratically the same tick
	local idle = net.ReadInt(10)
	local traitorCount = 0

	for _, p in ipairs(plyAll) do
		if p:IsAlive() and p:GetTraitor() then
			traitorCount = traitorCount + 1
		end
	end

	if traitorCount != 1 then
		net.Start("gmcore.afk.alert.reject")
		net.WriteInt(1)
		net.Send(ply)

		return
	end

	for _, p in ipairs(plyAll) do
		if p:HasStaffPerms() and (!p:Alive() or !p:IsTerror()) then
			p:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " has been AFK for " .. idle .. " seconds and is the last Traitor!")
		end
	end
end)
