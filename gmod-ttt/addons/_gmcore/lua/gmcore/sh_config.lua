---@class gmcore
---@field Config gmcoreConfig Configuration manager

---@class gmcoreConfig
---@field ServerId number Unique numeric identifier for this server
---@field ServerName string Display name of the server
---@field ServerTag string Short tag used to identify the server in logs and UI
---@field Database table Primary database connection configuration
---@field ForumDatabase table Forum database connection configuration
---@field ForumsBaseUrl string Base URL for forum/web services

gmcore.Config = gmcore.Config or {}

---Loads and validates the configuration from gmcore_config.json
---@return boolean success Whether the config loaded successfully
function gmcore.Config:Load()
	local configPath = "gmcore/gmcore_config.json"
	local configFile = file.Read(configPath, "DATA")

	if not configFile then
		ErrorNoHalt("[GMCore CONFIG] CRITICAL: gmcore_config.json not found! Check data/gmcore/ folder.")

		return false
	end

	local config = util.JSONToTable(configFile)
	if not config then
		ErrorNoHalt("[GMCore CONFIG] CRITICAL: Failed to parse gmcore_config.json! Check JSON syntax.")

		return false
	end

	if not self:ValidateConfig(config) then
		return false
	end

	-- Store config
	self.Data = config

	gmcore.ServerTag = config.server.tag
	gmcore.ServerId = config.server.id
	gmcore.serverName = config.server.name
	gmcore.ForumsBaseUrl = config.forums_base_url or config.forumsBaseUrl or ""
	gmcore.DeployEnv = config.server.deploy_env or config.server.deployEnv or config.server.env
	gmcore.MapRotationFile = config.map_rotation_file or "rotation_list.json"
	gmcore.serverAddr = game.GetIPAddress()

	SetGlobalString("gmcore.ServerTag", gmcore.ServerTag)
	if gmcore.DeployEnv then
		SetGlobalString("gmcore.DeployEnv", tostring(gmcore.DeployEnv))
	end
	if gmcore.ForumsBaseUrl ~= "" then
		SetGlobalString("gmcore.ForumsBaseUrl", tostring(gmcore.ForumsBaseUrl))
	end

	gmcore.print(string.format("[CONFIG] Server: %s (ID: %d, Tag: %s)", gmcore.serverName, gmcore.ServerId, gmcore.ServerTag))

	return true
end

---Validates the configuration structure
---@param config table The parsed config table
---@return boolean valid Whether the config is valid
function gmcore.Config:ValidateConfig(config)
	if not config.server then
		ErrorNoHaltWithStack("[GMCore CONFIG] Missing 'server' section in config!")

		return false
	end

	if not config.server.id or not config.server.name or not config.server.tag then
		ErrorNoHaltWithStack("[GMCore CONFIG] Server section missing required fields (id, name, tag)!")

		return false
	end

	if not config.databases then
		ErrorNoHaltWithStack("[GMCore CONFIG] Missing 'databases' section in config!")

		return false
	end

	if not config.databases.core or not config.databases.forums then
		ErrorNoHaltWithStack("[GMCore CONFIG] Missing database configuration (core or forums)!")

		return false
	end

	local requiredDbFields = {"ip", "username", "password", "database", "port"}
	for dbName, dbConfig in pairs({core = config.databases.core, forums = config.databases.forums}) do
		for _, field in ipairs(requiredDbFields) do
			if not dbConfig[field] then
				ErrorNoHaltWithStack(string.format("[GMCore CONFIG] Database '%s' missing field '%s'!", dbName, field))

				return false
			end
		end
	end

	return true
end

---Gets database configuration
---@param dbName string Database name ("core" or "forums")
---@return table|nil Database config or nil if not found
function gmcore.Config:GetDatabase(dbName)
	if not self.Data or not self.Data.databases then
		ErrorNoHaltWithStack("[GMCore CONFIG] Config not loaded! Call gmcore.Config:Load() first.")

		return nil
	end

	return self.Data.databases[dbName]
end

---Gets forums base URL from config
---@return string|nil Forums base URL or nil if not found
function gmcore.Config:GetForumsBaseUrl()
	if not self.Data then
		ErrorNoHaltWithStack("[GMCore CONFIG] Config not loaded! Call gmcore.Config:Load() first.")

		return nil
	end

	return self.Data.forums_base_url or self.Data.forumsBaseUrl
end

---Gets the full config data
---@return table|nil Config data or nil if not loaded
function gmcore.Config:GetData()
	return self.Data
end

---Log error and create fallback
function gmcore.Config:CreateFallback()
	ErrorNoHaltWithStack("[GMCore CONFIG] CRITICAL: Creating fallback configuration!")

	-- Set minimal fallback values
	gmcore.ServerTag = "fallback"
	gmcore.ServerId = 99
	gmcore.serverName = "FALLBACK MODE"
	gmcore.ForumsBaseUrl = ""
	gmcore.serverAddr = game.GetIPAddress()

	SetGlobalString("gmcore.ServerTag", gmcore.ServerTag)

	-- Alert staff once, not repeatedly
	timer.Simple(5, function()
		for _, ply in player.Iterator() do
			if ply:IsStaffRank() then
				ply:ChatPrint("[GMCore] WARNING: Server running in FALLBACK MODE - Config file missing or invalid!")
				ply:ChatPrint("[GMCore] Contact a developer immediately! Server functionality is LIMITED.")
			end
		end
	end)

	gmcore.print("[CONFIG] ===== FALLBACK MODE ACTIVE =====")
	gmcore.print("[CONFIG] Config file missing or invalid. Check data/gmcore/gmcore_config.json")
	gmcore.print("[CONFIG] Server ID: 99, Server Name: FALLBACK MODE")
end

if SERVER then
	if not gmcore.Config:Load() then
		gmcore.Config:CreateFallback()
	end
end
