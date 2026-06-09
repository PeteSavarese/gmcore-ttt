---@alias GLEventId string
---@alias GLMinutes integer

---@class Player
---@field glEventPlaytimeMins table<GLEventId, integer>|nil @Minutes played per event. `-1` means "unknown/not loaded yet".
---@field glEventPlaytimeLoaded table<GLEventId, boolean>|nil @Whether playtime for the event has finished loading.
---@field glEventPlaytimeLastSave table<GLEventId, number>|nil @`CurTime()` of last DB flush per event.
---@field glEventPlaytimeDirty table<GLEventId, boolean>|nil @Whether playtime has changed since last flush per event.
local Player = FindMetaTable("Player")

---Initialize GL event playtime cache fields
---@return nil Initializes tables in-place
function Player:GL_InitEventPlaytimeState()
	self.glEventPlaytimeMins = self.glEventPlaytimeMins or {}
	self.glEventPlaytimeLoaded = self.glEventPlaytimeLoaded or {}
	self.glEventPlaytimeLastSave = self.glEventPlaytimeLastSave or {}
	self.glEventPlaytimeDirty = self.glEventPlaytimeDirty or {}
end

---Load event playtime minutes from db pdata into NW2Int
---If not loaded yet, `GL_GetEventPlaytimeMins()` will return `-1` until this completes.
---@param eventId GLEventId The event identifier to load playtime for
---@param callback? fun(mins: GLMinutes): nil
---@return nil Loads asynchronously via PData callback
function Player:GL_LoadEventPlaytime(eventId, callback)
	if not eventId or eventId == "" then
		if callback then callback(0) end

		return
	end

	self:GL_InitEventPlaytimeState()
	-- Mark as unknown until loaded
	if self.glEventPlaytimeMins[eventId] == nil then self.glEventPlaytimeMins[eventId] = -1 end

	---@param playtimeMins string|number|nil The raw playtime value from PData
	self:GMCoreGetPData("gmcore.EventPlayTime_" .. eventId, 0, function(playtimeMins)
		if not IsValid(self) then return end

		local mins = math.max(0, math.floor(tonumber(playtimeMins) or 0))
		self:GL_InitEventPlaytimeState()
		self.glEventPlaytimeMins[eventId] = mins
		self.glEventPlaytimeLoaded[eventId] = true
		self:SetNW2Int("gmcore.EventPlayTimeMins_" .. eventId, mins)

		if callback then callback(mins) end
	end)
end

---Get cached event playtime minutes.
---Returns `-1` when unknown/not loaded yet (call `GL_LoadEventPlaytime(eventId)` to populate).
---@param eventId GLEventId The event identifier to get playtime for
---@return integer mins
---@nodiscard
function Player:GL_GetEventPlaytimeMins(eventId)
	self:GL_InitEventPlaytimeState()

	local mins = self.glEventPlaytimeMins[eventId]
	if mins == nil then return -1 end

	return mins
end

---Increment cached event playtime minutes.
---If playtime is not loaded yet, this will fetch playtime from db and return early.
---@param eventId GLEventId The event identifier to increment playtime for
---@param deltaMins number The number of minutes to add
---@return nil Updates cached playtime and NW2Int in-place
function Player:GL_AddEventPlaytimeMins(eventId, deltaMins)
	if not eventId or eventId == "" then return end

	self:GL_InitEventPlaytimeState()

	local current = self:GL_GetEventPlaytimeMins(eventId)
	if current < 0 then
		-- Not loaded yet, load and bail. Next tick will increment.
		self:GL_LoadEventPlaytime(eventId)

		return
	end

	local newMins = math.max(0, current + (tonumber(deltaMins) or 0))
	self.glEventPlaytimeMins[eventId] = newMins
	self.glEventPlaytimeDirty[eventId] = true
	self:SetNW2Int("gmcore.EventPlayTimeMins_" .. eventId, newMins)
end

---Flush cached event playtime minutes to pdata if dirty.
---@param eventId GLEventId The event identifier to flush playtime for
---@return nil Writes to PData only if the cache is dirty
function Player:GL_FlushEventPlaytime(eventId)
	if not eventId or eventId == "" then return end

	self:GL_InitEventPlaytimeState()

	if not self.glEventPlaytimeDirty[eventId] then return end

	local mins = self:GL_GetEventPlaytimeMins(eventId)
	if mins < 0 then return end

	self.glEventPlaytimeDirty[eventId] = false
	self.glEventPlaytimeLastSave[eventId] = CurTime()
	self:GMCoreSetPData("gmcore.EventPlayTime_" .. eventId, mins)
end

