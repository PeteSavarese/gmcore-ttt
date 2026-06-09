---@class Player
local Player = FindMetaTable("Player")

-- items

---Sets a loadout slot to a specific weapon class.
---@param kind string Weapon slot kind
---@param class string Weapon class name
function Player:PS_ChangeLoadout(kind, class)
	if self.PS_Loadout == nil then
		self.PS_Loadout = {}
	end

	self.PS_Loadout[kind] = class

	if gmcore.Loadout and gmcore.Loadout.SetLocalLoadout then
		gmcore.Loadout.SetLocalLoadout(kind, class)
	end
end

---Checks if a weapon class is set in the player's loadout for a given slot.
---@param wepclass string Weapon class name
---@param wepkind string Weapon slot kind
---@return boolean True if the weapon class is set in the specified loadout slot
function Player:PS_HasLoadWeapon(wepclass, wepkind)
	local loadout = self.PS_Loadout
	if gmcore.Loadout and gmcore.Loadout.localLoadout then
		loadout = gmcore.Loadout.localLoadout
	end

	if not loadout then return false end

	return loadout[wepkind] == wepclass
end

---Sends the player's loadout selections to the server.
function Player:PS_UpdateLoadout()
	if gmcore.Loadout and gmcore.Loadout.UpdateLoadoutToServer then
		return gmcore.Loadout.UpdateLoadoutToServer()
	end

	if not self.PS_Loadout then return false end

	net.Start("gmcore.Loadout.UpdateLoadout")
	net.WriteTable(self.PS_Loadout)
	net.SendToServer()

	return true
end

---Returns the player's owned items table.
---@return table<string, table>
function Player:PS_GetItems()
	return self.PS_Items or {}
end

---Checks whether the player owns the specified item (clientside).
---@param item_id string The unique identifier of the item to check
---@return boolean True if the player owns the item
function Player:PS_HasItem(item_id)
	if not self.PS_Items then return false end
	return self.PS_Items[item_id] and true or false
end

---Checks whether the player has the specified item equipped (clientside).
---@param item_id string The unique identifier of the item to check
---@return boolean True if the item is equipped
function Player:PS_HasItemEquipped(item_id)
	if not self:PS_HasItem(item_id) then return false end

	return self.PS_Items[item_id].Equipped or false
end

---Sends a buy item request to the server.
---@param item_id string The unique identifier of the item to buy
function Player:PS_BuyItem(item_id)
	if self:PS_HasItem(item_id) then print("he got it lol") return false end
	if not self:PS_HasPoints(PS.Config.CalculateBuyPrice(self, PS.Items[item_id])) then return false end

	net.Start("PS_BuyItem")
		net.WriteString(item_id)
	net.SendToServer()
end

---Requests the server to add a clientside model for this item.
---@param item_id string The unique identifier of the item model to add
function Player:PS_SendServerModel(item_id)
	net.Start("PS_ClientAddModel")
		net.WriteString(item_id)
	net.SendToServer()
end

---Requests the server to remove a clientside model for this item.
---@param item_id string The unique identifier of the item model to remove
function Player:PS_ServerRemoveModel(item_id)
	net.Start("PS_ClientRemoveModel")
		net.WriteString(item_id)
	net.SendToServer()
end

---Sends a buy weapon request to the server.
---@param item_id string The unique identifier of the weapon to buy
function Player:PS_BuyWeapon(item_id)
	if not self:PS_HasPoints(PS.Config.CalculateBuyPrice(self, PS.Items[item_id])) then
		return false
	end

	net.Start("PS_BuyItem")
		net.WriteString(item_id)
	net.SendToServer()
end


---Sends an upgrade item request to the server.
---@param item_id string The unique identifier of the item to upgrade
function Player:PS_UpgradeItem(item_id)
	--if not self:PS_HasItem(item_id) then return false end
	if self:PS_GetUpgradeLevel(item_id) >= #PS.Items[item_id].UpgradeList then return false end

	if not self:PS_HasPoints(PS.Config.CalculateUpgradePrice(self, PS.Items[item_id])) then return false end

	net.Start("PS_UpgradeItem")
		net.WriteString(item_id)
	net.SendToServer()
end

---Sends a sell item request to the server.
---@param item_id string The unique identifier of the item to sell
function Player:PS_SellItem(item_id)
	if not self:PS_HasItem(item_id) then return false end

	net.Start("PS_SellItem")
		net.WriteString(item_id)
	net.SendToServer()
end

---Equips a weapon.
---@param item_id string The unique identifier of the weapon to equip
function Player:PS_EquipItem(item_id)
	net.Start("PS_EquipItem")
		net.WriteString(item_id)
	net.SendToServer()
end

---Holsters a weapon.
---@param item_id string The unique identifier of the weapon to holster
function Player:PS_HolsterItem(item_id)
	net.Start("PS_HolsterItem")
		net.WriteString(item_id)
	net.SendToServer()
end

-- points

---Returns the player's current point balance (clientside).
---@return number The player's current points
function Player:PS_GetPoints()
	return self.PS_Points or 0
end

---Checks whether the player has at least the specified points (clientside).
---@param points number The minimum points required
---@return boolean True if the player has enough points
function Player:PS_HasPoints(points)
	return self:PS_GetPoints() >= points
end
