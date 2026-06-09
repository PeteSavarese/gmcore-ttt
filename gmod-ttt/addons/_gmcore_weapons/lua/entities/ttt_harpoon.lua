AddCSLuaFile()

if CLIENT then
	ENT.PrintName = "Harpoon"
	ENT.Icon = "vgui/ttt/icon_gl_harpoon"
end


ENT.Type = "anim"

-- When true, score code considers us a weapon
ENT.Projectile = true

ENT.Stuck = false
ENT.Weaponised = false
ENT.CanHavePrints = false
ENT.IsSilent = true
ENT.CanPickup = false

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_junk/harpoon002a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()

		--self.NextThink = CurTime() +  1
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(10)
		end

		self.InFlight = true
		self.CreateTime = CurTime()

		util.PrecacheSound("physics/metal/metal_grenade_impact_hard3.wav")
		util.PrecacheSound("physics/metal/metal_grenade_impact_hard2.wav")
		util.PrecacheSound("physics/metal/metal_grenade_impact_hard1.wav")
		util.PrecacheSound("physics/flesh/flesh_impact_bullet1.wav")
		util.PrecacheSound("physics/flesh/flesh_impact_bullet2.wav")
		util.PrecacheSound("physics/flesh/flesh_impact_bullet3.wav")
		self.Hit = {Sound("physics/metal/metal_grenade_impact_hard1.wav"), Sound("physics/metal/metal_grenade_impact_hard2.wav"), Sound("physics/metal/metal_grenade_impact_hard3.wav")}
		self.FleshHit = {Sound("physics/flesh/flesh_impact_bullet1.wav"), Sound("physics/flesh/flesh_impact_bullet2.wav"), Sound("physics/flesh/flesh_impact_bullet3.wav")}

		self:GetPhysicsObject():SetMass(2)
		self:SetUseType(SIMPLE_USE)
		self.CanTool = false
	end

	--[[---------------------------------------------------------
	Name: ENT:Think()
	---------------------------------------------------------]]
	function ENT:Think()
		if self.InFlight and self:GetAngles().pitch <= 55 then
			self:GetPhysicsObject():AddAngleVelocity(Vector(0, 10, 0))
		end
	end

	--[[---------------------------------------------------------
	Name: ENT:Disable()
	---------------------------------------------------------]]
	function ENT:Disable()
		self.PhysicsCollide = function() end
		self.InFlight = false
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	end

	--[[---------------------------------------------------------
	Name: ENT:KillPlayer()
	Description: Striped this from knife code entity
	---------------------------------------------------------]]
	function ENT:KillPlayer(other, tr)
		local dmg = DamageInfo()
		dmg:SetDamage(2000)

		if IsValid(self:GetOwner()) then
			dmg:SetAttacker(self:GetOwner())
		end

		dmg:SetInflictor(self)
		dmg:SetDamageForce(self:EyeAngles():Forward())
		dmg:SetDamagePosition(self:GetPos())
		dmg:SetDamageType(DMG_CLUB)

		-- this bone is why we need the trace
		local bone = tr.PhysicsBone
		local pos = tr.HitPos
		local norm = tr.Normal
		local ang = Angle(-28, 0, 0) + norm:Angle()
		ang:RotateAroundAxis(ang:Right(), -90)
		pos = pos - (ang:Forward() * 8)

		local harpoon = self
		local prints = self.fingerprints

		other.effect_fn = function(rag)
				if !IsValid(harpoon) or !IsValid(rag) then
					return
				end

				harpoon:SetPos(pos)
				harpoon:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				harpoon:SetAngles(ang)
				harpoon:SetMoveCollide(MOVECOLLIDE_DEFAULT)
				harpoon:SetMoveType(MOVETYPE_VPHYSICS)
				harpoon.fingerprints = prints
				harpoon:SetNWBool("HasPrints", true)
				--harpoon:SetSolid(SOLID_NONE)
				-- harpoon needs to be trace-able to get prints
				local phys = harpoon:GetPhysicsObject()

				if IsValid(phys) then
					phys:EnableCollisions(false)
				end

				constraint.Weld(rag, harpoon, bone, 0, 0, true)

				rag:CallOnRemove("ttt_harpoon_cleanup", function()
					SafeRemoveEntity(harpoon)
				end)

				-- self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		end

		other:DispatchTraceAttack(dmg, self:GetPos() + ang:Forward() * 3, other:GetPos())
		self:EmitSound(self.FleshHit[math.random(1,#self.Hit)])

		self.KilledPly = other
		self.Stuck = true
	end

	--[[---------------------------------------------------------
	Name: ENT:PhysicsCollided()
	---------------------------------------------------------]]
	function ENT:PhysicsCollide(data, phys)
		pain = data.Speed / 4
		local ent = data.HitEntity
		local vel = self:GetVelocity()

		if ent:IsWorld() and self.InFlight then
			if data.Speed > 500 then
				self:EmitSound(Sound("weapons/blades/impact.mp3"))

				-- Store data for deferred collision changes
				local hitPos = data.HitPos
				local hitNormal = data.HitNormal
				local currentAngles = self:GetAngles()

				-- Defer collision changes to avoid crashes
				timer.Simple(0, function()
					if !IsValid(self) then return end

					self:SetPos(hitPos - hitNormal * 10)
					self:SetAngles(currentAngles)

					local physics = self:GetPhysicsObject()

					if IsValid(physics) then
						physics:EnableMotion(false)
					end
				end)
			else
				self:EmitSound(self.Hit[math.random(1, #self.Hit)])
			end

			-- Defer the disable call as well
			timer.Simple(0, function()
				if IsValid(self) then
					self:Disable()
				end
			end)

		elseif ent.Health then
			if !ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" then
				util.Decal("ManhackCut", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
				self:EmitSound(self.Hit[math.random(1, #self.Hit)])

				-- Defer disable call
				timer.Simple(0, function()
					if IsValid(self) then
						self:Disable()
					end
				end)
			end

			if ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" then
				-- From here, ent = ply
				-- tr is also striped from weapon code, but endpos is changed to be the player's position.
				local tr = util.TraceLine({
					start = self:GetPos(),
					endpos = ent:GetPos(),
					filter = {self, self:GetOwner()},
					mask = MASK_SHOT_HULL
				})

				self:KillPlayer(ent, tr)
			end
		end

		-- Defer owner removal as well
		timer.Simple(0, function()
			if IsValid(self) then
				self:SetOwner(NULL)
			end
		end)
	end

	--[[---------------------------------------------------------
	Name: ENT:Use()
	---------------------------------------------------------]]
	function ENT:Use(activator, caller)
		if not IsValid(activator) or not activator:IsPlayer() then return end

		---@cast activator Player

		if self.KilledPly != nil then return end -- Harpoon has impacted ply. Don't allow
		if self.isTriple then return end -- Don't allow the extra harpoons to be able to be picked up and then thrown again to generate harpoon spam.
		if self.CreateTime + 2 >= CurTime() then return end -- Don't allow people to spam by throwing a harpoon on the ground and then picking up right after and then throwing again
		if not activator:CanCarryType(WEAPON_EQUIP1) then return end

		activator:Give("weapon_ttt_harpoon")
		self:Remove()
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
