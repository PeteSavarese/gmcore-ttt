---This file overrides gamemode init.lua which allows any admin to restart the round.
---This override only allows server console to run cmd which is done if user has ulx.roundrestart perm.

---Stops all round-related timers.
local function StopRoundTimers()
	timer.Stop("wait2prep")
	timer.Stop("prep2begin")
	timer.Stop("end2prep")
	timer.Stop("winchecker")
end

---Forces a round restart. Only allows server console to run (ulx.roundrestart perm check).
---@param ply Player Player who executed the command (invalid if server console)
---@param command string Console command name that was invoked
---@param args string[] Additional arguments passed to the command
local function ForceRoundRestart(ply, command, args)
	-- Only allow server console to run which means this can only be executed if player has perms to run ulx.roundrestart
	if !IsValid(ply) then
		LANG.Msg("round_restart")
		StopRoundTimers()
		PrepareRound()
	else
		ply:PrintMessage(HUD_PRINTCONSOLE, "This can only be run if you have ulx.roundrestart perms.")
	end
end

hook.Add("Initialize", "gmcore.TTTOverrides.OverrideRoundRestartCmd", function()
	concommand.Add("ttt_roundrestart", ForceRoundRestart)
end)

concommand.Add("ttt_roundrestart", ForceRoundRestart)
