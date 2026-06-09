ITEM.Name = "Santa Hat (Christmas)"
ITEM.Price = 0
ITEM.Model = "models/santa/santa.mdl"
ITEM.Attachment = "eyes"
ITEM.Section = "Cosmetic"

ITEM.Event = "christmas_2025"
ITEM.begin = 0
ITEM["end"] = 1767934799 -- Jan 8, 2026 11:59 PM EST

ITEM.Requirements = {
	{type = "event_playtime", event = "christmas_2025", value = 20, description = "20 hours of event playtime during Christmas 2025"},
}

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideModel(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideModel(self.ID)
end

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
	pos = pos + (ang:Forward() * -5)
	pos = pos + (ang:Up() * -2)

	-- Winter ghille needs santa hat moved above a lot
	if ply:GetModel() == "models/player/joheskiller/ghilliesuit_winter.mdl" then
		pos = pos + (ang:Up() * 5)
	elseif ply:GetModel() == "models/player/leet.mdl" or ply:GetModel() == "models/player/phoenix.mdl" or ply:GetModel() == "models/player/arctic.mdl" then
		pos = pos + (ang:Up() * 3)
		pos = pos + (ang:Forward() * -1.2)
	elseif ply:GetModel() == "models/player/wick/wick_chapter2.mdl" then
		ang:Add(Angle(-90, 0, 0))
	elseif ply:GetModel() == "models/player/anakin/anakin.mdl" then
		pos = pos + (ang:Up() * 3)
		pos = pos + (ang:Forward() * -0.2)
	end

	return model, pos, ang
end
