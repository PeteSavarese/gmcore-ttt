AddCSLuaFile()

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
		self:SetModel("models/griim/christmas/present_colourable.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self.bInFlight = true

		local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(10)
		end

		self:SetUseType(SIMPLE_USE)
	end

	function ENT:Think()
		if self.bInFlight then
			self:GetPhysicsObject():AddVelocity(Vector(0, 5, 0))
		end
	end

	--[[---------------------------------------------------------
	Name: ENT:PhysicsCollided()
	---------------------------------------------------------]]
	local sZapSound = Sound("npc/assassin/ball_zap1.wav")

	function ENT:PhysicsCollide(data, phys)
		local ent = data.HitEntity

		if ent:IsPlayer() then
			ent:Kill()
			self:Remove()
			-- TODO: !! HIGHWON !! Add additional effects here if you want.
		else
			-- This is the first time we've come in contact with the ground. Start the 3 second timer to zap and disappear
			timer.Simple(3, function()
				if !IsValid(self) then return end -- Removed somehow?

				local effect = EffectData()
				effect:SetOrigin(self:GetPos())
				util.Effect("cball_explode", effect)
				self:EmitSound(sZapSound)

				self:Remove()
			end)
		end

		self.bInFlight = false
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end
