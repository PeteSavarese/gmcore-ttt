---@class gmcore
---@field modules table<string, gmcoreModule> Loaded modules by name
---@field module_init_order gmcoreModule[] Module init order
---@field LoadModule fun(self: gmcore, path: string, name: string, from?: string) Load a module by name
---@field LoadModules fun(self: gmcore) Discover and load all modules
---@field InitModules fun(self: gmcore) Initialize all loaded modules

---@class gmcoreModule
---@field name string Module name
---@field initialized boolean Whether the module has been initialized
---@field depends? string[] Module dependencies
---@field Initialize? fun(self: gmcoreModule) Called after all modules are loaded
gmcore.modules = gmcore.modules or {}
gmcore.module_init_order = gmcore.module_init_order or {}

---Load a module from the given path by name. Handles dependency resolution,
---shared/server/client file includes, and VGUI registration.
---@param path string Base path (e.g. "gmcore/modules/")
---@param name string Module directory name
---@param from? string Name of the module that triggered this load (for dependency chains)
function gmcore:LoadModule(path, name, from)
	if self.modules[name] then return end
	if name == "__ignore" then return end

	if SERVER then gmcore.print("Loading module", name , (from and ("from: " .. from) or "")) end

	local sv_init = path .. name .. "/sv_" .. name .. ".lua"
	local sh_init = path .. name .. "/sh_" .. name .. ".lua"
	local cl_init = path .. name .. "/cl_" .. name .. ".lua"
	local vgui_path = path .. name .. "/vgui/"
	local meta_file = path .. name .. "/module.lua"

	MODULE = {}
	MODULE.name = name
	MODULE.initialized = false

	local depends = {}
	if file.Exists(meta_file, "LUA") then
		AddCSLuaFile(meta_file)
		depends = include(meta_file)

		MODULE.depends = depends
	end

	for k, v in pairs(depends) do
		if not self.modules[v] and v ~= name then
			if from and table.HasValue(depends, from) then
				continue
			end
		end

		self:LoadModule(path, v, name)
	end

	-- Shared files
	if file.Exists(sh_init, "LUA") then
		AddCSLuaFile(sh_init)
		include(sh_init)
	end

	-- Server files
	if SERVER and file.Exists(sv_init, "LUA") then
		include(sv_init)
	end

	-- Client files
	if file.Exists(cl_init, "LUA") then
		AddCSLuaFile(cl_init)

		if CLIENT then
			include(cl_init)
		end
	end

	local files = file.Find(vgui_path .. "*", "LUA")
	for _, vguiClassName in pairs(files) do
		local vguiClass = vgui_path .. vguiClassName

		if SERVER then AddCSLuaFile(vguiClass) end
		if CLIENT then include(vguiClass) end
	end

	self.modules[name] = MODULE
	table.insert(self.module_init_order, MODULE)

	MODULE = nil
end

---Discover and load all modules from gl/modules/ directory
function gmcore:LoadModules()
	local path = "gmcore/modules/"
	local _, folders = file.Find(path .. "*", "LUA")

	for _, folder in SortedPairs(folders, false) do
		self:LoadModule(path, folder, nil)
	end

	self:InitModules()
end

---Initialize all loaded modules by calling their Initialize function in load order
function gmcore:InitModules()
	for i, module in ipairs(self.module_init_order) do
		if module.Initialize then module.Initialize(module) end
		module.initialized = true
	end
end

if CLIENT then
	CreateClientConVar = CreateClientConVar or CreateConVar
	CreateClientConVar("gmcore_debug", "1", FCVAR_ARCHIVE)

	-- Sync convar to match persisted file value on first load,
	-- rather than overwriting file value with convar default.
	timer.Simple(0, function()
		local cvar = GetConVar("gmcore_debug")
		if cvar then
			RunConsoleCommand("gmcore_debug", gmcore.Debug.Enabled and "1" or "0")
		end
	end)

	cvars.AddChangeCallback("gmcore_debug", function(_, _, newValue)
		local enabled = newValue == "1" or newValue == "true"
		gmcore.SetDebugEnabled(enabled)
	end, "gmcore_debug")

	local function gmcore_module_debug_autocomplete(cmd, args)
		local out = {}
		local modules = gmcore.modules or {}
		local argstr = tostring(args or "")
		local prefix = string.Trim(argstr:match("^(%S+)") or "")

		if table.Count(modules) == 0 then
			local _, folders = file.Find("gmcore/modules/*", "LUA")
			for _, folder in ipairs(folders or {}) do
				modules[folder] = true
			end
		end

		for name, _ in pairs(modules) do
			if prefix == "" or string.StartWith(name, prefix) then
				table.insert(out, cmd .. " " .. name .. " 1")
				table.insert(out, cmd .. " " .. name .. " 0")
			end
		end

		table.sort(out)
		return out
	end

	concommand.Add("gmcore_module_debug", function(ply, cmd, args)
		local module = args and args[1]
		local val = args and args[2]

		if not module then
			print("Usage: gmcore_module_debug <module> [1/0 | true/false]")
			print("Current modules with debug enabled:")
			for name, enabled in pairs(gmcore.Debug.Modules) do
				if enabled then
					print(" - " .. name)
				end
			end

			return
		end

		if val == "1" or val == "true" then
			gmcore.SetModuleDebug(module, true)
			print("GMCore: debug enabled for module: " .. module)
		elseif val == "0" or val == "false" then
			gmcore.SetModuleDebug(module, false)
			print("GMCore: debug disabled for module: " .. module)
		else
			print("Usage: gmcore_module_debug <module> [1/0 | true/false]")
		end
	end, gmcore_module_debug_autocomplete)
end

if SERVER then
	concommand.Add("gmcore_debug", function(ply, cmd, args)
		local val = args and args[1]

		if val == "1" or val == "true" then
			gmcore.SetDebugEnabled(true)
			print("GMCore: debug enabled")
		elseif val == "0" or val == "false" then
			gmcore.SetDebugEnabled(false)
			print("GMCore: debug disabled")
		else
			print("Usage: gmcore_debug [1/0 | true/false]")
			print("Current debug status: " .. (gmcore.Debug.Enabled and "enabled" or "disabled"))
		end
	end)

	concommand.Add("gmcore_module_debug", function(ply, cmd, args)
		local module = args and args[1]
		local val = args and args[2]

		if not module then
			print("Usage: gmcore_module_debug <module> [1/0 | true/false]")
			print("Current modules with debug enabled:")
			for name, enabled in pairs(gmcore.Debug.Modules) do
				if enabled then
					print(" - " .. name)
				end
			end

			return
		end

		if val == "1" or val == "true" then
			gmcore.SetModuleDebug(module, true)
			print("GMCore: debug enabled for module: " .. module)
		elseif val == "0" or val == "false" then
			gmcore.SetModuleDebug(module, false)
			print("GMCore: debug disabled for module: " .. module)
		else
			print("Usage: gmcore_module_debug <module> [1/0 | true/false]")
		end
	end)
end
