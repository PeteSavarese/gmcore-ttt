--[[
	pointshop/cl_init.lua
	first file included clientside.
]]--

do
	local platform = system.IsWindows() and "win64.dll" or "linux64.dll"
	local prefix = SERVER and "gmsv_" or "gmcl_"
	if file.Exists("lua/bin/" .. prefix .. "reqwest_" .. platform, "GAME") then
		require("reqwest")
	end
end

include "sh_init.lua"
include "cl_player_extension.lua"
include "cl_ttt_extension.lua"

---@class PSRequirementDefinition
---@field type string Requirement type identifier (e.g. "store_rank", "playtime", "event_playtime").
---@field value any Required value or amount for the requirement.
---@field key string|nil Networked stat key for weapon-based requirements.
---@field event string|nil Event id for event playtime requirements.
---@field weapon string|nil Weapon class for weapon requirements.
---@field description string|nil Optional UI description for the requirement.

---@class PSRequirementInfo
---@field type string Requirement type identifier.
---@field label string Display label for the requirement.
---@field required any Required value or amount.
---@field current any Current value toward the requirement.
---@field met boolean Whether the requirement is met.
---@field progress number|nil Progress ratio (0..1) when applicable.
---@field progressText string|nil Human-readable progress text.
---@field pending boolean|nil Whether the requirement data is still loading.
---@field description string|nil Optional UI description.
---@field requiredMinutes number|nil Required minutes for playtime requirements.
---@field currentMinutes number|nil Current minutes for playtime requirements.
---@field event string|nil Event id for event playtime requirements.
---@field key string|nil Stat key for weapon requirements.
---@field weapon string|nil Weapon class for weapon requirements.

---@type Panel|nil Main shop menu panel
---@type Panel|{ html: WebView|nil }|nil Main shop menu panel, contains .html for webview
PS.ShopMenu = nil
---@type boolean Whether client has received initial spawn data
PS.ReceivedInitialSpawnData = false -- Prevent people from opening PS and buying items when they haven't received their data
---@type table<Player, table<string, CSModel>> Clientside models per player per item
PS.ClientsideModels = {}

---@type string|nil Currently hovered item ID for preview
PS.HoverModel = nil
---@type CSModel|nil Clientside model for hovered item
PS.HoverModelClientsideModel = nil

---@type table<Entity, string[]> Items pending valid player entity
local invalidplayeritems = {}

PS.EventPlaytimeMins = PS.EventPlaytimeMins or {}
PS.EventPlaytimePending = PS.EventPlaytimePending or {}

---@type string|nil Resolved URL for Pointshop Web UI
PS.WebUiResolvedUrl = PS.WebUiResolvedUrl or nil
---@type string|nil Cached version string for Pointshop Web UI
PS.WebUiVersionCached = PS.WebUiVersionCached or nil
---@type boolean Whether Web UI manifest is being fetched
PS.WebUiManifestPending = PS.WebUiManifestPending or false
---@type table<integer, function>|{} Callbacks to run when Web UI manifest is ready
PS.WebUiManifestCallbacks = PS.WebUiManifestCallbacks or {}

local givePointsAvatarCache = {}
local givePointsAvatarPending = {}

local reqwestClient = nil
local reqwestChecked = false

local function getReqwestClient()
	if reqwestChecked then return reqwestClient end

	reqwestChecked = true
	if type(reqwest) == "function" then
		reqwestClient = reqwest

		return reqwestClient
	end

	do
		local platform = system.IsWindows() and "win64.dll" or "linux64.dll"
		local prefix = SERVER and "gmsv_" or "gmcl_"

		if file.Exists("lua/bin/" .. prefix .. "reqwest_" .. platform, "GAME") then
			require("reqwest")
		end
	end

	if type(reqwest) == "function" then
		reqwestClient = reqwest
	end

	return reqwestClient
end

