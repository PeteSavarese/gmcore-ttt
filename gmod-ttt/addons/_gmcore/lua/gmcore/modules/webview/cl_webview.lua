-- Credit autumngmod@2025
-- WebView is a library that allows you to easily
-- create Web UI for Garry's Mod without thinking about the details.
-- Modified for Giant's Lair

do
	local platform = system.IsWindows() and "win64.dll" or "linux64.dll"
	local prefix = SERVER and "gmsv_" or "gmcl_"

	if file.Exists("lua/bin/" .. prefix .. "reqwest_" .. platform, "GAME") then
		require("reqwest")
	end
end

---Use reqwest when available, fall back to http.Fetch.
---@param params { method: string, url: string, success: fun(code:number, body:string, headers:table), failed: fun(err:string) }
local function httpRequest(params)
	if type(reqwest) == "function" then
		reqwest(params)

		return
	end

	http.Fetch(params.url,
		function(body, size, headers, code)
			if params.success then params.success(code, body, headers) end
		end,
		function(err)
			if params.failed then params.failed(err) end
		end
	)
end

gmcore = gmcore or {}
gmcore.WebView = gmcore.WebView or {}

---Client convar to force fetching the latest WebView HTML.
---@type ConVar
local cvarForceLatest = CreateClientConVar(
	"gmcore_webview_force_latest",
	"0",
	true,
	false,
	"Always pull the latest WebView HTML (dev only)"
)

---Returns true when running in local/dev mode or when forced by cvar.
---@return boolean isLocalDev
local function isLocalDevEnv()
	if cvarForceLatest and cvarForceLatest:GetBool() then
		return true
	end

	local deployEnv = string.lower(GetGlobalString("gmcore.DeployEnv", ""))
	if deployEnv == "local" or deployEnv == "dev" or deployEnv == "development" then
		return true
	end

	local serverTag = string.lower(GetGlobalString("gmcore.ServerTag", ""))
	if serverTag ~= "" and (serverTag:find("dev", 1, true) or serverTag:find("local", 1, true)) then
		return true
	end

	return false
end

---@type table<string, fun(webview: WebView)>
gmcore.WebView.std = gmcore.WebView.std or {}
gmcore.WebView.version = "0.1.6"
---Table of WebView panels that will be initialized after player spawned first time
---@type string[] List of WebViews id
gmcore.WebView.preload = gmcore.WebView.preload or {}
---Registered WebViews
---@type table<string, WebView>
gmcore.WebView.webviews = gmcore.WebView.webviews or {}

---DHTMLExtended
---@class DHTMLExtended: DHTML
---@field storage table<string, fun(...): string | number | boolean | nil>
---@field webview WebView
---@field getWebView fun(self: DHTMLExtended): WebView
---@field addCallback fun(self: DHTMLExtended, name: string, callback: fun(...): string | number | boolean | nil)

---@param name string
---@return boolean
local function isValidStdName(name)
	return string.match(name, "^[^.]+%.[^.]+$") ~= nil
end

---Registers std in cream, making it possible to connect it to WebView.
---@param name string Name of std ()
---@param callback fun(webview: WebView)
function gmcore.WebView:registerStd(name, callback)
	if not isValidStdName(name) then
		error("The name of the registered std must be of the form “%s.%s”")
	end

	self.std[name] = callback
end

---WebView
---@class WebView
---@field id string
---@field url string
---@field expressions string[] JS Code that will be executed when DHTML created
---@field methods table<string, fun(...): string | number | boolean | nil>
---@field stds string[]
---@field attached table<string, fun(): Panel>
---@field panel DHTMLExtended | nil DHTML Panel
---@field loaded function | nil
local webview = {}
webview.__index = webview

---Base callback functions available for all created webviews
---@type table<string, fun(path: string): boolean>
local baseCallbackFunctions = {
	["playSurfaceSound"] = function(path)
		if not path or path == "" then return false end

		surface.PlaySound(path)

		return true
	end,
	["luaPrint"] = function(message)
		if not message or message == "" then return false end

		gmcore.DebugPrint(message)

		return true
	end
}

