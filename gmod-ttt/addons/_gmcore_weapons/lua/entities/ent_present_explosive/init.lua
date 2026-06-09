AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/present/launcher_present.mdl")
	self:SetSubMaterial(0, "present/present_ribbon")
	self:SetSubMaterial(1, "present/present_red")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	phys:Wake()

	-- util.SpriteTrail(self, 0, Color( 255, 255, 255, 255), false, 6, 6, 3, 1/(6+6)*0.5, "trails/tinsel_trail.vmt")
	-- ParticleEffect( "PresentStars", self.Owner:EyePos() + (self.Owner:GetAimVector()), Angle( 0, 0, 0), (ent_present_explosive) )
	--ParticleEffectAttach( "presentstars", 1, (self), 1 )
	self.countsounds = 80

	timer.Simple(1, function()
		if not IsValid(self) then return end

		local entidex = self:EntIndex()

		timer.Create("presentboom" .. entidex, 0.2, 0, function()
			if not IsValid(self) then
				timer.Remove("presentboom" .. entidex)
				return
			end

			if self.countsounds == 160 then
				local explode = ents.Create("env_explosion")
				explode:SetPos(self:GetPos())
				explode:SetOwner(self:GetOwner())
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", "150")
				explode:Fire("Explode", 0, 0)

				timer.Remove("presentboom" .. self:EntIndex())
				self:Remove()
			else
				self.countsounds = self.countsounds + 10
			end
		end)
	end)
end

function ENT:Use()
end

function ENT:OnTakeDamage()
	timer.Create("presentexplode" .. self:EntIndex(), 0.08, 1, function()
		if not IsValid(self) then return end

		local explode = ents.Create("env_explosion")
		explode:SetPos(self:GetPos())
		explode:SetOwner(self:GetOwner())
		explode:Spawn()
		explode:SetKeyValue("iMagnitude", "170")
		explode:Fire("Explode", 0, 0)

		timer.Remove("presentexplode" .. self:EntIndex())
		self:Remove()
	end)
end