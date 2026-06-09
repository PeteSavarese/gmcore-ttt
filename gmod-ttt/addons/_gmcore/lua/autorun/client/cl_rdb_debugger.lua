--[[
	GMod Remote Debugger (https://github.com/danielga/vscode-gmrdb)
--]]

local DEBUG_ACTIVE = false
local DEBUG_PORT = 21110
local PERSIST_FILE = "rdb_state.txt"

---Check if the remote debugger is currently active
---@return boolean isActive True if the remote debugger is currently running
function GMCORE_IsDebuggerActive()
	return DEBUG_ACTIVE
end

local success = false
do
	local platform = system.IsWindows() and "win64.dll" or "linux64.dll"
	if file.Exists("lua/bin/gmcl_rdb_" .. platform, "GAME") then
		success = pcall(require, "rdb")
	end
end

if not success or not rdb then
	return
end

---Save debugger state to disk for persistence across map changes
---@param enabled boolean Whether debugger is active
---@param port number Debugger port number
local function saveState(enabled, port)
	file.Write(PERSIST_FILE, util.TableToJSON({ enabled = enabled, port = port }))
end

---Load saved debugger state from disk
---@return boolean enabled Whether debugger was active
---@return number port Debugger port number
local function loadState()
	if file.Exists(PERSIST_FILE, "DATA") then
		local content = file.Read(PERSIST_FILE, "DATA")

		if content then
			local state = util.JSONToTable(content)

			return state and state.enabled, state and state.port or DEBUG_PORT
		end
	end

	return false, DEBUG_PORT
end

---Activate the remote debugger on the given port.
---Server will pause until VSCode attaches.
---@param port number Port to listen on
local function activeDebugger(port)
	if DEBUG_ACTIVE then
		print("[RDB] Debugger is already active!")

		return
	end

	print("[RDB] Starting remote debugger on port " .. port .. "...")
	print("[RDB] Server will pause until VSCode debugger attaches (F5)")

	rdb.activate(port)

	DEBUG_ACTIVE = true
	DEBUG_PORT = port

	saveState(true, port)
	print("[RDB] Debugger attached! Server resumed.")
end

-- Load saved state and auto-activate if previously enabled
local saved_enabled, saved_port = loadState()
if saved_enabled then
	timer.Simple(1, function()
		print("[RDB] Auto-activating debugger from saved state...")
		activeDebugger(saved_port)
	end)
else
	print("[RDB] Debugger module loaded. Use 'rdb_activate' to start debugging.")
end

concommand.Add("rdb_activate", function(ply, cmd, args)
	local port = tonumber(args[1]) or DEBUG_PORT
	activeDebugger(port)
end)

concommand.Add("rdb_deactivate", function(ply, cmd, args)
	if not DEBUG_ACTIVE then
		print("[RDB] Debugger is already inactive.")

		return
	end

	DEBUG_ACTIVE = false
	saveState(false, DEBUG_PORT)
	print("[RDB] Debugger deactivated. Will not auto-start on next map/restart.")
	print("[RDB] Note: Current debugging session will continue until you detach VSCode.")
end)

concommand.Add("rdb_status", function(ply, cmd, args)
	if IsValid(ply) then return end

	if DEBUG_ACTIVE then
		print("[RDB] Debugger is ACTIVE on port " .. DEBUG_PORT)
		print("[RDB] Will auto-start on map changes and server restarts.")
	else
		print("[RDB] Debugger is INACTIVE. Use 'rdb_activate' to start.")
	end
end)
