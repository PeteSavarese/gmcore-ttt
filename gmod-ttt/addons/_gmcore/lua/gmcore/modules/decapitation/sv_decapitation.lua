---Headshot decapitation effects. Gibs player heads on headshot kills.
AddCSLuaFile("effects/headshot.lua")
AddCSLuaFile("effects/bloodstream.lua")

---@param Ply Player Player whose head will be gibbed
---@param Normal Vector Direction vector of the killing hit
local function gibPlayerHead(Ply, Normal)
	local Head = Ply:LookupBone("valvebiped.bip01_head1")
	if !Head then return end
	local Pos = Ply:GetBonePosition(Head)
	local RagHead = Ply.server_ragdoll:LookupBone("valvebiped.bip01_head1")
	if !RagHead then return end
	Ply.server_ragdoll:ManipulateBoneScale(RagHead, Vector(0, 0, 0))
	local ED = EffectData()
	ED:SetEntity(Ply)
	ED:SetNormal(Normal)
	ED:SetScale(Ply.server_ragdoll:EntIndex())
	ED:SetOrigin(Pos)
	util.Effect("headshot", ED)
end

local blacklist = {"models/player/p2_chell.mdl"}

---@param mdl string Player model path to check
---@return boolean isBlacklisted True if the model is in the decapitation blacklist
local function blacklisted(mdl)
	for k, v in pairs(blacklist) do
		if v == mdl then return true end
	end

	return false
end

-- Player Headshots
---@param Ply Player Player who was killed
---@param Inflictor Entity Weapon or entity that inflicted the fatal damage
---@param Attacker Entity Player or entity responsible for the kill
local function PlayerDeath(Ply, Inflictor, Attacker)
	if GAMEMODE_NAME != "terrortown" then return end
	if !IsValid(Ply.server_ragdoll) then return end
	if !Ply.was_headshot then return end
	if !IsValid(Attacker) or !Attacker:IsPlayer() then return end
	if !IsValid(Attacker:GetActiveWeapon()) then return end
	if Ply.IsGhost and Ply:IsGhost() then return end
	if blacklisted(Ply:GetModel()) then return end

	if Ply.OwnedBlackMarketItems then
		if Ply.OwnedBlackMarketItems[CAT_EQUIPMENT] == "fiber_helmet" then return end
	end

	local Normal = Attacker:GetForward()
	gibPlayerHead(Ply, Normal)
end

hook.Add("PlayerDeath", "HeadshotDecap.PlayerDeath", PlayerDeath)
hook.Remove("DoPlayerDeath", "FWKZT.SandboxHeadshot.DoPlayerDeath")

hook.Add("DoPlayerDeath", "FWKZT.SandboxHeadshot.DoPlayerDeath", function(pl, attacker, dmg)
	if GAMEMODE_NAME != "sandbox" then return end
	pl:SetDTBool(DT_PLAYER_HEADSHOT_BOOL, pl:LastHitGroup() == HITGROUP_HEAD)
end)

hook.Remove("ScaleNPCDamage", "FWKZT.SandboxHeadshot.ScaleNPCDamage")

hook.Add("ScaleNPCDamage", "FWKZT.SandboxHeadshot.ScaleNPCDamage", function(npc, hitgroup, dmginfo)
	if GAMEMODE_NAME != "sandbox" then return end
	npc.LastHitGroup = hitgroup
	npc:SetDTBool(DT_NPC_HEADSHOT_BOOL, hitgroup == HITGROUP_HEAD)
end)

hook.Remove("OnNPCKilled", "FWKZT.SandboxHeadshot.OnNPCKilled")

hook.Add("OnNPCKilled", "FWKZT.SandboxHeadshot.OnNPCKilled", function(npc, attacker, inf)
	if GAMEMODE_NAME != "sandbox" then return end
	npc:SetDTBool(DT_NPC_HEADSHOT_BOOL, npc.LastHitGroup == HITGROUP_HEAD)
end)