local function httpFetch(url, onSuccess, onFailure)
	local client = getReqwestClient()

	if client then
		client({
			method = "GET",
			url = url,
			success = function(code, body, headers)
				if onSuccess then
					onSuccess(body or "", body and #body or 0, headers or {}, code or 0)
				end
			end,
			failed = function(err)
				if onFailure then onFailure(err) end
			end
		})
		return
	end

	http.Fetch(url, onSuccess, onFailure)
end

---Fetches Steam avatar URL for a given SteamID64 and calls the callback with the URL.
---When avatar is fetched, store cache url and callback and return for any future calls.
---@param steamid64 string SteamID64 of user to fetch avatar for.
---@param fCallback fun(url: string|nil) Callback function to run once avatar URL is fetched.
local function getSteamAvatarBySteamId(steamid64, fCallback)
	if not steamid64 or steamid64 == "" then return end

	if givePointsAvatarCache[steamid64] then
		if fCallback then fCallback(givePointsAvatarCache[steamid64]) end

		return
	end

	if givePointsAvatarPending[steamid64] then return end

	givePointsAvatarPending[steamid64] = true

	httpFetch("https://steamcommunity.com/profiles/" .. steamid64 .. "/?xml=1", function(body)
		local url = body:match("<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>") or body:match("<avatarFull>(.-)</avatarFull>")
		if url and url != "" then
			givePointsAvatarCache[steamid64] = url
		end

		givePointsAvatarPending[steamid64] = nil

		if fCallback then fCallback(url) end
	end, function()
		givePointsAvatarPending[steamid64] = nil
	end)
end

---Extracts SteamID64 from_pos lottery entry/winner payload.
---@param entry table Lottery entry or winner table from lottery dump JSON.
---@return string|nil steamid64 Parsed SteamID64 or nil when missing/invalid.
local function resolveLotterySteamId(entry)
	if type(entry) != "table" then return nil end

	local sid = entry.steamid or entry.steamId or entry.steam_id or entry.steamID

	if sid == nil then return nil end

	sid = tostring(sid)

	if sid == "" then return nil end

	return sid
end

---Ensures lottery entry/winner includes avatar URL, fetching if needed.
---Triggers WebView refresh on lottery tab when async avatar fetch completes.
---@param entry table Lottery entry or winner table to update.
---@param payloadTable table Full lottery payload table used when sending refresh event to WebView.
local function applyLotteryAvatar(entry, payloadTable)
	if type(entry) != "table" then return end
	if entry.avatar_url or entry.avatarUrl then return end

	local sid = resolveLotterySteamId(entry)
	if not sid then return end

	if givePointsAvatarCache[sid] then
		entry.avatar_url = givePointsAvatarCache[sid]

		return
	end

	getSteamAvatarBySteamId(sid, function(url)
		if url and url != "" then
			entry.avatar_url = url
		end

		if PS.ShopMenu and PS.ShopMenu.html then
			PS.ShopMenu.html:event("refreshLotteryTab", { data = util.TableToJSON(payloadTable) })
		end
	end)
end

-- menu stuff

---Builds a serializable item info table for web UI.
---@param itemId string
---@param v PSItem
---@return table
local function getEventTimeWindow(item, eventInfo)
	local beginTime = tonumber(item.begin) or 0
	local endTime = tonumber(item["end"]) or 0
	if eventInfo then
		local eventBegin = tonumber(eventInfo.begin) or 0
		local eventEnd = tonumber(eventInfo["end"]) or 0

		if eventBegin > beginTime then
			beginTime = eventBegin
		end

		if eventEnd > 0 then
			if endTime == 0 then
				endTime = eventEnd
			else
				endTime = math.min(endTime, eventEnd)
			end
		end
	end

	return beginTime, endTime
end

local function getAvailabilityStatus(beginTime, endTime)
	local now = os.time()

	if beginTime > 0 and now < beginTime then
		return false, "upcoming", now
	end

	if endTime > 0 and now > endTime then
		return false, "expired", now
	end

	return true, "active", now
end

local function normalizeMaterialPath(path)
	if not path or path == "" then return "" end

	if string.StartWith(path, "materials/") then
		path = path:sub(11)
	end

	local lower = string.lower(path)
	if string.EndsWith(lower, ".vmt") or string.EndsWith(lower, ".vtf") then
		path = path:sub(1, #path - 4)
	end

	return path
end

local function isImageMaterialPath(path)
	local lower = string.lower(path or "")
	return string.EndsWith(lower, ".png") or string.EndsWith(lower, ".jpg") or string.EndsWith(lower, ".jpeg")
end

local refreshItemData

local function requestEventPlaytime(eventId)
	if not eventId or eventId == "" then return end
	if PS.EventPlaytimePending[eventId] then return end

	PS.EventPlaytimePending[eventId] = true

	if net then
		net.Start("PS_RequestEventPlaytime")
		net.WriteString(eventId)
		net.SendToServer()
	end
end

---Builds normalized requirement info table.
---@param ply Player Player used to resolve rank, playtime, and networked stats.
---@param requirement PSRequirementDefinition Raw requirement definition from config.
---@return PSRequirementInfo info Normalized requirement data.
local function buildRequirementInfo(ply, requirement)
	local info = {
		type = requirement.type
	}

	if requirement.type == "ulx_rank" then
		info.required = tostring(requirement.value or "")
		local isMember = ply:GetNWInt("forumId", 0) != 0

		info.current = isMember and "member" or "guest"
		info.met = (info.required == "member" and isMember) or false
		info.label = info.required == "member" and "Forum member" or ("Rank: " .. info.required)
		info.progress = info.met and 1 or 0
		info.progressText = info.met and "Met" or "Not met"
	elseif requirement.type == "store_rank" then
		local required = tonumber(requirement.value) or 0
		local current = 0
		if ply.GetStoreRank then
			current = tonumber(ply:GetStoreRank()) or 0
		end

		info.required = required
		info.current = current
		info.met = current >= required
		info.label = "Store rank"

		if required > 0 then
			info.progress = math.min(current / required, 1)
			info.progressText = string.format("%d / %d", math.min(current, required), required)
		end
	elseif requirement.type == "playtime" then
		local requiredHours = tonumber(requirement.value) or 0
		local currentMinutes = ply:GetNW2Int("gmcore.PlayTimeMins", 0)

		info.required = requiredHours
		info.requiredMinutes = requiredHours * 60
		info.currentMinutes = currentMinutes
		info.current = currentMinutes / 60
		info.met = currentMinutes >= info.requiredMinutes
		info.label = "Playtime (hours)"

		if info.requiredMinutes > 0 then
			info.progress = math.min(currentMinutes / info.requiredMinutes, 1)
			info.progressText = string.format("%d / %d hours", math.min(math.floor(info.current), requiredHours), requiredHours)
		end
	elseif requirement.type == "event_playtime" then
		local eventId = requirement.event
		local requiredHours = tonumber(requirement.value) or 0

		info.event = eventId
		info.required = requiredHours
		info.requiredMinutes = requiredHours * 60

		local mins = PS.EventPlaytimeMins[eventId]
		if mins == nil then
			requestEventPlaytime(eventId)

			info.pending = true
			mins = -1
		end

		info.currentMinutes = mins
		info.current = mins >= 0 and (mins / 60) or -1
		info.met = mins >= 0 and mins >= info.requiredMinutes or false
		info.label = "Event playtime (hours)"

		if mins >= 0 and info.requiredMinutes > 0 then
			info.progress = math.min(mins / info.requiredMinutes, 1)
			info.progressText = string.format("%d / %d hours", math.min(math.floor(info.current), requiredHours), requiredHours)
		else
			info.progressText = "Loading..."
		end
	elseif requirement.type == "weapon_kills" then
		local key = requirement.key
		local required = tonumber(requirement.value) or 0
		local current = key and ply:GetNWInt(key, 0) or 0

		info.key = key
		info.weapon = requirement.weapon
		info.required = required
		info.current = current
		info.met = current >= required
		info.label = "Weapon kills"

		if required > 0 then
			info.progress = math.min(current / required, 1)
			info.progressText = string.format("%d / %d", math.min(current, required), required)
		end
	elseif requirement.type == "weapon_headshots" then
		local key = requirement.key
		local required = tonumber(requirement.value) or 0
		local current = key and ply:GetNWInt(key, 0) or 0

		info.key = key
		info.weapon = requirement.weapon
		info.required = required
		info.current = current
		info.met = current >= required
		info.label = "Weapon headshots"

		if required > 0 then
			info.progress = math.min(current / required, 1)
			info.progressText = string.format("%d / %d", math.min(current, required), required)
		end
	else
		info.label = "Requirement"
	end

	if requirement.description and type(requirement.description) == "string" then
		info.description = requirement.description
	end

	return info
end

local function buildItemInfo(itemId, v)
	local ply = LocalPlayer()
	local info = {
		psItemId = itemId,
		name = v.Name,
		price = v.Price,
		buyPrice = PS.Config.CalculateBuyPrice(ply, v),
		sellPrice = PS.Config.CalculateSellPrice(ply, v),
		section = v.Section or 0,
		category = v.Category,
		isOwned = ply:PS_HasItem(itemId),
		isEquipped = ply:PS_HasItemEquipped(itemId),
		model = v.Model or "",
		class = v.Class or "",
		material = v.Material or "",
		description = v.Description or "",
		sound = v.Sound or "",
		singleUse = v.SingleUse or false,
		isRankColored = v.IsRankColored or false,
	}

	if v.Event and PS.SkinEventInfo and PS.SkinEventInfo[v.Event] then
		local eventInfo = PS.SkinEventInfo[v.Event]
		local beginTime, endTime = getEventTimeWindow(v, eventInfo)
		local isAvailable, availabilityStatus, now = getAvailabilityStatus(beginTime, endTime)

		info.event = {
			id = v.Event,
			name = eventInfo.name or v.Event,
			begin = beginTime,
			["end"] = endTime,
			available = isAvailable,
			status = availabilityStatus,
			now = now
		}

		info.eventId = v.Event
		info.eventName = eventInfo.name or v.Event
		info.eventBegin = beginTime
		info.eventEnd = endTime
		info.eventAvailable = isAvailable
		info.eventStatus = availabilityStatus
		info.isAvailable = isAvailable
		info.availabilityStatus = availabilityStatus
	elseif v.begin or v["end"] then
		local beginTime, endTime = getEventTimeWindow(v)
		local isAvailable, availabilityStatus, now = getAvailabilityStatus(beginTime, endTime)

		info.event = {
			id = v.Event or "",
			name = v.Event or "",
			begin = beginTime,
			["end"] = endTime,
			available = isAvailable,
			status = availabilityStatus,
			now = now
		}

		info.eventId = v.Event or ""
		info.eventName = v.Event or ""
		info.eventBegin = beginTime
		info.eventEnd = endTime
		info.eventAvailable = isAvailable
		info.eventStatus = availabilityStatus
		info.isAvailable = isAvailable
		info.availabilityStatus = availabilityStatus
	else
		info.isAvailable = true
		info.availabilityStatus = "active"
	end

	if v.Requirements and #v.Requirements > 0 then
		info.requirements = {}
		local allMet = true
		local pending = false

		for _, req in ipairs(v.Requirements) do
			local reqInfo = buildRequirementInfo(ply, req)
			if reqInfo.pending then pending = true end
			if reqInfo.met == false then allMet = false end
			table.insert(info.requirements, reqInfo)
		end

		info.requirementsMet = allMet
		info.requirementsPending = pending
	end

	-- Section-based store rank check
	if info.requirementsMet ~= false then
		if v.Section and isnumber(v.Section) and tonumber(v.Section) > 0 then
			local required = tonumber(v.Section)

			local current = ply.GetStoreRank and tonumber(ply:GetStoreRank()) or 0 or 0
			if current < required then
				info.requirementsMet = false
			end
		end
	end

	local isSkinsCategory = string.lower(v.Category or "") == "skins"
	if info.material and info.material != "" then
		local normalizedMaterial = normalizeMaterialPath(info.material)
		local materialDataPath = "gmcore/materials/pointshop/materials/" .. itemId .. ".png"

		if file.Exists(materialDataPath, "DATA") then
			info.materialPreviewPath = "asset://garrysmod/data/" .. materialDataPath
		elseif normalizedMaterial != "" then
			info.materialPreviewPath = "asset://garrysmod/materials/" .. normalizedMaterial

			if not isImageMaterialPath(normalizedMaterial) and gmcore and gmcore.Icon and gmcore.Icon.QueueMaterialPNG then
				gmcore.Icon:QueueMaterialPNG(normalizedMaterial, itemId, function()
					if refreshItemData then
						refreshItemData(itemId)
					end
				end)
			end
		end
	end

	if isSkinsCategory and v.Class and v.Class != "" then
		local weaponInfo = weapons.Get(v.Class)

		if weaponInfo and weaponInfo.PrintName and weaponInfo.PrintName != "" then
			info.weaponName = weaponInfo.PrintName
		else
			info.weaponName = v.Class
		end

		info.weaponName = LANG.TryTranslation(info.weaponName)
	end

	-- Upgrade info for TTT perks
	if v.UpgradeList and #v.UpgradeList > 0 then
		info.upgradable = true
		info.upgradeLevel = ply:PS_GetUpgradeLevel(itemId)
		info.upgradeMaxLevel = #v.UpgradeList

		if info.upgradeLevel < info.upgradeMaxLevel then
			info.upgradePrice = PS.Config.CalculateUpgradePrice(ply, v)
		else
			info.upgradePrice = 0
		end
	end

	return info
end

---Sends refresh event to web UI for a specific item.
---@param psItemId string Item ID to refresh
refreshItemData = function(psItemId)
	timer.Simple(0.1, function()
		if PS.ShopMenu and PS.ShopMenu.html then
			local itemInfo = nil
			local item = PS.Items[psItemId]
			if item then
				itemInfo = buildItemInfo(psItemId, item)
			end

			PS.ShopMenu.html:event("refreshItemData", {
				action = "item_updated",
				psItemId = psItemId,
				item = itemInfo
			})
		end
	end)
end

local function normalizeBaseUrl(url)
	url = string.Trim(url or "")
	while string.EndsWith(url, "/") do
		url = url:sub(1, -2)
	end
	return url
end

function PS:GetWebUiUrl(callback)
	local baseUrl = normalizeBaseUrl(GetGlobalString("gmcore.Pointshop.WebUiBaseUrl", ""))
	local version = GetGlobalString("gmcore.Pointshop.WebUiVersion", "")

	if baseUrl == "" or version == "" then
		if callback then callback(nil, nil) end

		return
	end

	if self.WebUiResolvedUrl and self.WebUiVersionCached == version then
		if callback then callback(self.WebUiResolvedUrl, { version = version }) end

		return
	end

	local resolvedUrl = baseUrl .. "/pointshop/"

	self.WebUiResolvedUrl = resolvedUrl
	self.WebUiVersionCached = version
	self.WebUiManifestPending = false
	self.WebUiManifestCallbacks = {}

	if callback then callback(resolvedUrl, { version = version }) end
end

---Creates Pointshop WebView and sets up all JS <-> Lua bindings
---@param url string URL to load in WebView
---@param version string Version of WebView to load
---@return WebView webview Created WebView instance
local function createShopWebView(url, version)
	-- Create WebView
	local webview = gmcore.WebView:NewVersioned("pointshop", url, version)

	webview:onLoaded(function(wv)
		if !IsValid(PS.ShopMenu) then return end
		if PS.ShopMenu.Closing then return end -- closed before HTML finished loading

		-- Don't MakePopup here. Think will do it fade-in is complete.
		PS.ShopMenu.WebReady = true
		wv.panel:SetParent(PS.ShopMenu)
		wv.panel:Dock(FILL)
		wv.panel:RequestFocus()

		-- Send initial points to web UI
		wv:event("refreshLocalPlyPoints", {
			points = LocalPlayer():PS_GetPoints()
		})
	end)

	--[[
		Begin Lua callbacks from Web UI
	]]--

	---@luals-desc closes shop panel; called by React after CSS fade-out animation starts
	webview:define("closePanel", function()
		if not IsValid(PS.ShopMenu) then return end
		if PS.ShopMenu.Closing then return end -- already fading, ignore React's callback

		PS.ShopMenu:SetMouseInputEnabled(false) -- return input immediately, before fade-out
		gui.EnableScreenClicker(false)
		PS.ShopMenu.Closing = true
		PS.ShopMenu.RemoveTime = CurTime()
	end)

	---@luals-desc Returns local player's point balance
	webview:define("getPlayerPoints", function()
		return LocalPlayer():PS_GetPoints()
	end)

	---@luals-desc Returns the versioned webserver base URL for loading item images
	webview:define("getBaseUrl", function()
		-- Use the full version from the manifest (e.g. "1.0.0-a6e27da") rather
		-- than PS.Config.WebUiVersion ("1.0.0"). The CI build appends a git SHA
		-- suffix, so the image directory on the server is the full version.
		local fullVersion = webview.fullVersion or version
		return url .. fullVersion .. "/"
	end)

	---@luals-desc Returns store ranks as JSON
	webview:define("getStoreRanks", function()
		local ranks = {}
		local function colorToHex(c)
			if not c then return "#ffffff" end

			return string.format("#%02x%02x%02x", c.r or 255, c.g or 255, c.b or 255)
		end

		ranks["0"] = { name = "Member", color = "#ffffff" }
		if gmcore and gmcore.StoreRank and gmcore.StoreRank.Ranks then
			for idx, data in pairs(gmcore.StoreRank.Ranks) do
				if data and data.name then
					ranks[tostring(idx)] = {
						name = data.name,
						color = colorToHex(data.color or Color(255, 255, 255))
					}
				end
			end
		end

		return util.TableToJSON(ranks)
	end)

	---@luals-desc Returns local player's SteamID64
	webview:define("getLocalPlySteamId", function()
		return LocalPlayer():SteamID64()
	end)

	---@luals-desc Returns local player's SteamID32
	webview:define("getLocalPlySteamId32", function()
		return LocalPlayer():SteamID()
	end)

	---@luals-desc Sends points to another player
	---@param steamid64 string
	---@param points number|string
	webview:define("sendPoints", function(steamid64, points)
		if not steamid64 or steamid64 == "" then return false end
		if steamid64 == LocalPlayer():SteamID64() then return false end

		local amount = math.Clamp(tonumber(points) or 0, 0, 1000000)
		if amount <= 0 then return false end

		local target = nil
		for _, ply in player.Iterator() do
			if IsValid(ply) and ply:SteamID64() == steamid64 then
				target = ply
				break
			end
		end

		if not IsValid(target) then return false end

		net.Start("PS_SendPoints")
			net.WriteEntity(target)
			net.WriteInt(amount, 32)
		net.SendToServer()

		return true
	end)

	---@luals-desc Returns a JSON list of users for give points
	webview:define("getGivePointsUsers", function()
		local users = {}

		for _, ply in player.Iterator() do
			if not IsValid(ply) then continue end

			local steamid64 = ply:SteamID64()
			local avatarUrl = givePointsAvatarCache[steamid64] or ""

			table.insert(users, {
				steamId64 = steamid64,
				name = ply:Nick(),
				avatarUrl = avatarUrl
			})

			if avatarUrl == "" then
				getSteamAvatarBySteamId(steamid64, function(url)
					if PS.ShopMenu and PS.ShopMenu.html and url and url != "" then
						PS.ShopMenu.html:event("givePointsAvatarReady", {
							steamId64 = steamid64,
							avatarUrl = url
						})
					end
				end)
			end
		end

		return util.TableToJSON(users)
	end)

	---@luals-desc Returns JSON of items for a category
	---@param activeTab string
	webview:define("getCategoryItems", function(activeTab)
		local items = {}

		for itemId, v in pairs(PS.Items) do
			if string.lower(v.Category) != activeTab then continue end

			local section = v.Section
			if not section then section = 0 end

			-- Resolve weapon world models lazily
			if (not v.Model or v.Model == "") and v.Class then
				local tWepInfo = weapons.Get(v.Class)

				if tWepInfo and tWepInfo.WorldModel and tWepInfo.WorldModel != "" then
					PS.Items[itemId].Model = tWepInfo.WorldModel
					v.Model = tWepInfo.WorldModel
				end
			end

			local sectionKey = tostring(section)
			if !items[sectionKey] then
				items[sectionKey] = {}
			end

			table.insert(items[sectionKey], buildItemInfo(itemId, v))
		end

		return util.TableToJSON(items)
	end)

	---@luals-desc Plays surface sound
	---@param soundPath string
	webview:define("playSurfaceSound", function(soundPath)
		if not soundPath or soundPath == "" then return false end

		surface.PlaySound(soundPath)

		return true
	end)

	webview:define("purchaseItem", function(psItemId, name)
		if !PS.Items[psItemId] then return false end

		GMCore_DialogQuery(
			"Are you sure you want to buy " .. name .. " for " .. string.Comma(PS.Config.CalculateBuyPrice(LocalPlayer(), PS.Items[psItemId])) .. " points?",
			"Buy Item", "Yes",
			function()
				if PS.Items[psItemId].SingleUse then
					LocalPlayer():PS_BuyWeapon(psItemId)
				else
					LocalPlayer():PS_BuyItem(psItemId)
				end
				refreshItemData(psItemId)
			end,
			"No", function() end
		)

		return true
	end)

	webview:define("sellItem", function(psItemId, name)
		if !PS.Items[psItemId] then return false end

		GMCore_DialogQuery(
			"Are you sure you want to sell " .. name .. " for " .. string.Comma(PS.Config.CalculateSellPrice(LocalPlayer(), PS.Items[psItemId])) .. " points?",
			"Sell Item", "Yes",
			function()
				LocalPlayer():PS_SellItem(psItemId)
				refreshItemData(psItemId)
			end,
			"No", function() end
		)

		return true
	end)

	webview:define("equipItem", function(psItemId)
		if !PS.Items[psItemId] then return false end

		LocalPlayer():PS_EquipItem(psItemId)
		refreshItemData(psItemId)

		return true
	end)

	webview:define("unEquipItem", function(psItemId)
		if !PS.Items[psItemId] then return false end

		LocalPlayer():PS_HolsterItem(psItemId)
		refreshItemData(psItemId)

		return true
	end)

	webview:define("upgradeItem", function(psItemId, name)
		if !PS.Items[psItemId] then return false end

		GMCore_DialogQuery(
		"Are you sure you want to upgrade " .. name .. " for " .. string.Comma(PS.Config.CalculateUpgradePrice(LocalPlayer(), PS.Items[psItemId])) .. " points?",
			"Buy Upgrade", "Yes", function()
			LocalPlayer():PS_UpgradeItem(psItemId)
			refreshItemData(psItemId)
		end, "No", function() end)

		return true
	end)

	webview:define("purchaseLotteryTickets", function(ticketsAmountToBuy)
		if ticketsAmountToBuy <= 0 then return false end

		GMCore_DialogQuery(
			"Are you sure you want to buy " .. ticketsAmountToBuy .. " lottery ticket(s)?",
			"Confirm Tickets Purchase", "Yes",
			function()
				if !LocalPlayer():PS_HasPoints(ticketsAmountToBuy * 100) then
					Derma_Message("You do not have enough points to purchase this many tickets!", "Lottery Ticket Purchase", "Ok")
					return
				end

				net.Start("gmcore.Pointshop.BuyTickets")
				net.WriteInt(ticketsAmountToBuy, 16)
				net.SendToServer()
			end,
			"No", function() end
		)

		return true
	end)

	webview:define("getLotteryData", function()
		local baseUrl = GetGlobalString("gmcore.ForumsBaseUrl", "https://website.com") .. "/gl/lottery/dumpjson"

		local fallback = util.TableToJSON({
			current_jackpot = 0,
			entries = {},
			history_winners = {}
		})

		if not PS.LotteryDataPending then
			PS.LotteryDataPending = true

			httpFetch(baseUrl, function(body)
				PS.LotteryDataPending = false
				local payloadTable = util.JSONToTable(body or "")

				if type(payloadTable) != "table" then
					payloadTable = {
						current_jackpot = 0,
						entries = {},
						history_winners = {}
					}
				end

				if type(payloadTable.entries) != "table" then
					payloadTable.entries = {}
				end

				if type(payloadTable.history_winners) != "table" then
					payloadTable.history_winners = {}
				end

				for _, entry in ipairs(payloadTable.entries) do
					applyLotteryAvatar(entry, payloadTable)
				end

				for _, winner in ipairs(payloadTable.history_winners) do
					applyLotteryAvatar(winner, payloadTable)
				end

				if PS.ShopMenu and PS.ShopMenu.html then
					PS.ShopMenu.html:event("refreshLotteryTab", { data = util.TableToJSON(payloadTable) })
				end
			end, function()
				PS.LotteryDataPending = false
			end)
		end

		return fallback
	end)

	webview:define("getLoadoutData", function()
		if not gmcore.Loadout or not gmcore.Loadout.GetWebLoadoutData then
			return "[]"
		end

		return util.TableToJSON(gmcore.Loadout.GetWebLoadoutData())
	end)

	webview:define("setLoadoutSlot", function(slot, weaponClass)
		LocalPlayer():PS_ChangeLoadout(slot, weaponClass)

		return true
	end)

	webview:define("saveLoadout", function()
		LocalPlayer():PS_UpdateLoadout()

		return true
	end)

	-- Load webview
	PS.ShopMenu.html = webview:load()
end

---Toggles pointshop menu visibility. Creates or destroys WebView panel.
function PS:ToggleMenu()
	if !PS.ReceivedInitialSpawnData then
		GMCore_MessageDialog("Your client hasn't received your pointshop data yet. If you continue to experience this popup, try rejoining.", "Pending Pointshop Data", "Ok")

		return
	end

	-- Close if already open
	if PS.ShopMenu and IsValid(PS.ShopMenu) then
		-- Tell React to start its CSS close animation; it will call closePanel back (ignored via guard).
		if PS.ShopMenu.html then
			PS.ShopMenu.html:event("gl_shop_should_close", {})
		end
		-- Release cursor immediately and fade the background blur in sync.
		PS.ShopMenu:SetMouseInputEnabled(false) -- return input immediately, before fade-out
		gui.EnableScreenClicker(false)
		PS.ShopMenu.Closing = true
		PS.ShopMenu.RemoveTime = CurTime()

		return
	end

	local w = ScrW() * 0.7
	local h = ScrH() * 0.7

	if ScrW() < 1920 then
		w = ScrW()
		h = ScrH()
	elseif ScrW() <= 2560 then
		w = ScrW() * 0.65
		h = ScrH() * 0.8
	end

	PS.ShopMenu = vgui.Create("EditablePanel")
	PS.ShopMenu:SetSize(w, h)
	PS.ShopMenu:Center()
	PS.ShopMenu:SetAlpha(0)
	PS.ShopMenu.CreateTime = CurTime()
	PS.ShopMenu.RemoveTime = 0
	PS.ShopMenu.Closing = false

	PS.ShopMenu.Think = function(s)
		if not s.Closing then
			local frac = math.TimeFraction(s.CreateTime, s.CreateTime + 0.3, CurTime())
			local newAlpha = math.floor(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 255))
			s:SetAlpha(newAlpha)

			-- Take input only once the fade-in is complete and the WebView is ready.
			-- Set to 250 because lerp never truly reaches final value
			if newAlpha >= 250 and s.WebReady and not s.InputEnabled then
				s.InputEnabled = true
				s:SetMouseInputEnabled(true)
				s:MakePopup()
				gui.EnableScreenClicker(true)
			end
		else
			local frac = math.TimeFraction(s.RemoveTime, s.RemoveTime + 0.45, CurTime())
			local newAlpha = math.floor(Lerp(math.ease.InOutQuart(frac), s:GetAlpha(), 0))
			s:SetAlpha(newAlpha)

			if newAlpha <= 0 then
				PS.ShopMenu = nil

				s:Remove()
			end
		end
	end

	PS.ShopMenu.Paint = function(s)
		Derma_DrawBackgroundBlur(s, 0)
	end

	self:GetWebUiUrl(function(resolvedUrl)
		if !IsValid(PS.ShopMenu) then return end

		createShopWebView(resolvedUrl, PS.Config.WebUiVersion)
	end)
end

hook.Add("gmcore.Loadout.LocalUpdateReceived", "PS_Loadout_RefreshTab", function()
	if not PS or not PS.ShopMenu or not PS.ShopMenu.html then return end

	PS.ShopMenu.html:event("refreshLoadoutTab", {})
end)

hook.Add("gmcore.Loadout.ConfigUpdated", "PS_Loadout_ConfigRefreshTab", function()
	if not PS or not PS.ShopMenu or not PS.ShopMenu.html then return end

	PS.ShopMenu.html:event("refreshLoadoutTab", {})
end)

net.Receive("gmcore.Pointshop.BuyTickets", function()
	if !PS then return end
	if !PS.ShopMenu then return end

	PS.ShopMenu.html:event("refreshLotteryTab", {})
end)

---Sets currently hovered item for preview rendering.
---@param itemId string Unique identifier of item to preview
function PS:SetHoverItem(itemId)
	local ITEM = PS.Items[itemId]

	if ITEM.Model then
		self.HoverModel = itemId

		self.HoverModelClientsideModel = ClientsideModel(ITEM.Model, RENDERGROUP_OPAQUE)
		self.HoverModelClientsideModel:SetNoDraw(true)
	end
end

---Clears currently hovered item preview.
function PS:RemoveHoverItem()
	self.HoverModel = nil
	self.HoverModelClientsideModel = nil
end

-- modification stuff

---Sends item modification changes to server.
---@param itemId string Unique identifier of item being modified
---@param modifications table<string, any>
function PS:SendModifications(itemId, modifications)
	net.Start("PS_ModifyItem")
		net.WriteString(itemId)
		net.WriteTable(modifications)
	net.SendToServer()
end

-- net hooks

net.Receive("PS_ToggleMenu", function(length)
	PS:ToggleMenu()
end)

net.Receive("PS_Items", function(length)
	local ply = net.ReadEntity()
	local items = net.ReadTable()
	ply.PS_Items = items

	-- Send refresh event when items are updated
	if PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshItemData", {
			action = "items_updated"
		})
	end

	PS.ReceivedInitialSpawnData = true
