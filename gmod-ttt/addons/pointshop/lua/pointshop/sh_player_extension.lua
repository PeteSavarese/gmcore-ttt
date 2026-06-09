---@class Player
local Player = FindMetaTable("Player")

-- Because of the huge variaty of admin mods and their various ways of handling usergroups.
-- This had to be done..
---Returns the player's usergroup, with compatibility for various admin mods.
---@return string The player's usergroup name
function Player:PS_GetUsergroup()
	if ( self.EV_GetRank ) then return self:EV_GetRank() end
	if ( serverguard ) then return serverguard.player:GetRank(self) end
	-- add for each conflicting admin mod.

	return self:GetNWString("UserGroup")
end

---Checks whether the player has fully upgraded a given item.
---@param item_id string The unique identifier of the item to check
---@return boolean True if the item is fully upgraded
function Player:PS_HasUpgrade(item_id)
	local ITEM = PS.Items[item_id]
	if not self.PS_Items then return false end

	local upgradesCount = 1
	if ITEM.UpgradeList then
		upgradesCount = #ITEM.UpgradeList
	end

	local level = self:PS_GetUpgradeLevel(item_id)

	return level >= upgradesCount and true or false
end

--TODO: Check if this method can be used to mimic model permanence
---Returns the current upgrade level for a given item.
---@param item_id string The unique identifier of the item
---@return number The current upgrade level, or 0 if not upgraded
function Player:PS_GetUpgradeLevel(item_id)
	if not self.PS_Items then return 0 end

	local level = 0
	if self.PS_Items[item_id] and self.PS_Items[item_id].Modifiers then
		level = self.PS_Items[item_id].Modifiers.level
	end

	return level or 0
end

---Returns whether the player's model item is permanently equipped.
---@param item_id string The unique identifier of the model item
---@return boolean True if the model is permanently equipped
function Player:PS_GetModelPermanence(item_id)
	if not self.PS_Items or not self.PS_Items[item_id].ModelPerk then return 0 end
	print("permanence result: " .. tostring(self.PS_Items[item_id].Modifiers.permanentEquip ~= false))
	--This is silly but for some reason this returns 0 otherwise.

	return self.PS_Items[item_id].Modifiers.permanentEquip ~= false or false
end
