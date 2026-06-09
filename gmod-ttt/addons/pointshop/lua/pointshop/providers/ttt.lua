require("mysqloo")

---@alias PointshopItemData {Equipped: boolean, Modifiers: table}
---@alias PointshopItems table<string, PointshopItemData>

---Given a SteamID64, returns player's items and points. Used for init when a player spawns in.
---@param steamId string SteamID64 of player to fetch current inventory.
---@param fCallback fun(points: number, items: PointshopItems): nil Function to run after we get items.
function PROVIDER:GetData(steamId, fCallback)
	local provider = self
	local getDataQuery = gmcore.Database:prepare("SELECT points FROM player_data WHERE steamid64 = ?")

	function getDataQuery:onError(err)
		gmcore.print("[PS] Error attempt on GetData for (" .. steamId .. "): " .. err)
	end

	function getDataQuery:onSuccess(data)
		local points = 0

		if data and data[1] and data[1]["points"] then
			points = tonumber(data[1]["points"]) or 0
		end

		provider:GetItems(steamId, function(items)
			if !isfunction(fCallback) then return end

			fCallback(points, items)
		end)
	end

	getDataQuery:setString(1, steamId)
	getDataQuery:start()
end

---Given a SteamID64, returns player's inventory by getting the latest version from MySQL database.
---@param steamId string SteamID64 of player to fetch current inventory.
---@param fCallback fun(items: PointshopItems): nil Function to run after we get items.
function PROVIDER:GetItems(steamId, fCallback)
	local getItemsQuery = gmcore.Database:prepare("SELECT item_id, equipped, modifiers FROM pointshop_items WHERE steamid64 = ?")

	function getItemsQuery:onError(err)
		gmcore.print("[PS] Error attempt on GetItems for (" .. steamId .. "): " .. err)
	end

	function getItemsQuery:onSuccess(data)
		local items = {}

		if data and #data > 0 then
			for _, row in ipairs(data) do
				local modifiers = util.JSONToTable(row["modifiers"] or "{}") or {}
				items[row["item_id"]] = {
					Equipped = tonumber(row["equipped"]) == 1,
					Modifiers = modifiers
				}
			end
		end

		if !isfunction(fCallback) then return end

		fCallback(items)
	end

	getItemsQuery:setString(1, steamId)
	getItemsQuery:start()
end

---Given a SteamID64, fetches player's inventory and if item doesn't exist, gives item, updates inventory,
---and removes points from player.
---@param steamId string SteamID64 of player to fetch current inventory.
---@param itemName string Item's class name to give.
---@param itemCost number Amount of points to remove from player upon giving item.
---@param fCallback? fun(): nil Function to run after giving item.
---@param category? string Optional item category.
function PROVIDER:BuyItem(steamId, itemName, itemCost, fCallback, category)
	if !PS.Items[itemName] then
		gmcore.print("[PS] Error attempt on BuyItem for " .. steamId .. ") \"" .. itemName .. "\" is not a valid pointshop item!")

		return
	end

	local ply = player.GetBySteamID64(steamId)

	-- First get the most up-to-date version of our items
	self:GetItems(steamId, function(curItems)
		if category != nil and category != "Weapons" and curItems[itemName] then return end -- We already have item

		if PS.Items[itemName].SingleUse then
			-- Single use, only remove points don't store in inventory
			PS.DataProvider:UpdatePoints(steamId, itemCost)
			ply:PS_SendItems()

			if !isfunction(fCallback) then return end

			fCallback()
			return
		end

		-- Insert our new item into table
		curItems[itemName] = {Modifiers = {}, Equipped = false}

		-- Now write updates to db
		local buyItemQuery = gmcore.Database:prepare([[
			INSERT INTO pointshop_items (steamid64, item_id, item_uuid, equipped, modifiers)
			VALUES (?, ?, UUID(), 0, ?)
			ON DUPLICATE KEY UPDATE
				equipped = VALUES(equipped),
				modifiers = VALUES(modifiers)
		]])

		function buyItemQuery:onSuccess()
			-- Now remove points once confirmed they have been given the item. Converted to negatiev to REMOVE points
			PS.DataProvider:UpdatePoints(steamId, itemCost)

			ply.PS_Items = curItems
			ply:PS_SendItems()

			if !isfunction(fCallback) then return end

			fCallback()
		end

		function buyItemQuery:onError(err)
			gmcore.print("[PS] Error attempt on BuyItem for (" .. steamId .. "): " .. err)
		end

		buyItemQuery:setString(1, steamId)
		buyItemQuery:setString(2, itemName)
		buyItemQuery:setString(3, util.TableToJSON({}))
		buyItemQuery:start()
	end)
end

---Given a SteamID64, fetches player's inventory and if item exists, removes item, updates inventory,
---and reimburses player calculated sell price.
---@param steamId string SteamID64 of player.
---@param itemName string Item's class name to remove.
---@param itemCost number Amount of points to reimburse.
---@param fCallback? fun(): nil Function to run after selling item.
function PROVIDER:SellItem(steamId, itemName, itemCost, fCallback)
	if !PS.Items[itemName] then
		gmcore.print("[PS] Error attempt on SellItem for " .. steamId .. ") \"" .. itemName .. "\" is not a valid pointshop item!")

		return
	end

	local ply = player.GetBySteamID64(steamId)

	-- First get the most up-to-date version of our items
	self:GetItems(steamId, function(curItems)
		if !curItems[itemName] then return end -- We don't have the item to sell

		curItems[itemName] = nil

		-- Now write updates to db
		local sellItemQuery = gmcore.Database:prepare("DELETE FROM pointshop_items WHERE steamid64 = ? AND item_id = ?")

		function sellItemQuery:onSuccess()
			PS.DataProvider:UpdatePoints(steamId, itemCost)

			ply.PS_Items = curItems
			ply:PS_SendItems()

			if !isfunction(fCallback) then return end

			fCallback()
		end

		function sellItemQuery:onError(err)
			gmcore.print("[PS] Error attempt on SellItem for (" .. steamId .. "): " .. err)
		end

		sellItemQuery:setString(1, steamId)
		sellItemQuery:setString(2, itemName)
		sellItemQuery:start()
	end)
