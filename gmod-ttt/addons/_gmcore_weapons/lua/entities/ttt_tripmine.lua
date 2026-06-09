GAMEMODE.ActiveTripmines = {} -- Used for deathscenes

if SERVER then
	util.AddNetworkString("TTT_gl_TripwireWarn")
end

AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/weapons/w_slam.mdl")
ENT.Health = 100
ENT.BlastRadius = 350
ENT.BlastDamage = 10000
ENT.MaxHealth = 50
ENT.CanUseKey = true

ENT.CanHavePrints = true
ENT.Avoidable = true

local calibrateSound = Sound("weapons/slam/mine_mode.wav")
local zapsound = Sound("npc/assassin/ball_zap1.wav")

if CLIENT then
	-- this entity can be DNA-sampled so we need some display info
	ENT.Icon = "vgui/ttt/icon_gl_tripwire"
	ENT.PrintName = "Tripwire"
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetHealth(self.MaxHealth)
	self:SetBodygroup(0, 1)

	if SERVER then
		self:SetMaxHealth(self.MaxHealth)
		self:SetUseType(SIMPLE_USE)
	end

	self.fingerprints = {}

	hook.Run("TTTTripminePlaced", self:GetOwner(), self)

	timer.Simple(2, function()
		if IsValid(self) then
			self:Calibrate()
		end
	end)


	if !table.HasValue(GAMEMODE.ActiveTripmines, self) then
		table.insert(GAMEMODE.ActiveTripmines, self)
	end
end

function ENT:Calibrate()
	local pos = self:GetPos()
	local tr = util.QuickTrace(pos, self:GetUp() * 10000, self)
	self.LaserLength = tr.Fraction
	self.LaserEndPos = tr.HitPos
	self.Calibrated  = true

	self:EmitSound( calibrateSound )

	if SERVER then
		self:SendWarn(true)
	end
end

function ENT:CreateBeam( startPos, endPos )
	if CLIENT then return end
	local beamEnd = ents.Create("info_target")
	beamEnd:SetKeyValue("targetname", "NULL" .. beamEnd:EntIndex() )
	beamEnd:SetPos(startPos + self:GetUp() * 2)
	beamEnd:Spawn()

	local beam = ents.Create("env_laser")
	beam:SetPos(endPos)
	beam:SetKeyValue("renderamt", "75")
	beam:SetKeyValue("rendercolor", "255 0 0")
	beam:SetKeyValue("texture", "sprites/laserbeam.spr")
	beam:SetKeyValue("TextureScroll", "35")
	beam:SetKeyValue("parentname", "")
	beam:SetKeyValue("damage", "0")
	beam:SetKeyValue("spawnflags", "1")
	beam:SetKeyValue("width", "0.5")
	beam:SetKeyValue("dissolvetype", "None")
	beam:SetKeyValue("EndSprite", "")
	beam:SetKeyValue("LaserTarget", "NULL" .. beamEnd:EntIndex())
	beam:SetKeyValue("TouchType", "0")
	beam:Spawn()

	self.beam = beam
	self.beamEnd = beamEnd
end

if SERVER then
	-- Inform traitors about us
	function ENT:SendWarn(armed)
		net.Start("TTT_gl_TripwireWarn")
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

function ENT:Think()
	if self.Calibrated then
		local tr = util.QuickTrace( self:GetPos(), self:GetUp() * 10000, function(ent)
			-- TODO from Pierogi: what is this?
			local ignoreTable = {self}

			if IsValid(ent) and ent:IsPlayer() then
				if ent:IsGhost() then
					table.insert(ignoreTable, ent)

				elseif ent:PS_HasItemEquipped("upgrade_tripwire_safety") then
					if (self:GetOwner() == ent) or (ent:IsTraitor() and ent:PS_GetUpgradeLevel("upgrade_tripwire_safety") == 2) then
						table.insert(ignoreTable, ent)
					end
				end
			end



			if table.HasValue(ignoreTable, ent) then return false end

			return true
		end)

		if tr.Fraction < self.LaserLength then
			self:Explode()
		end
	end
end

function ENT:Explode()
	if SERVER then
		local pos = self:GetPos()
		local radius = self.BlastRadius
		local damage = self.BlastDamage
		self.exploded = true

		util.BlastDamage( self, self:GetOwner(), pos, radius, damage )
		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		effect:SetScale(radius)
		effect:SetRadius(radius)
		effect:SetMagnitude(damage)
		util.Effect("Explosion", effect, true, true)

		table.RemoveByValue(GAMEMODE.ActiveTripmines, self)

		self:Remove()
	end
end

function ENT:Explode2()
	local effect = EffectData()
	effect:SetOrigin(self:GetPos())
	util.Effect("cball_explode", effect)
	self:EmitSound(zapsound)

	table.RemoveByValue(GAMEMODE.ActiveTripmines, self)

	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth(self:Health() - dmginfo:GetDamage())

	if !self.exploded and self:Health() <= 0 then
		self:Explode2()
	end
end

--[[
function ENT:UseOverride( pl )
	local wep = pl:Give( "weapon_ttt_tripmine" )
	if IsValid( wep ) then
		wep.fingerprints = wep.fingerprints or {}
		table.Add( wep.fingerprints, self.fingerprints )
	end
	self:Remove()
end
]]

if CLIENT then
	local Laser = Material("cable/redlaser")

	function ENT:Draw()
		self:DrawModel()
		local Vector1 = self:LocalToWorld(Vector(-2.3, 1.4, 0))

		if self.Calibrated then
			local pos = self:GetPos()
			render.SetMaterial(Laser)
			render.DrawBeam(Vector1, self.LaserEndPos, 1, 0, 0, Color(255, 255, 255, 5))
			self:SetRenderBoundsWS(pos, self.LaserEndPos)
		end
	end
end
