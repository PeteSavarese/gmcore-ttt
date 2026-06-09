---TTT spectator prop possession for PS upgrade "prop meddling"
---Integrates Pointshop upgrades for punch recharge speed.

local string = string
local math = math

---@class PROPSPEC
PROPSPEC = {}

local propspec_toggle = CreateConVar("ttt_spec_prop_control", "1")

local propspec_base = CreateConVar("ttt_spec_prop_base", "8")
local propspec_min = CreateConVar("ttt_spec_prop_maxpenalty", "-6")
local propspec_max = CreateConVar("ttt_spec_prop_maxbonus", "16")

---@param ply Player The spectator who is possessing a prop
---@param ent Entity The physics entity being possessed
function PROPSPEC.Start(ply, ent)
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(ent, true)

	local bonus = math.Clamp(math.ceil(ply:Frags() / 2), propspec_min:GetInt(), propspec_max:GetInt())

	ply.propspec = {ent=ent, t=0, retime=0, punches=0, max=propspec_base:GetInt() + bonus}

	ent:SetNWEntity("spec_owner", ply)
	ent.spec_owner = ply
	ent.spec_time = os.time()
	ply:SetNWInt("bonuspunches", bonus)
end

local function IsWhitelistedClass(cls)
	return (string.match(cls, "prop_physics*") or
		string.match(cls, "func_physbox*"))
end

---@param ply Player The spectator attempting possession
---@param ent Entity The candidate entity to possess
function PROPSPEC.Target(ply, ent)
	if not propspec_toggle:GetBool() then return end
	if (not IsValid(ply)) or (not ply:IsSpec()) or (ply.curSlayRound) or (not IsValid(ent)) then return end
	if ent.AllowPropspec == false then return end

	if IsValid(ent:GetNWEntity("spec_owner", nil)) then return end

	local phys = ent:GetPhysicsObject()

	if ent:GetName() != "" and (not GAMEMODE.propspec_allow_named) then return end
	if (not IsValid(phys)) or (not phys:IsMoveable()) then return end

	-- normally only specific whitelisted ent classes can be possessed, but
	-- custom ents can mark themselves possessable as well
	if (not ent.AllowPropspec) and (not IsWhitelistedClass(ent:GetClass())) then return end

	if(ent.SpecLock and ent.SpecLock > os.time() - 10) then return end

	for k, v in pairs(player.GetAll()) do
		if v:IsActive() then
			local wep = v:GetActiveWeapon()

			if IsValid(wep) && wep:GetClass() == "weapon_zm_carry" && IsValid(wep.EntHolding) then
				if(wep.EntHolding == ent) then return end
			end
		end
	end

	PROPSPEC.Start(ply, ent)
end

---@param ent Entity The entity to remove the spectator from
function PROPSPEC.Kick(ent)
	local ply = ent:GetNWEntity("spec_owner")
	if(IsValid(ply)) then
		PROPSPEC.End(ply) -- remove player from prop
	end
	ent.spec_owner = nil -- remove log info as they arnt in control
	ent.spec_time = 0
	ent.SpecLock = os.time()
end

-- Clear any propspec state a player has. Safe even if player is not currently
-- spectating.
---@param ply Player Player to clear propspec state for
function PROPSPEC.Clear(ply)
	local ent = (ply.propspec and ply.propspec.ent) or ply:GetObserverTarget()
	if IsValid(ent) then
		ent:SetNWEntity("spec_owner", nil)
		ent.spec_time = os.time();
	end

	ply.propspec = nil
	ply:SpectateEntity(nil)
end

---@param ply Player Player to stop possessing and return to roaming
function PROPSPEC.End(ply)
	PROPSPEC.Clear(ply)
	ply:Spectate(OBS_MODE_ROAMING)
	ply:ResetViewRoll()

	timer.Simple(0.1, function()
		if IsValid(ply) then ply:ResetViewRoll() end
	end)
end

local propspec_force = CreateConVar("ttt_spec_prop_force", "110")

---@param ply Player The spectator controlling the prop
---@param key number IN_* key constant
---@return boolean consumed Whether the key press was handled
function PROPSPEC.Key(ply, key)
	local ent = ply.propspec.ent
	local phys = IsValid(ent) and ent:GetPhysicsObject()
	if (not IsValid(ent)) or (not IsValid(phys)) then
		PROPSPEC.End(ply)
		return false
	end

	if not phys:IsMoveable() then
		PROPSPEC.End(ply)
		return true
	elseif phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
		-- we can stay with the prop while it's held, but not affect it
		if key == IN_DUCK then
			PROPSPEC.End(ply)
		end
		return true
	end

	-- always allow leaving
	if key == IN_DUCK then
		PROPSPEC.End(ply)
		return true
	end

	local pr = ply.propspec
	if pr.t > CurTime() then return true end

	if pr.punches < 1 then return true end

	local m = math.min(150, phys:GetMass())
	local force = propspec_force:GetInt()
	local aim = ply:GetAimVector()

	local mf = m * force

	pr.t = CurTime() + 0.15

	if key == IN_JUMP then
		-- upwards bump
		phys:ApplyForceCenter(Vector(0,0, mf))
		pr.t = CurTime() + 0.05
	elseif key == IN_FORWARD then
		-- bump away from player
		phys:ApplyForceCenter(aim * mf)
	elseif key == IN_BACK then
		phys:ApplyForceCenter(aim * (mf * -1))
	elseif key == IN_MOVELEFT then
		phys:AddAngleVelocity(Vector(0, 0, 200))
		phys:ApplyForceCenter(Vector(0,0, mf / 3))
	elseif key == IN_MOVERIGHT then
		phys:AddAngleVelocity(Vector(0, 0, -200))
		phys:ApplyForceCenter(Vector(0,0, mf / 3))
	else
		return true -- eat other keys, and do not decrement punches
	end

	pr.punches = math.max(pr.punches - 1, 0)
	ply:SetNWFloat("specpunches", pr.punches / pr.max)

	return true
end

local propspec_retime = CreateConVar("ttt_spec_prop_rechargetime", "1")

---@param ply Player The spectator whose punches to recharge
function PROPSPEC.Recharge(ply)
	local pr = ply.propspec
	if pr.retime < CurTime() then
		pr.punches = math.min(pr.punches + 1, pr.max)
		ply:SetNWFloat("specpunches", pr.punches / pr.max)

		if ply:PS_HasItemEquipped("upgrade_proppunch_recharge") and ply:PS_GetUpgradeLevel("upgrade_proppunch_recharge") > 0 then
			pr.retime = CurTime() + (propspec_retime:GetFloat() * (1 - (ply:PS_GetUpgradeLevel("upgrade_proppunch_recharge") * .15)))
		else
			pr.retime = CurTime() + propspec_retime:GetFloat()
		end
	end
end

---@param dmg CTakeDamageInfo Damage info to inspect
---@return Player|nil spec The spectator who caused the damage, or nil
function PROPSPEC.IsSpectatorDmg(dmg)
	local att = dmg:GetAttacker()
	local spec = att:GetNWEntity("spec_owner", nil)
	if(not IsValid(spec)) then
		if(IsValid(att.spec_owner) and att.spec_time and att.spec_time > os.time() - 5) then
			spec = att.spec_owner
		end
	end
	return spec
end
