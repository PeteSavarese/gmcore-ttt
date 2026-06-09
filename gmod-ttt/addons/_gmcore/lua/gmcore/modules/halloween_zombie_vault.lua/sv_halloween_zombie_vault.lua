---Halloween Zombie Vault NPC damage modifications.
local ZOMBIE_TOUGHNESS = 1
local ZOMBIE_DAMAGE = 10
local ANTLION_TOUGHNESS = 1.5
local ANTLION_DAMAGE = 10
local MANHACK_TOUGHNESS = 1.2
local MANHACK_DAMAGE = 5

hook.Add("EntityTakeDamage", "gmcore.ZombieVault.AttributeDamageType", function(ent, dmginfo)
	local attacker = dmginfo:GetAttacker()

	if attacker.Vault and attacker:IsValid() then
		--Attacker is a vault NPC
		local class = attacker:GetClass()

		if class == "npc_fastzombie" or class == "npc_drg_fastzombie" then
			dmginfo:SetDamage(ZOMBIE_DAMAGE)
		elseif class == "npc_antlion" or class == "npc_drg_antlion" then
			dmginfo:SetDamage(ANTLION_DAMAGE)
		elseif class == "npc_manhack" then
			dmginfo:SetDamage(MANHACK_DAMAGE)
		end
	elseif attacker:IsPlayer() and ent.Vault then
		--Victim is a vault NPC
		local class = attacker:GetClass()

		if class == "npc_fastzombie" or class == "npc_drg_fastzombie" then
			dmginfo:SetDamage(ZOMBIE_TOUGHNESS)
		elseif class == "npc_antlion" or class == "npc_drg_antlion" then
			dmginfo:SetDamage(ANTLION_TOUGHNESS)
		elseif class == "npc_manhack" then
			dmginfo:SetDamage(MANHACK_TOUGHNESS)
		end
	end
end)
