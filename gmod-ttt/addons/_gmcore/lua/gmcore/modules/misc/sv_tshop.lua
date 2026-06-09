---Traitor shop warnings: notifies traitor team when dangerous items are bought or placed.

---@type string[] Weapon classes that trigger a buy warning to all traitors
local buywarn = {"weapon_ttt_jihad"}

---@type table<string, string> Entity class -> display name for place warnings
local placewarn = {}
placewarn["ttt_death_station"] = "Death Station"
placewarn["ttt_tripmine"] = "Tripmine"

hook.Add("TTTOrderedEquipment", "gmcore.Misc.TraitorBuyExplosiveWarning", function(ply, id, is_item)
	if table.HasValue(buywarn, id) then
		for _, p in ipairs(player.GetAll()) do
			if p:IsAlive() and p:GetTraitor() then
				gmcore.chatprint(p, Color(255, 0, 0), "WARNING: A Jihad has been bought.")
			end
		end
	end
end)

hook.Add("OnEntityCreated", "gmcore.Misc.TraitorPlaceExplosiveWarning", function(ent)
	local id = ent:GetClass()

	if placewarn[id] then
		for _, p in ipairs(player.GetAll()) do
			if p:IsAlive() and p:GetTraitor() then
				gmcore.chatprint(p, Color(255, 0, 0), "WARNING: A " .. placewarn[id] .. " has been placed.")
			end
		end
	end
end)
