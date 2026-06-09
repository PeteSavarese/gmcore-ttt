AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Bump Mine"
ENT.Author = "SeNNoX"
ENT.Category = "Global Offensive"

ENT.Spawnable = true
ENT.AdminSpawnable = true

if CLIENT then
	function ENT:Initialize()
	end

	function ENT:Draw()
		self.Entity:DrawModel()
	end

	function ENT:DrawTranslucent()
		self:Draw()
	end
end

if SERVER then
	util.AddNetworkString("TTT_gl_BumpmineWarn")

	function ENT:Initialize()
		self:SetModel( "models/props_combine/combine_mine01.mdl" )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )

		local phys = self:GetPhysicsObject()
		phys:Wake()
		--phys:SetMaterial("gmod_bouncy")

		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

		self.TimesUsed = 1
		self:SetBodygroup(1,1)

		self:SetPos(self:GetPos()+Vector(0,0,5))
	end

	function ENT:PhysicsCollide( data, phys )
		local ent = data.HitEntity
		local phys = self:GetPhysicsObject()

		if ent:IsNPC() or ent:IsPlayer() then return false end
		if self.Stuck then return false end

		timer.Simple(0.01, function()
			if !self:IsValid() then return end

			self:EmitSound("csgo/bumpmine_land.wav")
			self:SetAngles(data.HitNormal:Angle()+Angle(-90,0,0))
			self:SetBodygroup(1,0)
			self.Stuck = true

			if ent:IsWorld() then
				phys:EnableMotion(false)
			else
				constraint.Weld(self, ent, 0, 0, 0, true, true)
			end
			self:SendWarn(self.Stuck)
		end)
		timer.Simple(2, function()
			if IsValid(self) then
				self:EmitSound("npc/roller/mine/rmine_blip3.wav")
				self.Armed = true
			end
		end)
	end

	function ENT:Think()
		if !self.Stuck or !self.Armed then return false end
		local entsph = ents.FindInSphere(self:GetPos(), 75)
		for k, v in pairs(entsph) do
			if v:IsPlayer() then
				v:SetVelocity(self:GetAngles():Up()*1000)
				v.was_pushed = {att=self:GetOwner(), t=CurTime(), wep="weapon_ttt_bumpmine"}
				v:EmitSound("csgo/bumpmine_launch.wav")
				self:Destroy()
			end
		end
	end

	function ENT:Destroy(quiet)
		self:EmitSound("csgo/bumpmine_detonate.wav")
		self:SetNoDraw(true)
		timer.Simple(0.001, function()
			if(self and self:IsValid()) then
				self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			end
		end)
		timer.Simple(0.002, function()
			if(self and self:IsValid()) then
				self:Remove()
			end
		end)
	end

	-- Inform traitors about us
	function ENT:SendWarn(armed)
		net.Start("TTT_gl_BumpmineWarn")
			net.WriteUInt(self:EntIndex(), 16)
			net.WriteBit(armed)
			if armed then
				net.WriteVector(self:GetPos())
			end
		net.Send(GetTraitorFilter(true))
	end

	function ENT:OnRemove()
		self:SendWarn(false)
	end
end