---Named event constants broadcast to all webviews
gmcore.WebView.Events = gmcore.WebView.Events or {
	STORE_RANK_CHANGED = "storeRankChanged",
}

---Broadcasts an event to every currently loaded WebView panel
---@param name string Event name (use gmcore.WebView.Events)
---@param payload table Payload table
function gmcore.WebView:broadcast(name, payload)
	for _, webview in pairs(self.webviews) do
		if not IsValid(webview) then continue end

		webview:event(name, payload)
	end
end

---Creates new versioned WebView object by checking if version exists in `data/gmcore/webviews/${id}/${version}.html` and if so loads.
---If not, fetches manifest.json at url for versioned singlefile HTML location, saves to `data/gmcore/webviews/${id}/${version}.html`, then loads
---@param id string Unique identifier of WebView, used for loading and registing WebView. Should be unique across all WebViews.
---@param url string URL to load in WebView. Do not use index.html directly, use URL to the folder with index.html and manifest.json
---@param version string Version to load that will be checked in manifest.json
---@return WebView webview Created or loaded WebView instance. Initially "about:blank" if version not cached, then switched to correct URL after fetching.
function gmcore.WebView:NewVersioned(id, url, version)
	local localPath = "gmcore/webviews/" .. id .. "/" .. version .. ".html.dat"
	local localUrl = "asset://garrysmod/data/" .. localPath

	local versionPath = "gmcore/webviews/" .. id .. "/" .. version .. ".version.dat"

	local forceLatest = isLocalDevEnv()
	if file.Exists(localPath, "DATA") and not forceLatest then
		local wv = self:new(id, localUrl)
		-- Restore the full version (e.g. "1.0.0-a6e27da") that was saved when the
		-- HTML was first fetched so that getBaseUrl returns the correct image URL.
		wv.fullVersion = file.Read(versionPath, "DATA") or version
		return wv
	end

	local webview = self:new(id, "about:blank")
	local baseUrl = string.Trim(url or "")

	-- Remove trailing slashes from baseUrl
	while string.EndsWith(baseUrl, "/") do
		baseUrl = baseUrl:sub(1, -2)
	end

	local manifestUrl = baseUrl .. "/manifest.json"

	httpRequest({
		method = "GET",
		url = manifestUrl,
		type = "application/json",
		success = function(code, body, _)
			if code != 200 then
				GMCore_MessageDialog("Failed to load manifest.json from " .. manifestUrl .. ": HTTP " .. tostring(code), "WebView Error", "Ok")
				gmcore.print("Failed to load manifest.json from " .. manifestUrl .. ": HTTP " .. tostring(code))

				return
			end

			local manifest = util.JSONToTable(body)
			if not manifest then
				GMCore_MessageDialog("Failed to parse manifest.json from " .. manifestUrl, "WebView Error", "Ok")
				gmcore.print("Failed to parse manifest.json from " .. manifestUrl)

				return
			end

			if not forceLatest and tostring(manifest.version) ~= tostring(version) then
				-- Strip trailing build metadata (e.g. "-669c11c")
				local manifestBaseVersion = tostring(manifest.version):match("^([^%-]+)") or tostring(manifest.version)
				if manifestBaseVersion ~= tostring(version) then
					GMCore_MessageDialog(("Version mismatch for WebView %s: expected %s, got %s"):format(id, version, manifest.version), "WebView Error", "Ok")
					gmcore.print(("Version mismatch for WebView %s: expected %s, got %s. Url fetched: %s"):format(id, version, manifest.version, manifestUrl))

					return
				end
			end

			-- Store full version (e.g. "1.0.0-a6e27da") so getBaseUrl can
			-- construct the correct image URL path, even when the base version
			-- (e.g. "1.0.0") is what sh_config.lua knows about.
			webview.fullVersion = tostring(manifest.version)

			local indexPath = manifest.url or manifest.index or manifest.path or "index.html"
			local indexUrl = indexPath
			if not string.StartWith(indexPath, "http://")
				and not string.StartWith(indexPath, "https://")
				and not string.StartWith(indexPath, "asset://")
			then
				if string.StartWith(indexPath, "/") then
					indexUrl = baseUrl .. indexPath
				else
					indexUrl = baseUrl .. "/" .. indexPath
				end
			end

			indexUrl = indexUrl

			httpRequest({
				method = "GET",
				url = indexUrl,
				type = "text/html",
				success = function(code, body, _)
					if code != 200 then
						GMCore_MessageDialog("Failed to load index.html from " .. indexUrl .. ": HTTP " .. tostring(code), "WebView Error", "Ok")
						gmcore.print("Failed to load index.html from " .. indexUrl .. ": HTTP " .. tostring(code))

						return
					end

					file.CreateDir("gmcore/webviews/" .. id)
					file.Write(localPath, body)
					-- Persist full version so subsequent sessions can restore it without re-fetching the manifest.
					file.Write(versionPath, webview.fullVersion)

					webview:setUrl(localUrl)
				end,
				failed = function(err)
					GMCore_MessageDialog("Failed to load index.html from " .. indexUrl .. ": " .. tostring(err), "WebView Error", "Ok")
					gmcore.print("Failed to load index.html from " .. indexUrl .. ": " .. tostring(err))

					if forceLatest and file.Exists(localPath, "DATA") then
						webview:setUrl(localUrl)
					end
				end
			})
		end,
		failed = function(err)
			GMCore_MessageDialog("Failed to load manifest.json from " .. manifestUrl .. ": " .. tostring(err), "WebView Error", "Ok")
			gmcore.print("Failed to load manifest.json from " .. manifestUrl .. ": " .. tostring(err))

			if forceLatest and file.Exists(localPath, "DATA") then
				webview:setUrl(localUrl)
			end
		end
	})

	return webview
