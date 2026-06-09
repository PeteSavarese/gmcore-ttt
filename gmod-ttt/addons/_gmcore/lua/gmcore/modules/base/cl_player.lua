---Client-side player lifecycle hooks. Receives net messages and fires client hooks.
--[[
	This is needed since there is no client hook that is run when the player is fully loaded in
]]
net.Receive("gmcore.PlayerFullyLoaded", function()
	hook.Run("gmcore.PlayerFullyLoaded")
end)

net.Receive("gmcore.PlayerSpawn", function()
	hook.Run("PlayerSpawnClient")
end)
