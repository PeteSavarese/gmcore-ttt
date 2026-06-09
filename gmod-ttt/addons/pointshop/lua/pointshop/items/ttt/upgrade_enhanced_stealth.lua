ITEM.Name = "Incognito"
ITEM.Price = 8000
ITEM.Material = "vgui/ttt/icon_disguise"
ITEM.OneUse = true
ITEM.Section = 0
ITEM.Description = "Level 1 hides your playermodel when disguised. Level 2 removes footstep sounds when a disguiser is equipped."

ITEM.UpgradeList = {}
ITEM.UpgradeList[1] = 8000
ITEM.UpgradeList[2] = 10000

local disguiseTable = {}	--Holds playermodels of those who need it when they disable their disguiser. Doesn't actually have to be here.

if SERVER then
	util.AddNetworkString("gmcore.SilentFootstepsAlert")
end

function ITEM:OnBuy(ply)

end

function ITEM:OnUpgrade(ply)

end

function ITEM:OnEquip(ply, modifications)

end

function ITEM:OnHolster(ply)

end

local function findModelID(ply)
	for k, v in pairs(PS.Items) do
		if v["Category"] == "Playermodels" and ply:PS_HasItemEquipped(k) then return k end
	end
end

hook.Add("TTTToggleDisguiser", "gmcore.InventoryShop.CheckDisguiserPerk", function(ply, state)
	if state and IsValid(ply) and ply:PS_HasItemEquipped("upgrade_enhanced_stealth") then
		local temp = findModelID(ply)
		disguiseTable[ply:SteamID64()] = temp
		ply:PS_HolsterItem(temp)
	end

	if not state and IsValid(ply) then
		if disguiseTable[ply:SteamID64()] then ply:PS_EquipItem(disguiseTable[ply:SteamID64()]) end
		disguiseTable[ply:SteamID64()] = nil
	end
end)

hook.Add("PlayerDeath", "gmcore.CheckLingeringPlayerModel", function(victim, weapon, attacker)
	if disguiseTable[victim:SteamID64()] then
		victim:PS_EquipItem(disguiseTable[victim:SteamID64()])
		disguiseTable[victim:SteamID64()] = nil
	end
end)

hook.Add("TTTEndRound", "ClearDisguiseTable", function()
	for _, ply in player.Iterator() do
		if disguiseTable[ply:SteamID64()] and IsValid(ply) then
			ply:PS_EquipItem(disguiseTable[ply:SteamID64()])
		end
	end

	disguiseTable = {}
end)

hook.Add("TTTToggleDisguiser", "gmcore.CheckFootstepPerk", function(ply, state)
	if state and IsValid(ply) and ply:PS_HasItemEquipped("upgrade_enhanced_stealth") and (ply:PS_GetUpgradeLevel("upgrade_enhanced_stealth") > 1) then
		net.Start("gmcore.SilentFootstepsAlert")
		net.WriteEntity(ply)
		net.WriteBool(state)
		net.Broadcast()
	end

	if not state and IsValid(ply) and ply:PS_HasItemEquipped("upgrade_enhanced_stealth") and (ply:PS_GetUpgradeLevel("upgrade_enhanced_stealth") > 1) then
		net.Start("gmcore.SilentFootstepsAlert")
		net.WriteEntity(ply)
		net.WriteBool(state)
		net.Broadcast()
	end
end)
