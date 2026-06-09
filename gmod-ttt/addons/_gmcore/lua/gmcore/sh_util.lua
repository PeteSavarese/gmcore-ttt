---Concatenates all arguments as strings separated by tabs
---@param ... any Values to concatenate
---@return string result Tab-separated string of all arguments
local function concat_tostring(...)
	local tbl = { ... } or {}
	local strs = {}

	for i, v in ipairs(tbl) do
		table.insert(strs, tostring(v))
	end

	return table.concat(strs, "\t")
end

---@class gmcoreDebug
---@field Enabled boolean Whether global debug output is enabled
---@field Modules table<string, boolean> Per-module debug flags
gmcore.Debug = gmcore.Debug or {}
if gmcore.Debug.Enabled == nil then gmcore.Debug.Enabled = true end
gmcore.Debug.Modules = gmcore.Debug.Modules or {}

local DEBUG_SAVE_FILE = "gmcore/debug_config.json"

---Load debug config from data/gmcore/debug_config.json (client or server).
function gmcore.DebugLoad()
	if not file.Exists(DEBUG_SAVE_FILE, "DATA") then
		file.CreateDir("gmcore")
		file.Write(DEBUG_SAVE_FILE, "{}")
	end

	local contents = file.Read(DEBUG_SAVE_FILE, "DATA")
	if not contents or contents == "" then return end

	local ok, tbl = pcall(function() return util.JSONToTable(contents) end)
	if not ok or type(tbl) ~= "table" then return end

	if tbl.Enabled ~= nil then gmcore.Debug.Enabled = tbl.Enabled end
	if tbl.Modules and type(tbl.Modules) == "table" then gmcore.Debug.Modules = tbl.Modules end
end

---Save debug config to data/gmcore/debug_config.json (client or server).
function gmcore.DebugSave()
	file.CreateDir("gmcore")

	local out = { Enabled = gmcore.Debug.Enabled, Modules = gmcore.Debug.Modules }
	local ok, json = pcall(function() return util.TableToJSON(out, true) end)
	if not ok or not json then return end

	file.Write(DEBUG_SAVE_FILE, json)
end

gmcore.DebugLoad()

---Enable or disable global debug output
---@param b boolean Whether to enable debug
function gmcore.SetDebugEnabled(b)
	gmcore.Debug.Enabled = not not b
	gmcore.DebugSave()
end

---Enable or disable debug output for a specific module
---@param moduleName string Module name to toggle
---@param b boolean Whether to enable debug for the module
function gmcore.SetModuleDebug(moduleName, b)
	if not moduleName then return end

	gmcore.Debug.Modules[moduleName] = not not b
	gmcore.DebugSave()
end

---Check if debug is enabled for a specific module
---@param moduleName? string Module name to check (nil returns global debug state)
---@return boolean enabled True if debug output is enabled for the specified module
function gmcore.IsModuleDebugEnabled(moduleName)
	if not gmcore.Debug.Enabled then return false end
	if not moduleName then return gmcore.Debug.Enabled end
	if gmcore.Debug.Modules[moduleName] == nil then return false end

	return gmcore.Debug.Modules[moduleName]
end

