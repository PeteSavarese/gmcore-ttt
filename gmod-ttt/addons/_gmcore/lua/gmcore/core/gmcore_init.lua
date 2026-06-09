---@class gmcore
---@field ServerId integer Server ID as defined in servers table
---@field serverName string Server display name
---@field ServerTag string Server tag identifier (e.g. "ttt1")
---@field serverAddr string Server IP address
---@field consoleTag string Console prefix tag (default: "[GMCore]")
---@field InDebug boolean When print is called, shows file and line for debugging
---@field TotalServers integer Total number of servers in the database
---@field Database Database MySQL database connection (mysqloo)

if SERVER then
	gmcore = gmcore -- For compatability incase of accidental capitalization

	-- ServerId, serverName, ServerTag, serverAddr are set by gmcore.Config:Load() in sh_config.lua

	gmcore.consoleTag = "[GMCore]"
	gmcore.InDebug = true -- When print function is called, shows file and line for removing debug prints
	gmcore.TotalServers = 0

	require("mysqloo")
	local dbInfo = gmcore.Config:GetDatabase("core")

	if not dbInfo then
		ErrorNoHaltWithStack("[GMCore INIT] Failed to get database config!")

		return
	end

	---@type Database
	gmcore.Database = mysqloo.connect(dbInfo.ip, dbInfo.username, dbInfo.password, dbInfo.database, dbInfo.port)

	---Called when the core database connection succeeds
	function gmcore.Database:onConnected()
		gmcore.print("[CORE] Database connected")

		local query = gmcore.Database:query("SELECT * FROM servers")

		function query:onSuccess(data)
			for k,v in pairs(data) do
				gmcore.TotalServers = gmcore.TotalServers + 1
			end
		end

		query:start()
	end

	function gmcore.Database:onConnectionFailed(err)
		gmcore.print("[CORE] Database connection issue: " .. err)
	end

	gmcore.Database:connect()
end
