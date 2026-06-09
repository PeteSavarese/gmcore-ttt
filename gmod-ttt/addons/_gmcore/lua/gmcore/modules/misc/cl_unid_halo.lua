---Highlights unidentified bodies with a red halo for living players.

---@type Color
local color_red = Color(255, 0, 0)
---@type Entity[]
local unidBodies = {}

---Creates a timer that periodically finds unidentified bodies near the local player.
local function createSphereCheckingTimer()
	timer.Create("gmcore.Misc.UnidBodiesCheckSphere", 0.5, 0, function()
		if !LocalPlayer then return end
		if !LocalPlayer().IsActive then return end
		if !LocalPlayer():IsActive() then return end
		if !GetConVar("ttt_unid_halo"):GetBool() then return end

		unidBodies = {} -- Clear table first

		for _, ent in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 500)) do
			if ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, false) != false and !CORPSE.GetFound(ent, false) then
				table.insert(unidBodies, ent)
			end
		end
	end)
end

hook.Add("PreDrawHalos", "gmcore.Misc.HaloUnidBodies", function()
	if !LocalPlayer():IsActive() then return end
	if !GetConVar("ttt_unid_halo"):GetBool() then return end

	halo.Add(unidBodies, color_red, 1, 1)
end)

hook.Add("InitPostEntity", "gmcore.Misc.UnidBodiesInitTimer", function()
	createSphereCheckingTimer()
end)

-- Add this for when Lua autorefresh is run
if LocalPlayer != nil then
	createSphereCheckingTimer()
end
