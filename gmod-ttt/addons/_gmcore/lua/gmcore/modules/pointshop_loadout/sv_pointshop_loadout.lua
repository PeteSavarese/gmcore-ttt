util.AddNetworkString("gmcore.Loadout.UpdateLoadout")
util.AddNetworkString("gmcore.Loadout.SendConfig")

---Grabs random weapon from weapon list.
---@param weaponTable string[]
---@return string
local function getRandomWeapon(weaponTable)
	if not weaponTable or #weaponTable <= 1 then return "" end

	return weaponTable[math.random(2, #weaponTable)]
end

net.Receive("gmcore.Loadout.UpdateLoadout", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local tLoadout = net.ReadTable()
	local sLoadout = util.TableToJSON(tLoadout or {})

	ply:SetPData("gmcore.Loadout.CurrentLoadout", sLoadout)
	net.Start("gmcore.Loadout.UpdateLoadout")
	net.WriteTable(tLoadout or {})
	net.Send(ply)
end)

---Send loadout config to player (or everyone if no player provided).
---I'm not sure why I added net.Broadcast, but if I remove it I know something will break... so it stays
---@param ply? Player Player to send the config to. If nil, will be sent to all players.
function gmcore.Loadout.SendConfig(ply)
	local snapshot = gmcore.Loadout.GetConfigSnapshot()
	net.Start("gmcore.Loadout.SendConfig")
	net.WriteTable(snapshot)

	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

hook.Add("gmcore.Loadout.ConfigReady", "gmcore.Loadout_BroadcastConfig", function()
	gmcore.Loadout.SendConfig()
end)

hook.Add("PlayerLoadout", "gmcore.Loadout_GiveLoadout", function(ply)
	local loadoutFile = ply:GetPData("gmcore.Loadout.CurrentLoadout")
	if loadoutFile == nil then return end
	if not ply:Alive() or ply:IsSpec() then return end

	local loadout = util.JSONToTable(loadoutFile)
	if not loadout or loadout == "" then return end

	for slot, weapon in pairs(loadout) do
		local cat = gmcore.Loadout.Categories[slot]
		if not cat then continue end
		if not gmcore.Loadout.HasAccess(ply, cat.Rank) then continue end

		local normalized = gmcore.Loadout.NormalizeSelection(weapon)
		if normalized == "random" then
			normalized = getRandomWeapon(cat.Items)
		end

		if normalized == "" then continue end
		if table.HasValue(cat.Exclude, normalized) then continue end
		if not weapons.Get(normalized) then continue end
		if ply:HasWeapon(normalized) then continue end

		ply:Give(normalized)

		if ply:IsStoreRank() and ply:GetStoreRank() > cat.Rank then
			local tWepInfo = weapons.Get(normalized)

			if tWepInfo and tWepInfo.Primary and tWepInfo.Primary.Ammo then
				ply:GiveAmmo(tWepInfo.Primary.ClipMax, tWepInfo.Primary.Ammo)
			end
		end
	end
end)

hook.Add("PlayerInitialSpawn", "gmcore.Loadout_SendCurrentSelections", function(ply)
	gmcore.Loadout.SendConfig(ply)

	local sLoadoutFile = ply:GetPData("gmcore.Loadout.CurrentLoadout")
	if sLoadoutFile == nil then return end

	local tLoadout = util.JSONToTable(sLoadoutFile)
	if tLoadout and tLoadout ~= "" then
		net.Start("gmcore.Loadout.UpdateLoadout")
		net.WriteTable(tLoadout)
		net.Send(ply)
	end
end)