end)

net.Receive("PS_Points", function(length)
	local ply = net.ReadEntity()
	local points = net.ReadInt(32)
	ply.PS_Points = PS:ValidatePoints(points)

	if ply == LocalPlayer() and PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshLocalPlyPoints", {
			points = ply.PS_Points
		})
	end

	PS.ReceivedInitialSpawnData = true
end)

net.Receive("PS_AddClientsideModel", function(length)
	local ply = net.ReadEntity()
	local itemId = net.ReadString()

	if !IsValid(ply) then
		if !invalidplayeritems[ply] then
			invalidplayeritems[ply] = {}
		end

		table.insert(invalidplayeritems[ply], itemId)

		return
	end

	ply:PS_AddClientsideModel(itemId)

	-- Send refresh event when clientside model is added (item equipped)
	if PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshItemData", {
			action = "model_added",
			itemId = itemId
		})
	end
end)

net.Receive("PS_RemoveClientsideModel", function(length)
	local ply = net.ReadEntity()
	local itemId = net.ReadString()

	if !ply or !IsValid(ply) or not ply:IsPlayer() then return end

	ply:PS_RemoveClientsideModel(itemId)

	-- Send refresh event when clientside model is removed (item unequipped)
	if PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshItemData", {
			action = "model_removed",
			itemId = itemId
		})
	end
