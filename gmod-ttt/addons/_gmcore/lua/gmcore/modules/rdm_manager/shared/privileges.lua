---Damagelog privilege checks for Player metatable.

-- edit the privileges on shared/config.lua
local function checkSettings(self, value)
	local round_state = GetRoundState()

	if value == 1 or value == 2 then
		return round_state ~= ROUND_ACTIVE
	elseif value == 3 then
		return round_state ~= ROUND_ACTIVE or self:IsSpec()
	elseif value == 4 then
		return true
	end

	return false
end

local meta = FindMetaTable("Player")

---@return boolean canUse True if the player has permission to view the damage log
function meta:CanUseDamagelog()
	local value = Damagelog.User_rights[self:GetUserGroup()]
	if value then
		return checkSettings(self, value)
	end

	return checkSettings(self, 2)
end

---@return boolean canUse True if the player has permission to use the RDM manager
function meta:CanUseRDMManager()
	return Damagelog.RDM_Manager_Rights[self:GetUserGroup()]
end
