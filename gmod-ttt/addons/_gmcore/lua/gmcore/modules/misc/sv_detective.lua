---Detectives get a police playermodel.
---@type string
local mdl = "models/player/elispolice/police.mdl"

hook.Add("PlayerSetModel", "gmcore.Misc.DetectiveModel", function(ply)
	if not IsValid(ply) then return end
	if not ply.IsActiveDetective or not ply:IsActiveDetective() then return end

	ply:SetModel(mdl)
end)

hook.Add("TTTBeginRound", "gmcore.Misc.ApplyDetectiveModel", function()
	for _, v in player.Iterator() do
		if v:IsActiveDetective() then
			v:SetModel(mdl)
		end
	end
end)