end)

net.Receive("PS_SendClientsideModels", function(length)
	local itms = net.ReadTable()

	for ply, items in pairs(itms) do
		-- skip if the player isn"t valid yet and add them to the table to sort out later
		if !IsValid(ply) then
			invalidplayeritems[ply] = items
			continue
		end

		for _, itemId in pairs(items) do
			if PS.Items[itemId] then
				if not ply.PS_AddClientsideModel or ply.PS_AddClientsideModel == nil then return end

				ply:PS_AddClientsideModel(itemId)
			end
		end
	end

	-- Send refresh event when all clientside models are synced
	if PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshItemData", {
			action = "models_synced"
		})
	end
end)

net.Receive("PS_SendNotification", function(length)
	local str = net.ReadString()
	if gmcore and gmcore.Notify then
		gmcore.Notify(str, 5, "pointshop")
	else
		notification.AddLegacy(str, NOTIFY_GENERIC, 5)
	end
end)

net.Receive("PS_SendEventPlaytime", function(length)
	local eventId = net.ReadString()
	local mins = net.ReadUInt(32)

	if not eventId or eventId == "" then return end

	PS.EventPlaytimeMins[eventId] = mins
	PS.EventPlaytimePending[eventId] = nil

	if PS.ShopMenu and PS.ShopMenu.html then
		PS.ShopMenu.html:event("refreshItemData", {
			action = "items_updated",
			eventId = eventId
		})
	end
end)

