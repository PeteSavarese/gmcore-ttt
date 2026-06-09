if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TearGas_Toggle")
end

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Projectile = true
ENT.Model = Model("models/weapons/w_eq_flashbang_thrown.mdl")
AccessorFunc(ENT, "radius", "Radius", FORCE_NUMBER)
function ENT:Initialize()
	self:SetRadius(TearGas_Config.GasRadius)
	self:SetColor(Color(0, 150, 0))
	return self.BaseClass.Initialize(self)
end

if CLIENT then
	local Particles = {Model("particle/particle_smokegrenade"), Model("particle/particle_noisesphere")}
	function ENT:CreateGas(center)
		if GetRoundState() == ROUND_POST then return end
		local em = ParticleEmitter(center)
		local r = self:GetRadius()
		local delay = 0.05
		for i = 1, TearGas_Config.GasThickness do
			local prpos = VectorRand() * r
			prpos.z = prpos.z + 32
			prpos.z = math.min(prpos.z, 45)
			timer.Simple(i * delay, function()
				local p = em:Add(table.Random(Particles), center + prpos)
				if p then
					--if math.random( 1, 4 ) == 1 then
					p:SetColor(235, 235, 235)
					--else
					--	p:SetColor( 0, math.random( 50, 150 ), 0 )
					--end
					p:SetStartAlpha(25)
					p:SetEndAlpha(5)
					p:SetVelocity(VectorRand() * math.Rand(800, 1000))
					p:SetLifeTime(0)
					p:SetDieTime(TearGas_Config.GasLength)
					p:SetStartSize(math.random(180, 200))
					p:SetEndSize(math.random(1, 40))
					p:SetRoll(math.random(-180, 180))
					p:SetRollDelta(math.Rand(-0.1, 0.1))
					p:SetAirResistance(600)
					p:SetCollide(true)
					p:SetBounce(0.2)
					p:SetLighting(false)
				end
			end)
		end

		timer.Simple(delay * r, function() em:Finish() end)
	end
end

if SERVER then
	function ENT:TearGas_Check(pos, tr, radius, num)
		if GetRoundState() == ROUND_POST then return end
		if tr ~= nil then
			if tr.Fraction ~= 1.0 then pos = tr.HitPos + tr.HitNormal * 0.6 end
			radius = radius * 2
		end

		for _, ent in pairs(ents.FindInSphere(pos, radius)) do
			if IsValid(ent) and ent:IsPlayer() and ent:IsActive() then
				if ent.TearGas_Cough == nil or (CurTime() >= ent.TearGas_Cough) then
					ent:EmitSound("hostage/hpain/hpain" .. math.random(1, 6) .. ".wav", 90, 90)
					ent.TearGas_Cough = CurTime() + math.Rand(1, 3)
				end

				local blurVision = true
				if ent:PS_HasItemEquipped("upgrade_tear_gas_safety") then
					if self.Owner == ent then
						blurVision = false
					elseif ent:IsTraitor() and ent:PS_GetUpgradeLevel("upgrade_tear_gas_safety") == 2 then
						blurVision = false
					end
				end

				if blurVision then
					net.Start("TearGas_Toggle")
					net.WriteBit(true)
					net.Send(ent)
					timer.Create("Ungas_" .. ent:UniqueID(), TearGas_Config.DisorientationLength, 1, function()
						net.Start("TearGas_Toggle")
						net.WriteBit(false)
						net.Send(ent)
					end)
				end

				local dmginfo = DamageInfo()
				dmginfo:SetDamage(TearGas_Config.DamagePerSecond)
				dmginfo:SetDamageType(DMG_ACID)
				dmginfo:SetAttacker(self.Owner)
				dmginfo:SetInflictor(self)
				ent:TakeDamageInfo(dmginfo)
			end
		end

		if num <= math.max(TearGas_Config.GasLength - 2, 1) then
			timer.Simple(1, function()
				if not IsValid(self) then return end

				self:TearGas_Check(pos, nil, radius, num + 1)
			end)
		else
			self:Remove()
		end
	end
end

function ENT:Explode(tr)
	self:SetDetonateExact(0)

	if SERVER then
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)
		self:GetPhysicsObject():EnableMotion(false)
		self:EmitSound("weapons/smokegrenade/sg_explode.wav", 110, 90)

		local pos = self:GetPos()
		local radius = self:GetRadius()
		timer.Simple(0.5, function() self:TearGas_Check(pos, tr, radius, 1) end)
	else
		local pos = self:GetPos()
		if tr.Fraction ~= 1.0 then pos = tr.HitPos + tr.HitNormal * 0.6 end
		self:CreateGas(pos)
	end
end

hook.Add("Initialize", "TearGas_HackyTempAddToDetailedEvents", function() if wepnameswitch ~= nil then wepnameswitch["ttt_teargas_proj"] = "tear gas" end end)