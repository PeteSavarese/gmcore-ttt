---Firework rocket entity for the fun round. A launched projectile that flies upward and detonates with an explosion effect.
AddCSLuaFile()

if CLIENT then
	ENT.PrintName = "Firework (FUN ROUND)"
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
		self:SetModel("models/models/gf2/rogue_cheney/rockets/big/rocket_01.mdl")
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
		self.Hit = Sound("gmcore/july4/firework/impact_player.mp3")
		self:GetPhysicsObject():SetMass(2)
		self:SetUseType(SIMPLE_USE)
		self.CanTool = false
	end

	--[[---------------------------------------------------------
	Name: ENT:ExplosionEffect()
	---------------------------------------------------------]]
	function ENT:ExplosionEffect(pos)
		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		-- these don't have much effect with the default Explosion
		effect:SetScale(1)
		effect:SetRadius(1)
		effect:SetMagnitude(0)
		effect:SetOrigin(pos)

		util.BlastDamage(self, self:GetOwner(), pos, 100, 200)

		util.Effect("Explosion", effect, true, true)
		util.Effect("HelicopterMegaBomb", effect, true, true)
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
		if !IsValid(self:GetOwner()) then print("no owner") return end

		local dmg = DamageInfo()
		dmg:SetDamage(2000)
		dmg:SetAttacker(self:GetOwner())
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

		local firework = self

		other.effect_fn = function(rag)
				if !IsValid(firework) or !IsValid(rag) then
					return
				end

				firework:SetPos(pos)
				firework:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				firework:SetAngles(ang)
				firework:SetMoveCollide(MOVECOLLIDE_DEFAULT)
				firework:SetMoveType(MOVETYPE_VPHYSICS)
				--firework:SetSolid(SOLID_NONE)
				-- firework needs to be trace-able to get prints
				local phys = firework:GetPhysicsObject()

				if IsValid(phys) then
					phys:EnableCollisions(false)
				end

				constraint.Weld(rag, firework, bone, 0, 0, true)

				rag:CallOnRemove("ttt_firework_cleanup", function()
					SafeRemoveEntity(firework)
				end)
		end

		self:ExplosionEffect(other:GetPos())

		other:DispatchTraceAttack(dmg, self:GetPos() + ang:Forward() * 3, other:GetPos())
		self:EmitSound(self.Hit)

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
			self:EmitSound(self.Hit)
			self:ExplosionEffect(self:GetPos())
			self:Remove()
		elseif ent.Health then
			if !ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll" then
				util.Decal("ManhackCut", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
				self:EmitSound(self.Hit)
				self:ExplosionEffect(self:GetPos())
				self:Remove()
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
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
