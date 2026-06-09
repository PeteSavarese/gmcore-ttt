AddCSLuaFile()

if CLIENT then
	ENT.PrintName = "Grapple Hook"
end

ENT.Type = "anim"

ENT.Projectile = true -- When true, score code considers us a weapon
ENT.Stuck = false
ENT.Weaponised = false
ENT.CanHavePrints = false
ENT.IsSilent = true
ENT.CanPickup = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsHooked")
	self:NetworkVar("Bool", 0, "InFlight")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_c17/TrapPropeller_Lever.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()

		--self.NextThink = CurTime() +  1
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(10)
		end

		self:GetPhysicsObject():SetMass(2)
		self:SetUseType(SIMPLE_USE)
		self.CanTool = false

		self:SetInFlight(true)
	end
end

--[[---------------------------------------------------------
Name: ENT:PhysicsCollided()
---------------------------------------------------------]]
function ENT:PhysicsCollide(data, phys)
	local ent = data.HitEntity

	if ent:IsWorld() then
		-- Throwing this in a timer prevents console from being spammed about changing collision rules in a callback
		timer.Simple(0,function()
			if !IsValid(self) then return end

			self:EmitSound(Sound("physics/metal/metal_barrel_impact_hard7.wav"))
			self:SetCollisionGroup(COLLISION_GROUP_WORLD)
			self:SetPos(data.HitPos)
			self:GetPhysicsObject():EnableMotion(false)

			local ang = data.HitNormal:Angle()
			ang:RotateAroundAxis(ang:Up(), 90)
			self:SetAngles(ang)

			self:SetIsHooked(true)
			self:SetInFlight(false)
		end)
	end
end
