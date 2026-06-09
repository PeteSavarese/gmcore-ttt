AddCSLuaFile()
local BounceSound = Sound("garrysmod/balloon_pop_cute.wav")
DEFINE_BASECLASS("base_anim")
ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "BallColor")
end

local BallSize = 32

function ENT:Initialize()
	if SERVER then
		local size = BallSize / 2
		self:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
		self:PhysicsInitSphere(size, "metal_bouncy")
		local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:Wake()
		end

		self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))
	else
		self.LightColor = Vector(0, 0, 0)
	end
end

if CLIENT then
	local matBall = Material("sprites/sent_ball")

	function ENT:Draw()
		local pos = self:GetPos()

		render.SetMaterial(matBall)
		local lcolor = render.ComputeLighting(self:GetPos(), Vector(0, 0, 1))
		local c = self:GetBallColor()
		lcolor.x = c.r * (math.Clamp(lcolor.x, 0, 1) + 0.5) * 255
		lcolor.y = c.g * (math.Clamp(lcolor.y, 0, 1) + 0.5) * 255
		lcolor.z = c.b * (math.Clamp(lcolor.z, 0, 1) + 0.5) * 255
		render.DrawSprite(pos, BallSize, BallSize, Color(lcolor.x, lcolor.y, lcolor.z, 255))
	end
end

if SERVER then
	local function warnPlyTeamDamage(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		ply:SendLua([[gmcore.chatprinticon("exclamation", "Its a fun round. You can't damage your team mates!")]])
	end

	function ENT:Think()
		if self.ShouldDissolve or self:GetVelocity():Length() < 400 then
			self:Remove()
		end
	end

	function ENT:PhysicsCollide(data, physobj)
		local hitent = data.HitEntity
		local owner = self:GetOwner()
		self.BallCollisions = (self.BallCollisions or 0) + 1

		if self.BallCollisions > 1 then
			self.ShouldDissolve = true
		end

		if (data.Speed > 800 and hitent:IsWorld() and data.HitPos:Distance(self:GetOwner():GetPos()) < 200) then
			local pos = self:LocalToWorld(self:OBBCenter())
			local tpos = owner:LocalToWorld(owner:OBBCenter())
			local dir = (tpos - pos):GetNormal()

			-- always need an upwards push to prevent the ground's friction from
			-- stopping nearly all movement
			dir.z = math.abs(dir.z) + 1
			local push_force = 220
			local push = dir * push_force
			-- try to prevent excessive upwards force
			local vel = owner:GetVelocity() + push
			vel.z = math.min(vel.z, push_force)
			owner:SetVelocity(vel)
		end

		if data.Speed > 400 then
			if hitent:GetClass() == "func_breakable_surf" or hitent:GetClass() == "func_breakable" or hitent:GetClass() == "prop_physics" and hitent:Health() > 0 then
				hitent:Input("RemoveHealth", owner, self, 20)
			elseif hitent:IsPlayer() then
				local pos = self:LocalToWorld(self:OBBCenter())
				local effectdata = EffectData()
				effectdata:SetStart(pos)
				effectdata:SetOrigin(pos)
				effectdata:SetScale(1)
				util.Effect("GlassImpact", effectdata)
				hitent:EmitSound("physics/flesh/flesh_squishy_impact_hard2.wav")

				-- A long winded way of preventing team damage
				if hitent:IsPlayer() and owner:IsPlayer() and IsValid(hitent) and IsValid(owner) then
					if hitent:GetRole() == ROLE_INNOCENT and owner:GetRole() == ROLE_INNOCENT then
						warnPlyTeamDamage(owner)

						return false
					elseif hitent:GetRole() == ROLE_TRAITOR and owner:GetRole() == ROLE_TRAITOR then
						warnPlyTeamDamage(owner)

						return false
					elseif hitent:GetRole() == ROLE_DETECTIVE and owner:GetRole() == ROLE_DETECTIVE then
						warnPlyTeamDamage(owner)

						return false
					elseif hitent:GetRole() == ROLE_INNOCENT and owner:GetRole() == ROLE_DETECTIVE then
						warnPlyTeamDamage(owner)
					else
						local info = DamageInfo()
						info:SetDamagePosition(self:GetPos())
						info:SetMaxDamage(30)
						info:SetDamage(30)
						info:SetAttacker(self:GetOwner())
						info:SetInflictor(self)
						info:SetDamageType(DMG_GENERIC)
						hitent:TakeDamageInfo(info)
					end
				end

				local tpos = hitent:LocalToWorld(hitent:OBBCenter())
				local dir = (tpos - pos):GetNormal()
				local phys = hitent:GetPhysicsObject()
				-- always need an upwards push to prevent the ground's friction from
				-- stopping nearly all movement
				dir.z = math.abs(dir.z) + 1
				local push_force = 10
				local push = dir * push_force
				-- try to prevent excessive upwards force
				local vel = hitent:GetVelocity() + push
				vel.z = math.min(vel.z, push_force)
				hitent:SetVelocity(vel)
				self:Remove()

				return
			end
		else
			return
		end

		-- Play sound on bounce
		if data.Speed > 60 and data.DeltaTime > 0.2 then
			sound.Play(BounceSound, self:GetPos(), 75, math.random(90, 120), math.Clamp(data.Speed / 150, 0, 1))
		end

		-- Bounce like CRAAZY
		local LastSpeed = math.max(data.OurOldVelocity:Length(), data.Speed)
		local NewVelocity = physobj:GetVelocity()
		NewVelocity:Normalize()
		LastSpeed = math.max(NewVelocity:Length(), LastSpeed)
		local TargetVelocity = NewVelocity * LastSpeed * 0.7
		physobj:SetVelocity(TargetVelocity)
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)
end
