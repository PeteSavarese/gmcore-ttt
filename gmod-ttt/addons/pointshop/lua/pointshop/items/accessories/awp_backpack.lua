ITEM.Name = 'AWP Backpack'
ITEM.Price = 6600
ITEM.Model = 'models/weapons/w_snip_awp.mdl'
ITEM.Bone = 'ValveBiped.Bip01_Spine2'
ITEM.Section = "Cosmetic"

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideModel(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideModel(self.ID)
end

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
	model:SetModelScale(0.8, 0)
	pos = pos + (ang:Right() * 5) + (ang:Up() * -7) + (ang:Forward() * 2)
	return model, pos, ang
end