net.Receive("PS_EventProgressDialog", function(length)
	local key = net.ReadString()
	local title = net.ReadString()
	local buttonText = net.ReadString()
	local text = net.ReadString()

	GMCore_EventProgressDialogs = GMCore_EventProgressDialogs or {}

	local dialog = GMCore_EventProgressDialogs[key]
	if IsValid(dialog) and dialog.SetDialogText then
		dialog:SetDialogText(text)
		return
	end

	dialog = GMCore_MessageDialog(text, title, buttonText)
	GMCore_EventProgressDialogs[key] = dialog

	if IsValid(dialog) then
		dialog.OnRemove = function()
			if GMCore_EventProgressDialogs then GMCore_EventProgressDialogs[key] = nil end
		end
	end
end)

-- hooks

--- Refresh item sections (requirements, pricing) update immediately without reopening the shop.
hook.Add("gmcore.StoreRank.Changed", "gmcore.Pointshop.StoreRankFireWebEvent", function(ply, new, old)
	if ply != LocalPlayer() then return end

	gmcore.WebView:broadcast(gmcore.WebView.Events.STORE_RANK_CHANGED, {rank = new, oldRank = old})
end)

hook.Add("Think", "PS_Think", function()
	for ply, items in pairs(invalidplayeritems) do
		if IsValid(ply) then
			for _, itemId in pairs(items) do
				if PS.Items[itemId] then
					ply:PS_AddClientsideModel(itemId)
				end
			end

			invalidplayeritems[ply] = nil
		end
	end
end)

