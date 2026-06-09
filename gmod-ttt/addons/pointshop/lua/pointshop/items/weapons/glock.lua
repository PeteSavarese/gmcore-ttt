if ITEM == nil then
	ITEM = {}
end

ITEM.Name = "Glock 18"
ITEM.Price = 10
ITEM.Class = "weapon_ttt_glock"
ITEM.Section = "Secondary"
ITEM.Model = ""
ITEM.SingleUse = true

function ITEM:OnBuy(ply)
	local tWepInfo = weapons.Get(self.Class)

	// Drop current weapon in slot
	for _, plyWep in ipairs(ply:GetWeapons()) do
		local tCurWepInfo = weapons.Get(plyWep:GetClass())
		if tCurWepInfo == nil then continue end

		if tCurWepInfo.Kind == tWepInfo.Kind then
			ply:DropWeapon(plyWep)
		end
	end

	ply:Give(self.Class)
	ply:SelectWeapon(self.Class)
	ply:GiveAmmo(tWepInfo.Secondary.ClipSize, tWepInfo.Secondary.Ammo)
end
