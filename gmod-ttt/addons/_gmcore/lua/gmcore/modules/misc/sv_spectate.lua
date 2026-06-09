-- runs public spectate code when user clicks avatar on scoreboard, see sb_row.lua for client side.

util.AddNetworkString("SB_Spectate")

net.Receive("SB_Spectate", function(len, ply)
	local target = net.ReadEntity()

	if IsValid(target) and target:IsPlayer() and target:IsAlive() and not ply:IsAlive() then
		ply:Spectate(ply.spec_mode or OBS_MODE_CHASE)
		ply:SpectateEntity(target)
	end
end)