---Print a debug message with automatic module detection from call stack.
---Respects per-module debug settings. No-op if debug is disabled.
---@param ... any Values to print
function gmcore.DebugPrint(...)
	if not gmcore.Debug.Enabled then return end

	local info = debug.getinfo(2, "S")
	local src = info and (info.short_src or info.source) or "unknown"

	local moduleName = "core"

	-- Detect module from path until gmcore.modules global is loaded. Modules only added AFTER being loaded
	local modFromPath = src:match("gmcore/modules/([^/\\]+)") or src:match("gmcore/modules\\([^/\\]+)")
	if not modFromPath then
		modFromPath = src:match("addons/.*/gmcore/modules/([^/\\]+)") or src:match("addons\\.*\\gmcore\\modules\\([^/\\]+)")
	end

	-- Check if it's from the core folder
	local coreFromPath = src:match("gmcore/core/([^/\\]+)") or src:match("gmcore/core\\([^/\\]+)")
	if not coreFromPath then
		coreFromPath = src:match("addons/.*/gmcore/core/([^/\\]+)") or src:match("addons\\.*\\gmcore\\core\\([^/\\]+)")
	end

	if coreFromPath then
		moduleName = "core"
	elseif modFromPath then
		moduleName = modFromPath
	else
		-- Fallback to existing lookup once modules table is available
		if gmcore.modules then
			for name, _ in pairs(gmcore.modules) do
				if src:find("gmcore/modules/" .. name, 1, true) or src:find("/" .. name .. "/", 1, true) or src:find("\\" .. name .. "\\", 1, true) then
					moduleName = name
					break
				end
			end
		end
	end

	if not gmcore.IsModuleDebugEnabled(moduleName) then return end

	local msg = concat_tostring(...)

	local ok, _ = pcall(function()
		MsgC(Color(255, 255, 255), "[", Color(255, 0, 0), "GMCore", Color(255, 255, 255), "] ")
		MsgC(Color(200, 200, 200), "[", Color(100, 200, 255), moduleName, Color(200, 200, 200), "] ")
		MsgC(Color(255, 255, 255), msg, "\n")
	end)

	if not ok then
		print("[GMCore][" .. moduleName .. "] " .. msg)
	end
end

---Print a message to console with colored [GMCore] prefix
---@param ... any Values to print
function gmcore.Print(...)
	return MsgC(Color(255, 255, 255), "[", Color(255, 0, 0), "GMCore", Color(255, 255, 255), "] ", concat_tostring(...), "\n")
end

-- Backwards compatibility cuz I'll def miss one
gmcore.print = gmcore.print or gmcore.Print

if SERVER then
	util.AddNetworkString("gmcore.chatprint")

	---Send a chat message to a specific player
	---@param ply Player Player to send the message to
	---@param ... any Message parts (strings, Colors, etc.)
	function gmcore.ChatPrint(ply, ...)
		net.Start("gmcore.chatprint")

		local args = { ... }

		net.WriteTable(args)
		net.Send(ply)
	end

	---Send a chat message to all players
	---@param ... any Message parts (strings, Colors, etc.)
	function gmcore.ChatPrintAll(...)
		net.Start("gmcore.chatprint")

		local args = { ... }

		net.WriteTable(args)
		net.Broadcast()
	end

	-- Backwards compatibility
	gmcore.chatprint = gmcore.chatprint or gmcore.ChatPrint
	gmcore.chatprintAll = gmcore.chatprintAll or gmcore.ChatPrintAll
end

if CLIENT then

	net.Receive("gmcore.chatprint", function()
		local args = net.ReadTable()
		gmcore.ChatPrint(unpack(args))
	end)

	---Display a chat message locally with [GMCore] prefix
	---@param ... any Message parts (strings, Colors, etc.)
	function gmcore.ChatPrint(...)
		return chat.AddText(Color(60, 60, 60), "[", CHAT_PRINT_BLUE, "GMCore", Color(60, 60, 60), "] ", Color(255, 255, 255), ...)
	end

	---Display a chat message locally with [GMCore] prefix and an icon
	---@param sSilkIcon string Silk icon name (unused currently)
	---@param ... any Message parts (strings, Colors, etc.)
	function gmcore.ChatPrintIcon(sSilkIcon, ...)
		return chat.AddText(Color(60, 60, 60), "[", CHAT_PRINT_BLUE, "GMCore", Color(60, 60, 60), "] ", Color(255, 255, 255), ...)
	end

	-- Backwards compatibility
	gmcore.chatprint = gmcore.chatprint or gmcore.ChatPrint
	gmcore.chatprinticon = gmcore.chatprinticon or gmcore.ChatPrintIcon
end

/*CreateConVar("gmcore_server_tag", "notset", { FCVAR_ARCHIVE, FCVAR_REPLICATED })

function gmcore.GetServerTag()
	return GetConVar("gmcore_server_tag"):GetString()
end*/
