---Jondome map sword damage attribution. Attributes trigger_hurt damage from jondome swords to player holding the sword.
if not string.match(string.lower(game.GetMap()), "jondome") then return end

---@param ent Entity Entity to check
---@return boolean isSword True if the entity is jondome sword prop
local function isJondomeSword(ent)
	if ent:GetClass() != "prop_physics" or ent:GetModel() != "models/mcmodelpack/items/sword.mdl" then
		return false
	end

	return true
end

---@param entity Entity Entity to check
---@return boolean isTrigger True if entity is a trigger_hurt
local function isTriggerHurt(entity)
	return entity:GetClass() == "trigger_hurt"
end

hook.Add("EntityTakeDamage", "gmcore.Maps.JondomeSwordTracking", function(victim, dmginfo)
	if !victim:IsPlayer() then return end

	local attacker = dmginfo:GetInflictor()

	if !isTriggerHurt(attacker) then return end

	-- If jondome sword, getattacker simply returns type 'trigger_hurt', calling 'GetParent' gets the ent trigger_hurt is tied to
	local triggerHurtParent = attacker:GetParent()
	if !IsValid(triggerHurtParent) then return end
	if !isJondomeSword(triggerHurtParent) then return end

	if triggerHurtParent.CurrentAttacker == nil then return end

	dmginfo:SetAttacker(triggerHurtParent.CurrentAttacker)
end)

hook.Add("TTTMagnetoPickup", "gmcore.Manhack.ChangeAttacker", function(ply, ent, ghostEnt)
	if !IsValid(ent) then return end
	if !isJondomeSword(ent) then return end

	ent.CurrentAttacker = ply
end)
