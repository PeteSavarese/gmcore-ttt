util.AddNetworkString("gmcore.ServerHopper.ServerPing")

--[[
	Broadcast every 5 seconds that the server is alive.
]]
timer.Create("gmcore.ServerHopper.TimerAlive", 2, 0, function()
	net.Start("gmcore.ServerHopper.ServerPing")
	net.Broadcast()
end)
