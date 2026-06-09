---Server heartbeat module: writes a timestamp file periodically.
---The script from our docker container watchdog monitors this file and restarts the server if it stops updating.
---Paused when debugger is active to prevent watchdog from killing server during breakpoints.

---@type string
local HEARTBEAT_FILE = "gmcore/healthcheck_heartbeat.txt"
---@type number
local HEARTBEAT_INTERVAL = 5
---@type string
local DEBUG_STATUS_FILE = "gmcore/debug_active.txt"

if not file.Exists("gmcore", "DATA") then
	file.CreateDir("gmcore")
end

---Writes the current timestamp to the heartbeat file (skips if debugger is active).
local function WriteHeartbeat()
	local isDebugActive = GMCORE_IsDebuggerActive and GMCORE_IsDebuggerActive() or false

	if isDebugActive then
		file.Write(DEBUG_STATUS_FILE, "1")
		gmcore.DebugPrint("Heartbeat paused - debugger is active")

		return
	else
		if file.Exists(DEBUG_STATUS_FILE, "DATA") then
			file.Delete(DEBUG_STATUS_FILE)
		end
	end

	local timestamp = os.time()
	local success = file.Write(HEARTBEAT_FILE, tostring(timestamp))

	if success then
		gmcore.DebugPrint("Heartbeat written: " .. timestamp .. " to data/" .. HEARTBEAT_FILE)
	else
		gmcore.print("ERROR: Failed to write heartbeat!")
	end
end

timer.Create("gmcore.HealthCheck.Heartbeat", HEARTBEAT_INTERVAL, 0, function()
	WriteHeartbeat()
end)

WriteHeartbeat()
