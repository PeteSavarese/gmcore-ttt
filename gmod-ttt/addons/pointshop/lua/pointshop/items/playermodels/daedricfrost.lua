if ITEM == nil then
	ITEM = {}
end

ITEM.Name = "Daedric Frost"
ITEM.Price = 0
ITEM.Model = "models/player/daedricfrost/daedricfrost.mdl"
ITEM.Section = 2

ITEM.Event = "christmas_2025"
ITEM.begin = 0
ITEM["end"] = 1767934799 -- Jan 8, 2026 11:59 PM EST

ITEM.Requirements = {
	{type = "event_playtime", event = "christmas_2025", value = 20, description = "20 hours of event playtime during Christmas 2025"},
}
