if ITEM == nil then
	ITEM = {}
end

ITEM.Name = "Combine"
ITEM.Price = 2000
ITEM.Model = "models/player/police.mdl"
ITEM.Section = "Member"

ITEM.Requirements = {
	{type = "ulx_rank", value = "member", description = "Must be a registered forum member"},
}

