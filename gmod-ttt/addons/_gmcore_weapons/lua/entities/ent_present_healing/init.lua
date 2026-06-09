AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
	Changed heal sound. Credit - https://freesound.org/people/mondofred/sounds/416386/
]]

function ENT:Initialize()
	self:SetModel("models/present/launcher_present.mdl")
	self:SetSubMaterial(0, "present/present_ribbon")
	self:SetSubMaterial(1, "present/present_green")
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

		timer.Create("presentheal" .. entidex, 0.2, 0, function()
			if not IsValid(self) then
				timer.Remove("presentheal" .. entidex)

				return
			end

			if self.countsounds == 160 then
				ParticleEffect("present_heal_mist", self:GetPos(), Angle(0, 0, 0))
				self:EmitSound("heal.mp3", 80)

				for k, ply in pairs(player.GetAll()) do
					local plypos = ply:GetPos()
					local dist = plypos:Distance(self:GetPos())
					local cutoffDist = 375
					local reduction = (dist - 10) / cutoffDist
					local healAmount = ply:Health() + (0.80 * ply:GetMaxHealth()) * (1 - reduction)
					local healAmount = math.Clamp(healAmount, ply:Health(), ply:GetMaxHealth())

					ply:SetHealth(healAmount)
				end

				timer.Remove("presentheal" .. self:EntIndex())
				self:Remove()
			else
				self.countsounds = self.countsounds + 10
			end
		end)
	end)
end

function ENT:Use() end

function ENT:OnTakeDamage()
	timer.Create("presenthealed" .. self:EntIndex(), 0.08, 1, function()
		if not IsValid(self) then return end

		ParticleEffect("present_heal_mist", self:GetPos(), Angle(0, 0, 0))
		self:EmitSound("heal.mp3", 70)

		local plypos = self:GetOwner():GetPos()
		local ply = self:GetOwner()
		local dist = plypos:Distance(self:GetPos())
		local cutoffDist = 375
		local reduction = (dist - 10) / cutoffDist
		local healAmount = ply:Health() + (0.75 * ply:GetMaxHealth()) * (1 - reduction)
		local healAmount = math.Clamp(healAmount, ply:Health(), ply:GetMaxHealth())

		ply:SetHealth(healAmount)

		timer.Remove("presenthealed" .. self:EntIndex())
		self:Remove()
	end)
end