end

---Given a SteamID64, fetches player's inventory and if player has item, updates item's modifiers/properties.
---@param steamId string SteamID64 of player to update.
---@param itemName string Item's class update.
---@param itemProperties PointshopItemData The updated properties for this item.
---@param fCallback? fun(): nil Function to run after saving item.
function PROVIDER:SaveItem(steamId, itemName, itemProperties, fCallback)
	if !PS.Items[itemName] then
		gmcore.print("[PS] Error attempt on SaveItem for " .. steamId .. ") \"" .. itemName .. "\" is not a valid pointshop item!")

		return
	end

	local ply = player.GetBySteamID64(steamId)

	-- First get the most up-to-date version of our items
	self:GetItems(steamId, function(curItems)
		if !curItems[itemName] then return end -- We don't own the item to modify

		-- Update item's properties
		curItems[itemName] = itemProperties

		-- Now write updates to db
		local updateItemQuery = gmcore.Database:prepare([[
			INSERT INTO pointshop_items (steamid64, item_id, item_uuid, equipped, modifiers)
			VALUES (?, ?, UUID(), ?, ?)
			ON DUPLICATE KEY UPDATE
				equipped = VALUES(equipped),
				modifiers = VALUES(modifiers)
		]])

		function updateItemQuery:onSuccess()
			ply.PS_Items = curItems
			ply:PS_SendItems()

			if !isfunction(fCallback) then return end

			fCallback()
		end

		function updateItemQuery:onError(err)
			gmcore.print("[PS] Error attempt on SaveItem for (" .. steamId .. "): " .. err)
		end

		updateItemQuery:setString(1, steamId)
		updateItemQuery:setString(2, itemName)
		updateItemQuery:setNumber(3, itemProperties and itemProperties.Equipped and 1 or 0)
		updateItemQuery:setString(4, util.TableToJSON(itemProperties and itemProperties.Modifiers or {}))
		updateItemQuery:start()
	end)
end

---Gives points to everyone provided in plysToGivePoints param with corresponding points.
---@param plysToGivePoints table Table containing steamid64 and points to be given.
function PROVIDER:GivePointsOverTime(plysToGivePoints)
	local updateQueryString = "UPDATE player_data SET points = (CASE"

	for _, ply in ipairs(plysToGivePoints) do
		updateQueryString = updateQueryString .. " WHEN steamid64 = ? THEN points + ? "
	end

	-- Close case check and begin where statement
	updateQueryString = updateQueryString .. "END) WHERE steamid64 IN ("

	for k, ply in ipairs(plysToGivePoints) do
		updateQueryString = updateQueryString .. "?"

		-- If another player then add a comma delimiter
		if plysToGivePoints[k + 1] then
			updateQueryString = updateQueryString .. ","
		end
	end

	-- Close where check and finish query
	updateQueryString = updateQueryString .. ")"

	local updateQuery = gmcore.Database:prepare(updateQueryString)

	function updateQuery:onSuccess(data)
		for _, plyEntry in ipairs(plysToGivePoints) do
			local ply = player.GetBySteamID64(plyEntry[1])

			if !ply or ply.PS_Points == nil then continue end -- Player disconnected or not yet initialized?

			ply.PS_Points = ply.PS_Points + plyEntry[2]
			ply:PS_Notify("You've been given ", plyEntry[2], " ", PS.Config.PointsName, " for playing on the server!")

			ply:PS_SendPoints()
		end
	end

	function updateQuery:onError(err)
		gmcore.print("[PS] Error attempt on GivePointsOverTime: " .. err)
	end

	local preparedItemPos = 1 -- Used to track what our next pos is for setting a prepared value

	-- Handle CASE statement
	for k, ply in ipairs(plysToGivePoints) do
		updateQuery:setString(preparedItemPos, ply[1])
		preparedItemPos = preparedItemPos + 1
		updateQuery:setNumber(preparedItemPos, ply[2])
		preparedItemPos = preparedItemPos + 1
	end

	-- Handle WHERE statement
	for k, ply in ipairs(plysToGivePoints) do
		updateQuery:setString(preparedItemPos, ply[1])
		preparedItemPos = preparedItemPos + 1
	end

	updateQuery:start()
end

---Given a SteamID64, updates player's points.
---@param steamId string SteamID64 of player to modify.
---@param pointChange number Positive or negative number to add or remove points.
function PROVIDER:UpdatePoints(steamId, pointChange)
	local updatePointsQuery = gmcore.Database:prepare("UPDATE player_data SET points = points + ? WHERE steamid64 = ?")

	function updatePointsQuery:onSuccess()
		local ply = player.GetBySteamID64(steamId)

		if !IsValid(ply) then return end

		ply.PS_Points = player.GetBySteamID64(steamId).PS_Points + pointChange
		ply:PS_SendPoints()
	end

	function updatePointsQuery:onError(err)
		gmcore.print("[PS] Error attempt on UpdatePoints for (" .. steamId .. "): " .. err)
	end

	updatePointsQuery:setNumber(1, pointChange)
	updatePointsQuery:setString(2, steamId)
	updatePointsQuery:start()
end
