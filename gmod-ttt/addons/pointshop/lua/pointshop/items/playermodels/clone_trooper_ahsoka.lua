if ITEM == nil then
	ITEM = {}
end

local UNLOCK_TIME = 0 -- Visible upon event start
local END_TIME = 1757051999 -- September 9, 2025

ITEM.Name = "Ahsoka Clone Trooper"
ITEM.Price = 0
ITEM.Model = "models/player/clone_sw/clone_sw_pm.mdl"
ITEM.Skin = 1
ITEM.Section = "Event"
ITEM.begin = UNLOCK_TIME
ITEM["end"] = END_TIME

ITEM.Requirements = {
	{type = "ulx_rank", value = "member", description = "Registered on the forums"},
	{type = "playtime", value = 50, description = "50 hours of playtime"},
}