hook.Add("PostPlayerDraw", "PS_PostPlayerDraw", function(ply)
	if !ply:Alive() then return end
	if ply == LocalPlayer() and GetViewEntity():GetClass() == "player" and (GetConVar("thirdperson") and GetConVar("thirdperson"):GetInt() == 0) then return end
	if !PS.ClientsideModels[ply] then return end

	for itemId, model in pairs(PS.ClientsideModels[ply]) do
		if !PS.Items[itemId] then PS.ClientsideModel[ply][itemId] = nil continue end

		local ITEM = PS.Items[itemId]

		if !ITEM.Attachment and !ITEM.Bone then PS.ClientsideModel[ply][itemId] = nil continue end

		local pos = Vector()
		local ang = Angle()

		if ITEM.Attachment then
			local attach_id = ply:LookupAttachment(ITEM.Attachment)
			if !attach_id then return end

			local attach = ply:GetAttachment(attach_id)

			if !attach then return end

			pos = attach.Pos
			ang = attach.Ang
		else
			local bone_id = ply:LookupBone(ITEM.Bone)
			if !bone_id then return end

			pos, ang = ply:GetBonePosition(bone_id)
		end

		model, pos, ang = ITEM:ModifyClientsideModel(ply, model, pos, ang)

		model:SetPos(pos)
		model:SetAngles(ang)

		model:SetRenderOrigin(pos)
		model:SetRenderAngles(ang)
		model:SetupBones()
		model:DrawModel()
		model:SetRenderOrigin()
		model:SetRenderAngles()
	end
end)