---Called on player spawn. Re-equips all equipped items and applies permanent clientside models.
function Player:PS_PlayerSpawn()
	if not self:PS_CanPerformAction() then return end

	-- TTT ( and others ) Fix
	if TEAM_SPECTATOR != nil and self:Team() == TEAM_SPECTATOR then return end
	if TEAM_SPEC != nil and self:Team() == TEAM_SPEC then return end

	-- Murder Spectator Fix (they don't specify the above enums when making teams)
	-- https://github.com/mechanicalmind/murder/blob/master/gamemode/sv_spectate.lua#L15
	if self.Spectating then return end

	timer.Simple(1, function()
		if not IsValid(self) then return end
		if not self.PS_Items then return end

		for item_id, item in pairs(self.PS_Items) do
			local ITEM = PS.Items[item_id]

			if ITEM == nil then continue end
			if item.Equipped then
				ITEM:OnEquip(self, item.Modifiers)
			end

			if PS.Items[item_id].ModelPerk and self.PS_Items[item_id].Modifiers and self.PS_Items[item_id].Modifiers.permanentEquip then
				if not PS.ClientsideModels[self] then
					PS.ClientsideModels[self] = {}
				end

				if PS.ClientsideModels[self] and not PS.ClientsideModels[self][item_id] then
					self:PS_AddClientsideModel(item_id)
				end
			end
		end
	end)
end

---Called on player death. Holsters equipped items that don't have KeepOnDeath.
function Player:PS_PlayerDeath()
	if not self.PS_Items then return end

	for itemId, item in pairs(self.PS_Items) do
		if not item.Equipped then continue end

		local ITEM = PS.Items[itemId]
		if ITEM == nil then continue end
		if ITEM.KeepOnDeath then continue end

		ITEM:OnHolster(self, item.Modifiers)
	end
end

---Called on initial spawn. Initializes player state, loads data, and sends clientside models.
function Player:PS_PlayerInitialSpawn()
	self.PS_HasLoadedData = false -- Set to true when DB returns points and items. Prevents updating DB with PS_Items before all items are loaded
	self.PS_Points = 0
	self.PS_Items = {}

	self:GL_InitEventPlaytimeState()

	-- Send stuff
	timer.Simple(1, function()
		if not IsValid(self) then return end

		self:PS_LoadData()
		self:PS_SendClientsideModels()

		-- Prime event playtime cache so requirements are synchronous.
		if PS and PS.SkinEventInfo then
			for eventId, _ in pairs(PS.SkinEventInfo) do
				self:GL_LoadEventPlaytime(eventId)
			end
		end
	end)

	-- Send player's clientside models so they can see in their pointshop preview
	timer.Simple(3, function()
		if not IsValid(self) then return end

		for itemId, item in pairs(self.PS_Items) do
			local ITEM = PS.Items[itemId]

			if ITEM == nil then continue end

			if (ITEM.Bone or ITEM.Attachment) and not ITEM.CosmeticPerk then
				self:PS_AddClientsideModel(itemId)
			end

			if ITEM.ComseticPerk and self.PS_Items[item_id].Modifiers.permanentEquip then
				self:PS_AddClientsideModel(itemId)
			end
		end
	end)
end

---Called on disconnect. Cleans up clientside models, flushes event playtime, and removes timers.
function Player:PS_PlayerDisconnected()
	PS.ClientsideModels[self] = nil

	-- Flush any pending event playtime to DB
	if self.glEventPlaytimeDirty then
		for eventId, dirty in pairs(self.glEventPlaytimeDirty) do
			if dirty then
				self:GL_FlushEventPlaytime(eventId)
			end
		end
	end

	if timer.Exists("PS_PointsOverTime_" .. self:UniqueID()) then
		timer.Remove("PS_PointsOverTime_" .. self:UniqueID())
	end
end

---Loads the player's points and items from the data provider.
function Player:PS_LoadData()
	self.PS_Points = 0
	self.PS_Items = {}

	PS:GetPlayerData(self, function(points, items)
		self.PS_Points = points or 0
		self.PS_Items = items or {}

		self:PS_SendPoints()
		self:PS_SendItems()

		self.PS_HasLoadedData = true -- Now we can make changes to player's points and items
	end)
end

---Checks whether the player is currently allowed to perform a pointshop action.
---@param itemname? string Item ID to check exceptions for
---@return boolean True if the player is allowed to perform the action
function Player:PS_CanPerformAction(itemname)
	local allowed = true
	if itemname then itemexcept = PS.Items[itemname].Except end

	--if (self.IsSpec and self:IsSpec()) and !itemexcept then allowed = false end
	--if !self:Alive() and !itemexcept then allowed = false end


	--if !allowed then
	--	self:PS_Notify("You're not allowed to do that at the moment!")
	--end

	return allowed
end

-- points

---Gives points to the player via the data provider.
---@param points number The number of points to give
function Player:PS_GivePoints(points)
	if not self.PS_Points then return end

	PS:GivePlayerPoints(self, points)
end

---Gives points to the player with point boost hooks applied.
---@param points number Base points before boost Base points before boost
function Player:PS_GivePointsBoostable(points)
	if not self.PS_Points then return end

	-- table reference so multiple hooks could modify the value if necessary.
	local points_ref = { points = points }
	hook.Run("gmcore.Pointshop.GetPointBoost", self, points_ref)
	local newPoints = points_ref.points or points
	newPoints = math.floor(newPoints + 0.5) -- round to nearest whole number

	PS:GivePlayerPoints(self, newPoints)
end

---Takes points from the player via the data provider.
---@param points number The number of points to remove
function Player:PS_TakePoints(points)
	PS:TakePlayerPoints(self, points)
end

---Sets the player's points to an exact value.
---@param points number The exact point balance to set
function Player:PS_SetPoints(points)
	self.PS_Points = points
	PS:SetPlayerPoints(self, points)
end

---Returns the player's current point balance.
---@return number The player's current points
function Player:PS_GetPoints()
	return self.PS_Points and self.PS_Points or 0
end

---Checks whether the player has at least the specified number of points.
---@param points number The minimum points required
---@return boolean True if the player has enough points
function Player:PS_HasPoints(points)
	return self.PS_Points >= points
end

-- give/take items

---Gives the player an item without charging points.
---@param item_id string The unique identifier of the item to give
---@return boolean True if the item was successfully given
function Player:PS_GiveItem(item_id)
	if not PS.Items[item_id] then return false end

	self.PS_Items[item_id] = { Modifiers = {}, Equipped = false }

	PS:GivePlayerItem(self, item_id, self.PS_Items[item_id])
	self:PS_SendItems()

	return true
end

---Removes an item from the player's inventory.
---@param item_id string The unique identifier of the item to remove
---@return boolean True if the item was successfully removed
function Player:PS_TakeItem(item_id)
	if not PS.Items[item_id] then return false end
	if not self:PS_HasItem(item_id) then return false end

	self.PS_Items[item_id] = nil

	PS:TakePlayerItem(self, item_id)

	self:PS_SendItems()

	return true
end

-- buy/sell items

-- Requirement type handlers
---@type table<string, fun(ply: Player, requirement: table): boolean, string?>
local RequirementHandlers = {}

-- Check if player meets rank requirement
RequirementHandlers["ulx_rank"] = function(ply, requirement)
	if requirement.value == "member" then
		if ply:GetNWInt("forumId", 0) != 0 then
			return true
		end

		return false, "You must be a registered forum member to purchase this skin"
	end

	return false, "You need " .. requirement.value .. " rank or higher to purchase this item"
end

RequirementHandlers["store_rank"] = function(ply, requirement)
	if ply:GetStoreRank() >= tonumber(requirement.value) then
		return true
	end

	return false, "You need " .. requirement.value .. " rank or higher to purchase this item"
end

RequirementHandlers["playtime"] = function(player, requirement)
	local requiredHours = tonumber(requirement.value) or 0
	local plyPlayTimeHrs = player:GetNW2Int("gmcore.PlayTimeMins", 0) / 60

	if plyPlayTimeHrs >= requiredHours then
		return true
	else
		return false, "You need " .. requiredHours .. " hours of playtime to purchase this item"
	end
end

RequirementHandlers["event_playtime"] = function(ply, requirement)
	local eventId = requirement.event
	local requiredHours = tonumber(requirement.value) or 0

	if not eventId then return false, "Invalid event playtime requirement" end

	-- Use cached playtime. No async GMCoreGetPData here.
	local mins = ply:GL_GetEventPlaytimeMins(eventId)
	if mins < 0 then
		ply:GL_LoadEventPlaytime(eventId)

		return false, "Syncing event playtime. Try again in a moment."
	end

	local eventPlaytimeHrs = mins / 60
	if eventPlaytimeHrs >= requiredHours then return true end

	return false, "You need " .. requiredHours .. " hours of playtime during this event to purchase this item"
end

RequirementHandlers["weapon_kills"] = function(ply, requirement)
	local key = requirement.key
	local required = tonumber(requirement.value) or 0
	if not key or key == "" then return false, "Invalid weapon kill requirement" end

	local cur = ply:GetNWInt(key, 0)
	if cur >= required then return true end

	return false, "You need " .. required .. " kills to purchase this item"
end

RequirementHandlers["weapon_headshots"] = function(ply, requirement)
	local key = requirement.key
	local required = tonumber(requirement.value) or 0
	if not key or key == "" then return false, "Invalid weapon headshot requirement" end

	local cur = ply:GetNWInt(key, 0)
	if cur >= required then return true end

	return false, "You need " .. required .. " headshots to purchase this item"
end

RequirementHandlers["custom"] = function(player, requirement)
	if requirement.check and type(requirement.check) == "function" then
		return requirement.check(player, requirement)
	else
		return false, "Invalid custom requirement"
	end
end

---Checks whether a player meets all requirements to buy an item.
---@param ply Player The player attempting to buy the item
---@param itemId string The unique identifier of the item
---@return boolean True if all requirements are met
local function checkRequirements(ply, itemId)
	local skinData = PS.Items[itemId]
	if not skinData then return false end

	if not skinData.Requirements or #skinData.Requirements == 0 then
		return true
	end

	-- Check each requirement
	for _, requirement in ipairs(skinData.Requirements) do
		local handler = RequirementHandlers[requirement.type]

		if handler then
			local canPurchase, errorMessage = handler(ply, requirement)

			if not canPurchase then
				ply:PS_Notify(errorMessage or "Requirement not met")
				return false
			end
		else
			print("[WeaponSkinRequirements] Unknown requirement type: " .. (requirement.type or "nil"))
			ply:PS_Notify("Invalid requirement type: " .. (requirement.type or "unknown"))

			return false
		end
	end

	return true
end

-- TODO: Possibly move to timetracker in GL core instead??
timer.Create("gmcore.EventPlaytime.Tick", 60, 0, function()
	if not PS or not PS.SkinEventInfo then return end

	local now = os.time()
	---@type GLEventId[]
	local activeEvents = {}

	for eventId, info in pairs(PS.SkinEventInfo) do
		---@cast eventId GLEventId
		---@cast info table
		local beginTime = tonumber(info.begin) or 0
		local endTime = tonumber(info["end"]) or 0

		if beginTime > 0 and now < beginTime then continue end
		if endTime > 0 and now > endTime then continue end

		table.insert(activeEvents, eventId)
	end

	if #activeEvents == 0 then return end

	for _, ply in ipairs(player.GetHumans()) do
		if not IsValid(ply) then continue end

		-- -- Skip spectators (TTT / similar) when teams are present
		-- if not ply:IsSpec() then print("Skipping spectator: " .. ply:Nick()) continue end

		ply:GL_InitEventPlaytimeState()
		for _, eventId in ipairs(activeEvents) do
			ply:GL_AddEventPlaytimeMins(eventId, 1)
			ply:GL_FlushEventPlaytime(eventId)
		end
	end
end)

--[[
	Check if a player can buy an item. Used for BuyItem and BuyUpgrade

	@ply - Player that is attempting to buy an item
	@itemId - Item ID that is attempted to be purchased
	@isUpgrade - Is the item we are checking an upgrade
]]
---Checks whether a player can buy or upgrade an item (points, permissions, restrictions).
---@param ply Player The player attempting the purchase
---@param itemId string The unique identifier of the item
---@param isUpgrade boolean Whether this is an upgrade rather than a new purchase
---@return boolean True if the player can buy or upgrade the item
local function checkCanBuy(ply, itemId, isUpgrade)
	local ITEM = PS.Items[itemId]
	if not ITEM then return false end

	local points = isUpgrade and PS.Config.CalculateUpgradePrice(ply, ITEM) or PS.Config.CalculateBuyPrice(ply, ITEM)

	if not ply:PS_HasPoints(points) then return false end
	if not ply:PS_CanPerformAction(itemId) then return end

	if ITEM.Requirements and #ITEM.Requirements > 0 then
		if not checkRequirements(ply, itemId) then return false end
	end

	if ITEM.Category == "Skins" then
		return true
	end

	if ITEM.AdminOnly and not ply:IsAdmin() then
		ply:PS_Notify("This item is Admin only!")
		return false
	end

	if (ITEM.AllowedUserGroups and #ITEM.AllowedUserGroups > 0) and not table.HasValue(ITEM.AllowedUserGroups, ply:PS_GetUsergroup()) then
		ply:PS_Notify("You're not in the right group to buy this item!")
		return false
	end

	if (ITEM.Section and isnumber(ITEM.Section) and ITEM.Section > 0) and ply:GetStoreRank() < tonumber(ITEM.Section) then
		ply:PS_Notify("This item is only for " .. gmcore.StoreRank.Ranks[tonumber(ITEM.Section)].name .. " and up!")
		return false
	end

	if (ITEM.Section and type(ITEM.Section) == "string" and string.lower(ITEM.Section) == "member" and ply:GetNWInt("forumId", 0) == 0) then
		ply:PS_Notify("This item is only for registered forum users!")
		return false
	end

	local cat_name = ITEM.Category
	local CATEGORY = PS:FindCategoryByName(cat_name)

	if (CATEGORY.AllowedUserGroups and #CATEGORY.AllowedUserGroups > 0) and table.HasValue(CATEGORY.AllowedUserGroups, ply:PS_GetUsergroup()) then
		ply:PS_Notify("You're not in the right group to buy this item!")
		return false
	end

	if CATEGORY.CanPlayerSee and not CATEGORY:CanPlayerSee(ply) then
		ply:PS_Notify("You're not allowed to buy this item!")
		return false
	end

	if ITEM.CanPlayerBuy then -- should exist but we'll check anyway
		local allowed, message

		if type(ITEM.CanPlayerBuy) == "function" then
			allowed, message = ITEM:CanPlayerBuy(ply)
		elseif type(ITEM.CanPlayerBuy) == "boolean" then
			allowed = ITEM.CanPlayerBuy
		end

		if not allowed then
			ply:PS_Notify(message or "You're not allowed to buy this item!")

			return false
		end
	end


	if cat_name == "Weapons" then
		if not ply:IsTerror() then
			ply:PS_Notify("You can only buy weapons while alive!")

			return false
		elseif ply.PS_WeaponBuyDelay and ply.PS_WeaponBuyDelay > CurTime() then -- Exponential delay to prevent buying tons of weapons
			local iDelaySeconds = math.Round(ply.PS_WeaponBuyDelay - CurTime())

			ply:PS_Notify(string.format("You must wait %d second%sbefore buying another weapon!", iDelaySeconds, iDelaySeconds > 1 and "s " or " "))
			return false
		end
	end

	if cat_name == "Weapons" then
		local sFrActive = gmcore.FunRounds and gmcore.FunRounds.CurrentlyActiveRound
		local tFunRound = sFrActive and gmcore.FunRounds.RegisteredFunRounds[sFrActive]
		local bIsActiveFunRound = gmcore.FunRounds.IsRoundFun

		if bIsActiveFunRound and tFunRound and tFunRound.PointshopDisabled then
			ply:PS_Notify("You cannot buy weapons during this fun round!")

			return false
		end
	end

	return true
end

---Purchases an item for the player, deducting points and equipping it.
---@param itemId string The unique identifier of the item to buy
---@return boolean|nil False if the purchase fails, nil on success
function Player:PS_BuyItem(itemId)
	if not PS.Items[itemId] then return false end
	if not checkCanBuy(self, itemId, false) then return false end

	local ITEM = PS.Items[itemId]
	local points = PS.Config.CalculateBuyPrice(self, ITEM)

	-- Buy item and after send msgs
	PS.DataProvider:BuyItem(self:SteamID64(), itemId, -points, function()
		self:PS_EquipItem(itemId)
		ITEM:OnBuy(self)

		if ITEM.Category == "Weapons" then -- Set delay for single use weapons
			if not self.PS_WeaponBuyDelayCount then
				self.PS_WeaponBuyDelayCount = 1 -- Used to track for expnential delay
			else
				self.PS_WeaponBuyDelayCount = self.PS_WeaponBuyDelayCount + 1
			end

			self.PS_WeaponBuyDelay = CurTime() +
			math.pow(2, self.PS_WeaponBuyDelayCount)                                   -- Exponentially increase delay seconds (2, 4, 8, 16)
		end

		if ITEM.SingleUse then
			self:PS_Notify("Single use item. You'll have to buy this item again next time!")
			return
		end

		self:PS_Notify("Bought ", ITEM.Name, " for ", points, " ", PS.Config.PointsName)
	end, ITEM.Category)
end

---Upgrades an owned item (or buys and upgrades if not owned).
---@param upgradeId string The unique identifier of the item to upgrade
---@return boolean|nil False if the upgrade fails, nil on success
function Player:PS_UpgradeItem(upgradeId)
	if not PS.Items[upgradeId] then return false end
	if not checkCanBuy(self, upgradeId, true) then return false end

	local ITEM = PS.Items[upgradeId]
	local points = PS.Config.CalculateUpgradePrice(self, ITEM)

	-- We we already have item, just update level and stop there
	if self:PS_HasItem(upgradeId) then
		local level = self:PS_GetUpgradeLevel(upgradeId)

		self:PS_ModifyItem(upgradeId, { level = level + 1 })
		ITEM:OnUpgrade(self)
		self:PS_EquipItem(upgradeId)
		self:PS_TakePoints(points)

		self:PS_Notify("Upgraded ", ITEM.Name, " for ", points, " ", PS.Config.PointsName)

		return
	end

	-- Since we don't own upgrde, buy, apply level 1, and send msgs
	PS.DataProvider:BuyItem(self:SteamID64(), upgradeId, -points, function()
		self:PS_ModifyItem(upgradeId, { level = 1 })
		ITEM:OnUpgrade(self)
		self:PS_EquipItem(upgradeId)

		self:PS_Notify("Upgraded ", ITEM.Name, " for ", points, " ", PS.Config.PointsName)
	end)
end

---Sells an item from the player's inventory, refunding points.
---@param item_id string The unique identifier of the item to sell
---@return boolean|nil False if the sale fails, nil on success
function Player:PS_SellItem(item_id)
	if not PS.Items[item_id] then return false end
	if not self:PS_HasItem(item_id) then return false end

	local ITEM = PS.Items[item_id]

	if ITEM.CanPlayerSell then -- should exist but we'll check anyway
		local allowed, message

		if type(ITEM.CanPlayerSell) == "function" then
			allowed, message = ITEM:CanPlayerSell(self)
		elseif type(ITEM.CanPlayerSell) == "boolean" then
			allowed = ITEM.CanPlayerSell
		end

		if not allowed then
			self:PS_Notify(message or "You're not allowed to sell this item!")

			return false
		end
	end

	local points = PS.Config.CalculateSellPrice(self, ITEM)

	PS.DataProvider:SellItem(self:SteamID64(), item_id, points, function()
		ITEM:OnHolster(self)
		ITEM:OnSell(self)
		self:PS_Notify("Sold ", ITEM.Name, " for ", points, " ", PS.Config.PointsName)
	end)
end

---Checks whether the player owns the specified item.
---@param item_id string The unique identifier of the item to check
---@return table|false Item data or false
function Player:PS_HasItem(item_id)
	if not self.PS_Items then return false end

	return self.PS_Items[item_id] or false
end

---Checks whether the player has the specified item equipped.
---@param item_id string The unique identifier of the item to check
---@return boolean True if the item is equipped
function Player:PS_HasItemEquipped(item_id)
	if not self:PS_HasItem(item_id) then return false end

	return self.PS_Items[item_id].Equipped or false
end

---Returns the number of items the player has equipped from a given category.
---@param cat_name string The category name to count equipped items in
---@return number The count of equipped items in the category
function Player:PS_NumItemsEquippedFromCategory(cat_name)
	local count = 0

	for item_id, item in pairs(self.PS_Items) do
		local ITEM = PS.Items[item_id]
		if not ITEM then continue end

		if ITEM.Category == cat_name and item.Equipped then
			count = count + 1
		end
	end

	return count
end

-- equip/hoster items

---Equips a pointshop item on the player, handling category limits and auto-holstering.
---@param item_id string The unique identifier of the item to equip
---@return boolean|nil False if equipping fails, nil on success
function Player:PS_EquipItem(item_id)
	if not PS.Items[item_id] then return false end
	if not self:PS_HasItem(item_id) then return false end
	if not self:PS_CanPerformAction(item_id) then return false end

	local ITEM = PS.Items[item_id]

	if type(ITEM.CanPlayerEquip) == "function" then
		allowed, message = ITEM:CanPlayerEquip(self)
	elseif type(ITEM.CanPlayerEquip) == "boolean" then
		allowed = ITEM.CanPlayerEquip
	end

	if not allowed then
		self:PS_Notify(message or "You're not allowed to equip this item!")
		return false
	end

	if (ITEM.Section and isnumber(ITEM.Section) and ITEM.Section > 0) and self:GetStoreRank() < tonumber(ITEM.Section) then
		self:PS_Notify("This item is only for " .. gmcore.StoreRank.Ranks[tonumber(ITEM.Section)].name .. " and up!")
		return false
	end

	local cat_name = ITEM.Category
	local CATEGORY = PS:FindCategoryByName(cat_name)

	if CATEGORY.Name == "Skins" then
		-- Unequip previously equiped weapon skins for same item class
		if not ITEM.Class then return end

		for k, v in pairs(PS.Items) do
			if v.Category == "Skins" and v.Class == ITEM.Class and self:PS_HasItemEquipped(k) and k != item_id then
				self:PS_HolsterItem(k, true, function()
					self:PS_Notify("Holstered previously equipped skin: ", v["Name"], ".")

					self.PS_Items[item_id].Equipped = true
					PS:SavePlayerItem(self, item_id, self.PS_Items[item_id], fCallback)
					ITEM:OnEquip(self, self.PS_Items[item_id].Modifiers)
					self:PS_SendItems()
					self:PS_Notify("Equipped ", ITEM.Name, ".")
				end)

				return
			end
		end
	end

	if CATEGORY and CATEGORY.AllowedEquipped > -1 then
		if CATEGORY.Name == "Playermodels" or CATEGORY.Name == "Jihad Sounds" then
			for k, v in pairs(PS.Items) do
				if CATEGORY.Name == "Playermodels" and v["Category"] == "Playermodels" and self:PS_HasItemEquipped(k) then
					self:PS_HolsterItem(k, true, function()
						self:PS_Notify("Holstered previously equipped playermodel: ", v["Name"], ".")

						-- Now that old playermodel is unequipped, equip new playermodel
						self.PS_Items[item_id].Equipped = true
						PS:SavePlayerItem(self, item_id, self.PS_Items[item_id], fCallback)
						ITEM:OnEquip(self, self.PS_Items[item_id].Modifiers)
						self:PS_SendItems()
						self:PS_Notify("Equipped ", ITEM.Name, ".")
					end)

					return
				elseif CATEGORY.Name == "Jihad Sounds" and v["Category"] == "Jihad Sounds" and self:PS_HasItemEquipped(k) then
					self:PS_HolsterItem(k, true, function()
						self:PS_Notify("Holstered previously equipped jihad sound: ", v["Name"], ".")

						-- Now that old jihad sound is unequipped, equip new sound
						self.PS_Items[item_id].Equipped = true
						PS:SavePlayerItem(self, item_id, self.PS_Items[item_id], fCallback)
						ITEM:OnEquip(self, self.PS_Items[item_id].Modifiers)
						self:PS_SendItems()
						self:PS_Notify("Equipped ", ITEM.Name, ".")
					end)

					return
				end
			end
		else
			if self:PS_NumItemsEquippedFromCategory(cat_name) + 1 > CATEGORY.AllowedEquipped then
				self:PS_Notify("Only " ..
				CATEGORY.AllowedEquipped ..
				" item" .. (CATEGORY.AllowedEquipped == 1 and "" or "s") .. " can be equipped from this category!")

				return false
			end
		end
	end

	if CATEGORY.SharedCategories then
		local ConCatCats = CATEGORY.Name
		for p, c in pairs(CATEGORY.SharedCategories) do
			if p != #CATEGORY.SharedCategories then
				ConCatCats = ConCatCats .. ", " .. c
			else
				if #CATEGORY.SharedCategories != 1 then
					ConCatCats = ConCatCats .. ", and " .. c
				else
					ConCatCats = ConCatCats .. " and " .. c
				end
			end
		end

		for id, item in pairs(self.PS_Items) do
			if not self:PS_HasItemEquipped(id) then continue end

			local CatName = PS.Items[id].Category
			local Cat = PS:FindCategoryByName(CatName)

			if not Cat.SharedCategories then continue end

			for _, SharedCategory in pairs(Cat.SharedCategories) do
				if SharedCategory == CATEGORY.Name and Cat.AllowedEquipped > -1 and CATEGORY.AllowedEquipped > -1 and Cat.AllowedEquipped > -1 and CATEGORY.AllowedEquipped > -1 then
					return false
				end
			end
		end
	end

	self.PS_Items[item_id].Equipped = true
	PS:SavePlayerItem(self, item_id, self.PS_Items[item_id], fCallback)
	ITEM:OnEquip(self, self.PS_Items[item_id].Modifiers)
	self:PS_SendItems()
	self:PS_Notify("Equipped ", ITEM.Name, ".")
end

---Holsters (unequips) a pointshop item on the player.
---@param item_id string The unique identifier of the item to holster
---@param is_model? boolean Whether the item is a model (suppresses notification)
---@param fCallback? function Callback after save completes
function Player:PS_HolsterItem(item_id, is_model, fCallback)
	if is_model == nil then is_model = false end
	if not PS.Items[item_id] then return false end
	if not self:PS_HasItem(item_id) then return false end
	if not self:PS_CanPerformAction(item_id) then return false end

	self.PS_Items[item_id].Equipped = false

	local ITEM = PS.Items[item_id]

	if type(ITEM.CanPlayerHolster) == "function" then
		allowed, message = ITEM:CanPlayerHolster(self)
	elseif type(ITEM.CanPlayerHolster) == "boolean" then
		allowed = ITEM.CanPlayerHolster
	end

	if not allowed then
		self:PS_Notify(message or "You're not allowed to holster this item!")

		return false
	end

	ITEM:OnHolster(self)

	if is_model == false then
		self:PS_Notify("Holstered ", ITEM.Name, ".")
	end

	PS:SavePlayerItem(self, item_id, self.PS_Items[item_id], fCallback)

	self:PS_SendItems()
end

-- modify items

---Applies modifier changes to an owned item and saves.
---@param item_id string The unique identifier of the item to modify
---@param modifications table<string, any>
function Player:PS_ModifyItem(item_id, modifications)
	if not PS.Items[item_id] then return false end
	if not self:PS_HasItem(item_id) then return false end
	if type(modifications) != "table" then return false end
	if not self:PS_CanPerformAction(item_id) then return false end

	local ITEM = PS.Items[item_id]

	for key, value in pairs(modifications) do
		self.PS_Items[item_id].Modifiers[key] = value
	end

	ITEM:OnModify(self, self.PS_Items[item_id].Modifiers)

	PS:SavePlayerItem(self, item_id, self.PS_Items[item_id])

	self:PS_SendItems()
end

-- clientside Models

---Adds a clientside model for this player and broadcasts to all clients.
---@param item_id string The unique identifier of the item model to add
function Player:PS_AddClientsideModel(item_id)
	net.WriteEntity(self)
	net.WriteString(item_id)
	net.Broadcast()

	if not PS.ClientsideModels[self] then PS.ClientsideModels[self] = {} end

	PS.ClientsideModels[self][item_id] = item_id
end

---Removes a clientside model for this player and broadcasts to all clients.
---@param item_id string The unique identifier of the item model to remove
function Player:PS_RemoveClientsideModel(item_id)
	net.WriteEntity(self)
	net.WriteString(item_id)
	net.Broadcast()

	if not PS.ClientsideModels[self] then return end

	PS.ClientsideModels[self][item_id] = nil
end

-- menu stuff

---Sends a net message to toggle the pointshop menu for this player.
---@param show? any Unused parameter
function Player:PS_ToggleMenu(show)
	net.Start("PS_ToggleMenu")
	net.Send(self)
end

-- send stuff

---Broadcasts this player's current points to all clients.
function Player:PS_SendPoints()
	net.Start("PS_Points")
	net.WriteEntity(self)
	net.WriteInt(self.PS_Points, 32)
	net.Broadcast()
end

---Broadcasts this player's items table to all clients.
function Player:PS_SendItems()
	net.Start("PS_Items")
	net.WriteEntity(self)
	net.WriteTable(self.PS_Items)
	net.Broadcast()
end

---Sends the full clientside models table to this player.
function Player:PS_SendClientsideModels()
	net.Start("PS_SendClientsideModels")
	net.WriteTable(PS.ClientsideModels)
	net.Send(self)
end

-- notifications

---Sends a notification string to this player.
---@param ... string|number Concatenated into the notification message
function Player:PS_Notify(...)
	local str = table.concat({ ... }, "")

	net.Start("PS_SendNotification")
	net.WriteString(str)
	net.Send(self)
end

--[[
	Loops through all players on servers, gets points they should earn, stores in table, and sends it off to DB handler for one single query instead of 1 query per person
]]
---Awards points to all online players with boost hooks applied, in a single batch query.
function PS:AwardPointsOverTime()
	if #player.GetAll() <= 0 then return end

	local plyToPoints = {} -- Key is steamid, value is how many points they should get

	for _, ply in ipairs(player.GetAll()) do
		local iPointsOverTime = PS.Config.PointsOverTimeAmount

		-- This is manually done again outside of the `Player:GivePointsBoosted` function
		-- because this is an optimized routine that doesn't call it for each player
		local points_ref = { points = iPointsOverTime }
		hook.Run("gmcore.Pointshop.GetPointBoost", ply, points_ref)
		local iPointsOverTimeBoosted = points_ref.points or iPointsOverTime
		iPointsOverTimeBoosted = math.floor(iPointsOverTimeBoosted + 0.5) -- round to nearest whole number

		-- gmcore Custom Point Code
		-- if ply:IsStoreRank() then
		-- 	table.insert(plyToPoints, {ply:SteamID64(), gmcore.StoreRank.Ranks[ply:GetStoreRank()].ps_pointsovertime})
		-- else
		table.insert(plyToPoints, { ply:SteamID64(), iPointsOverTimeBoosted })
		-- end
	end

	PS.DataProvider:GivePointsOverTime(plyToPoints)
end

timer.Create("gmcore.Pointshop.PointsOverTime", PS.Config.PointsOverTimeDelay * 60, 0, PS.AwardPointsOverTime)
