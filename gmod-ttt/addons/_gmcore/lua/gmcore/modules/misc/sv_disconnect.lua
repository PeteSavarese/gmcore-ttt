hook.Add("PlayerDisconnected", "PlayerDisconnectedandDrop", function(ply)
	for k, wep in ipairs(ply:GetWeapons()) do
		WEPS.DropNotifiedWeapon(ply, wep, true) -- with ammo in them
		wep:DampenDrop()
	end
end)