end

---Creates a new unversioned WebView object. This SHOULD NOT be used for versioned
---GL React systems built with vite.
---@param id string Unique identifier of WebView, used for loading and registing WebView. Should be unique across all WebViews.
---@param url string URL to load in WebView.
---@return WebView
function gmcore.WebView:new(id, url)
	local webview = setmetatable({
		id = id,
		url = url,
		expressions = {},
		methods = {},
		stds = {},
		attached = {}
	}, webview)

	return webview
end

---Adds a function that you can call from JavaScript.
---@param name string
---@param callback fun(...): string | number | boolean | nil
function webview:define(name, callback)
	-- If self.panel is valid
	if not IsValid(self) then
		self.methods[name] = callback

		return
	end

	self.panel:addCallback(name, callback)
end

---Executes `JavaScript` code in the panel,
---or queues the execution until the panel is created, and then executes that code.
---This provides guarantees that your code will be executed.
---@param code string
---@return self
function webview:execute(code)
	if not IsValid(self) then
		self.expressions[#self.expressions+1] = code

		return self
	end

	self.panel:QueueJavascript(code)

	return self
end

---@param name string
---@return self
function webview:importStd(name)
	if not gmcore.WebView.std[name] then
		error("Invalid std " .. name .. "!")
	end

	self.stds[#self.stds+1] = name

	return self
end

---Attaches the returned VGUI panel to the HTML block, taking over its width and position.
---@param callback fun(): Panel
---@param blockId string
---@return self
function webview:attach(callback, blockId)
	self.attached[blockId] = callback

	return self
end

---Updates URL of WebView
---@param url string
---@return self
function webview:setUrl(url)
	self.url = url

	if not IsValid(self) then return self end

	self.panel:OpenURL(url)

	for name, callback in pairs(self.methods) do
		self.panel:addCallback(name, callback)
	end

	for _, code in ipairs(self.expressions) do
		self.panel:QueueJavascript(code)
	end

	-- for _, name in ipairs(self.stds) do
		-- local std = cream.std[name]

		-- std(self)
	-- end

	-- for id, callback in pairs(self.attached) do
		-- local panel = callback()
		-- panel:SetParent(self.panel)
		-- todo
	-- end

	return self
end

---Function called after panel loading
---@param callback function
---@return self
function webview:onLoaded(callback)
	self.loaded = callback

	return self
end

--- Generates path to the ``index.html.dat`` of current WebView.\
--- Relative to ``asset://garrysmod/resource/shared/``
---@private
---@return string ``asset://garrysmod/resource/shared/${id}/index.html.dat``
function webview:generateUrl()
	return "asset://garrysmod/resource/shared/" .. self.id .. "/index.html.dat"
end

--- Returns DHTML panel (if it already created)
---@return DHTML | nil
function webview:getPanel()
	return self.panel
end

---_G.IsValid compatibility
---@private
---@return boolean
function webview:IsValid()
	return IsValid(self.panel)
end

---Alias for ``cream:load(webview)``
---@return self
function webview:load()
	gmcore.WebView:load(self)

	return self
end

---Sends an event to JavaScript
---@param name string Name of the event
---@param payload table Payload
function webview:event(name, payload)
	local jsoned = util.TableToJSON(payload)

	-- ¯\_(ツ)_/¯
	local event = ("new CustomEvent('%s', { detail: %s })"):format(name, jsoned)
	local code = ("window.dispatchEvent(%s)"):format(event)

	self:execute(code)
end

-- Panel managment

--- Creates DHTML panel on player's screen\
--- If ``cream.preload`` (creation queue) exists, it places itself in it\
--- If not, the panel is created immediately
---@param webview WebView
function gmcore.WebView:load(webview)
	local id = webview.id

	local cached = self.webviews[id]
	if IsValid(cached) then
		cached:getPanel():Remove()
	end

	self.webviews[id] = webview

	-- Always register base callbacks into self.methods so they're  available
	-- on a deferred setUrl() call
	for name, func in pairs(baseCallbackFunctions) do
		webview:define(name, func)
	end

	if self.preload and not table.HasValue(self.preload, id) then
		if webview.url:sub(1, 8) ~= "asset://" then -- ¯\_(ツ)_/¯
			timer.Simple(0, function()
				self:create(id)
			end)

			return
		end

		self.preload[#self.preload+1] = id
		self:create(id)

		return
	end

	self:create(id)
end

--- `INTERNAL` Creates DHTML on player's screen\
--- `You don't have to use it!`
---@private
---@param id string WebView's id
---@return DHTMLExtended
function gmcore.WebView:create(id)
	local webview = self:getThrowable(id)

	-- If DHTML already created
	if IsValid(webview) then
			webview:getPanel():Remove()
	end

	---@type DHTML
	local dhtml = vgui.Create("DHTML")
	dhtml:Dock(FILL) -- autosizing

	self:setupWebView(webview, dhtml)

	return panel
end

---`INTERNAL` Provides interface between Lua and JS (API)\
---`You don't have to use it!`
---@private
---@param webview WebView
---@param panel DHTML
---@return DHTMLExtended
function gmcore.WebView:setupWebView(webview, panel)
	---@cast panel DHTMLExtended

	-- Storage
	---@private
	panel.storage = {}

	---@private
	panel.webview = webview

	panel.getWebView = function(self)
		return self.webview
	end

	panel.addCallback = function(self, name, callback)
		self.storage[name] = callback
	end

	panel.OnDocumentReady = function(self, url)
		if webview.loaded then
			webview.loaded(webview)
		end
	end

	panel:AddFunction("lua", "call", function(...)
		local args = { ... }
		local func = args[1]
		local callback = panel.storage[func]

		if not callback then
			-- todo @ throw error to js if not found
			return
		end

		-- removing callback function name
		table.remove(args, 1)

		return callback(unpack(args))
	end)

	webview.panel = panel
	webview:setUrl(webview.url)

	return panel
end

---Returns WebView if it exists
---@param id string
---@return WebView | nil
function gmcore.WebView:get(id)
	return self.webviews[id]
end

---Returns WebView, throws error if it not exists in ``self.webviews``
---@param id string
---@return WebView
function gmcore.WebView:getThrowable(id)
	local webview = self.webviews[id]

	if not webview then
		error("WebView " .. id .. " not found!")
	end

	return webview
end

timer.Simple(0, function()
	for index, v in ipairs(gmcore.WebView.preload) do
		local webview = gmcore.WebView:get(v)

		if not webview then
			print("Webview \"" .. tostring(v) .. "\" not found")

			continue
		end

		webview:load()

		table.remove(gmcore.WebView.preload, index)
	end
end)
