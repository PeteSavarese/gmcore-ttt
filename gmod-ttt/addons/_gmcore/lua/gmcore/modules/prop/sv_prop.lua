---Prop physics attribution module: attributes damage from prop collisions to physics attacker.

---@type table<integer, {[1]: integer, [2]: number}> EntIndex -> {collidingEntIndex, time}
local collides = {}

---Callback for physics collisions to propagate physics attacker between entities.
---@param ent Entity Entity involved in the physics collision
---@param d table Collision data
local function onPhysicsCollide(ent, d)
	local hitent = d.HitEntity

	if hitent:GetClass() == "dynamic_prop" or hitent:GetClass() == "prop_physics" or hitent:IsWorld() then
		if collides[hitent:EntIndex()] then
			if collides[hitent:EntIndex()][1] ~= ent:EntIndex() or collides[hitent:EntIndex()][2] + 5 < CurTime() then
				collides[hitent:EntIndex()] = { ent:EntIndex(), CurTime() }

				-- TODO: Fix undefined function 'addenttoDM' - should be 'addentToDM' or similar
				-- addenttoDM(ent)
				if hitent:IsWorld() then return end
				-- addenttoDM(hitent)

				if hitent:GetPhysicsAttacker() and not ent:GetPhysicsAttacker() then
					ent:SetPhysicsAttacker(hitent:GetPhysicsAttacker())
				elseif ent:GetPhysicsAttacker() and not hitent:GetPhysicsAttacker() then
					hitent:SetPhysicsAttacker(ent:GetPhysicsAttacker())
				elseif IsValid(hitent:GetOwner()) and not IsValid(ent:GetOwner()) then
					ent:SetPhysicsAttacker(hitent:GetOwner())
				elseif IsValid(ent:GetOwner()) and not IsValid(hitent:GetOwner()) then
					hitent:SetPhysicsAttacker(ent:GetOwner())
				end
			end
		else
			collides[hitent:EntIndex()] = { ent:EntIndex(), CurTime() }

			-- TODO: Fix undefined function 'addenttoDM' - should be 'addentToDM' or similar
			-- addenttoDM(ent)
			if hitent:IsWorld() then return end
			-- addenttoDM(hitent)

			if hitent:GetPhysicsAttacker() and not ent:GetPhysicsAttacker() then
				ent:SetPhysicsAttacker(hitent:GetPhysicsAttacker())
			elseif ent:GetPhysicsAttacker() and not hitent:GetPhysicsAttacker() then
				hitent:SetPhysicsAttacker(ent:GetPhysicsAttacker())
			elseif IsValid(hitent:GetOwner()) and not IsValid(ent:GetOwner()) then
				ent:SetPhysicsAttacker(hitent:GetOwner())
			elseif IsValid(ent:GetOwner()) and not IsValid(hitent:GetOwner()) then
				hitent:SetPhysicsAttacker(ent:GetOwner())
			end
		end
	end
end

hook.Add("TTTPrepareRound", "gmcore.PropSpec.AddPropCallbacks", function()
	timer.Simple(5, function()
		for k, v in ipairs(ents.FindByClass("dynamic_prop")) do
			v:AddCallback("PhysicsCollide", onPhysicsCollide)
		end

		for k, v in ipairs(ents.FindByClass("prop_physics")) do
			v:AddCallback("PhysicsCollide", onPhysicsCollide)
		end
	end)
end)

hook.Add("WeaponEquip", "gmcore.PropSpec.EvictPossessor", function(weapon, ply)
	local SWEP = weapon
	local weaponClass = SWEP:GetClass()

	if weaponClass == "weapon_zm_carry" then
		SWEP.MoveObject_orig = SWEP.MoveObject
		SWEP.Pickup_orig = SWEP.Pickup

		function SWEP:MoveObject(phys, pdir, maxforce, is_ragdoll)
			if ! IsValid(phys) then return end
			PROPSPEC.Kick(phys:GetEntity())

			return self:MoveObject_orig(phys, pdir, maxforce, is_ragdoll)
		end

		function SWEP:Pickup()
			if CLIENT or IsValid(self.EntHolding) then return end

			local trace = ply:GetEyeTrace(MASK_SHOT)

			PROPSPEC.Kick(trace.Entity)
			self:Pickup_orig()
		end
	elseif weaponClass == "weapon_ttt_phammer" then
		function SWEP:CreateHammer(tgt, pos)
			PROPSPEC.Kick(tgt)

			local hammer = ents.Create("ttt_physhammer")

			if IsValid(hammer) then
				local ang = ply:GetAimVector():Angle()
				ang:RotateAroundAxis(ang:Right(), 90)
				hammer:SetPos(pos)
				hammer:SetAngles(ang)
				hammer:Spawn()
				hammer:SetOwner(ply)

				local stuck = hammer:StickTo(tgt)

				if ! stuck then
					hammer:Remove()
				end

				self.hammer = hammer
			end
		end
	end
end)
