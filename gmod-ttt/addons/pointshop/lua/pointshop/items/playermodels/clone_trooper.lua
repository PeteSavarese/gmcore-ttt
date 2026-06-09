if ITEM == nil then
	ITEM = {}
end

ITEM.Name = "Clone Trooper"
ITEM.Price = 2000
ITEM.Model = "models/player/clone_sw/clone_sw_pm.mdl"
ITEM.Section = "Member"

ITEM.Requirements = {
	{type = "ulx_rank", value = "member", description = "Must be a registered forum member"},
}

