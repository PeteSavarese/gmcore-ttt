---@class gmcore
---@field Ranks table<string, RankInfo> Staff rank definitions

-- `hasStaffPerms` is used around the codebase, but it was a stopgap for not making an actual ulx perm. This should be removed in the future.

---@class RankInfo
---@field color Color Display color for the rank
---@field niceName string Human-readable rank name
---@field hasStaffPerms boolean Whether this rank has staff permissions???

---Staff rank definitions keyed by ULX group name
---@type table<string, RankInfo>
gmcore.Ranks = {
	["owner"] = {
		color = Color(255, 0, 0),
		niceName = "Owner",
		hasStaffPerms = true
	},
	["communitymanager"] = {
		color = Color(187, 51, 68),
		niceName = "Community Manager",
		hasStaffPerms = true
	},
	["developer"] = {
		color = Color(255, 181, 255),
		niceName = "Developer",
		hasStaffPerms = true
	},
	["leadadmin"] = {
		color = Color(255, 165, 0),
		niceName = "Lead Administrator",
		hasStaffPerms = true
	},
	["admin"] = {
		color = Color(0, 128, 255),
		niceName = "Administrator",
		hasStaffPerms = true
	},
	["mod"] = {
		color = Color(0, 255, 249),
		niceName = "Moderator",
		hasStaffPerms = true
	},
	["trialmod"] = {
		color = Color(153, 255, 204),
		niceName = "Trial Moderator",
		hasStaffPerms = true
	},
	["advisor"] = {
		color = Color(204, 255, 102),
		niceName = "Advisor",
		hasStaffPerms = false
	},
}

---@class Player
local a = FindMetaTable("Player")

---Returns store rank index if player has an active store rank, false otherwise
---@return number|false rankIndex The store rank index, or false if the player has no store rank
function a:StoreRank()
	if self:IsStoreRank() then return self:GetStoreRank() end

	return false
end

---Returns ULX usergroup name if player has a staff rank, false otherwise
---@return string|false groupName The ULX usergroup name, or false if the player has no staff rank
function a:StaffRank()
	if self:IsStaffRank() then return self:GetNWString("UserGroup") end

	return false
end

---Returns rank info table if player has a staff rank in gmcore.Ranks, false otherwise
---@return RankInfo|false rankInfo The rank info table, or false if the player has no staff rank
function a:IsStaffRank()
	return gmcore.Ranks[self:GetUserGroup()] or false
end

---Returns whether the player's ULX group has staff permissions as defined in gmcore.Ranks
---@return boolean hasPerms True if the player's ULX group has staff permissions
function a:HasStaffPerms()
	return gmcore.Ranks[self:GetUserGroup()] and gmcore.Ranks[self:GetUserGroup()].hasStaffPerms or false
end

---Returns whether the player is alive and not spectating. TTT gets wonky with spectators counting as being alive, so this is a reliable method for TTT
---@return boolean alive True if the player is valid, alive, and not spectating
function a:IsAlive()
	if IsValid(self) and self:Alive() and ! self:GetForceSpec() and ! self:IsSpec() then return true end

	return false
end
