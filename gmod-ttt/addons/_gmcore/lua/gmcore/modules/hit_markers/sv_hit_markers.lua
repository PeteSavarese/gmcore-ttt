util.AddNetworkString("gmcore.HitMarkers.SendHitConfirm")

hook.Add("PlayerHurt", "gmcore.Misc.HitMarkers.PlayerHurt", function(_, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	net.Start("gmcore.HitMarkers.SendHitConfirm")
	net.Send(attacker)
end)
