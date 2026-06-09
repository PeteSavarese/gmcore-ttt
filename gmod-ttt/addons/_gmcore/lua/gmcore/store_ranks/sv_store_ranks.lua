---@class Player
local pMeta = FindMetaTable("Player")

---Recursive method that unequips each item in callback for PS_HolsterItem
---and removes them from table
---@param ply Player Player to unequip items from
---@param items table Table of item IDs to unequip
local function unequipPointshopItems(ply, items)
	if #items == 0 then return end -- We've finished

	local itemId = items[1]
	local itemTable = PS.Items[itemId]

	ply:PS_HolsterItem(itemId, itemTable.Category == "Playermodels", function()
		if itemTable.Category == "Playermodels" then
			ply:PS_Notify("Holstered " .. itemTable.Name .. ".")
		end

		table.remove(items, 1)

		-- If still items to remove, call ourselves again
		if #items != 0 then
			unequipPointshopItems(ply, items)
		end
	end)
end

---Set NWInt "gmcore.StoreRank"
---@param int integer Store rank index to assign to the player
function pMeta:SetStoreRank(int)
	self:SetNWInt("gmcore.StoreRank", tonumber(int) or 0) -- Store their rank as NWInt for easier access during session instead of querying the sv.db so much
	gmcore.StoreRank:SetStoreRankStatus(self, int)
end

---Returns NWInt "gmcore.StoreRank"
---@return (number|nil)? rankIndex The player's stored store rank index from PData
function pMeta:GetStoreRankPData()
	return tonumber(self:GetPData("gmcore.StoreRank", 0))
end


---Sets store rank status for a player and unequips rank-specific items if downgrading
---If new rank is lower than current, all PS items requiring a higher rank will be unequipped
---@param ply Player Player whose rank is being set
---@param newRankIndex number New rank index to assigned
function gmcore.StoreRank:SetStoreRankStatus(ply, newRankIndex)
	if !IsValid(ply) then return end
	if type(newRankIndex) != "number" then return end

	local oldRankIndex = ply:GetStoreRankPData() or 0

	-- If we are downgrading unequip all their rank-specific items
	local itemsToRemove = {} -- Stores all items that need to be unequipped. Supplied to unequipPointshopItems

	if newRankIndex < oldRankIndex then
		for itemId, item in pairs(ply.PS_Items) do
			local itemTable = PS.Items[itemId]

			if !itemTable then continue end
			if !itemTable.Section then continue end
			if !isnumber(itemTable.Section) then continue end
			if !item.Equipped then continue end

			if newRankIndex < tonumber(itemTable.Section) then
				table.insert(itemsToRemove, itemId)
			end
		end
	end

	unequipPointshopItems(ply, itemsToRemove)

	ply:SetPData("gmcore.StoreRank", newRankIndex)
	ply:SetNWInt("gmcore.StoreRank", tonumber(newRankIndex))

	if oldRankIndex != newRankIndex then
		--- Fired on the server when a player's store rank changes.
		---@param ply Player The player whose rank changed.
		---@param newRank number The new store rank index.
		---@param oldRank number The previous store rank index.
		hook.Call("gmcore.StoreRank.Changed", nil, ply, newRankIndex, oldRankIndex)

		net.Start("gmcore.StoreRank.Changed")
			net.WriteEntity(ply)
			net.WriteUInt(newRankIndex, 8)
			net.WriteUInt(oldRankIndex, 8)
		net.Send(ply)
	end
end

hook.Add("PlayerInitialSpawn", "gmcore.StoreRank.SetNWintOnSpawn", function(ply)
	ply:SetNWInt("gmcore.StoreRank", tonumber(ply:GetStoreRankPData()))
end)
