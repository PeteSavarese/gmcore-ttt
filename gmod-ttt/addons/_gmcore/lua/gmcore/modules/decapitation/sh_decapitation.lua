DT_PLAYER_HEADSHOT_BOOL = 31
DT_NPC_HEADSHOT_BOOL = 31

local meta = FindMetaTable("NPC")

function meta:WasHeadshotDeath()
	return self:GetDTBool(DT_NPC_HEADSHOT_BOOL) or false
end

---@class Player
local pmeta = FindMetaTable("Player")

function pmeta:WasHeadshotDeath()
	return self:GetDTBool(DT_PLAYER_HEADSHOT_BOOL) or false
end
