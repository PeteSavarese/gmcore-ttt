AddCSLuaFile()

SWEP.HoldType = "ar2"

if CLIENT then
	SWEP.PrintName = "Gauss Rifle"
	SWEP.Slot = 6
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = [[A high-powered electromagnetic rifle. Fires a single
explosive round that detonates on impact.
Make your shot count.]]
	}

	SWEP.Icon = "vgui/ttt/icon_gl_gauss_rifle"
	SWEP.UseHands = true
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 64
end

SWEP.Base = "weapon_tttbase"

DEFINE_BASECLASS "weapon_tttbase"

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.Primary.Ammo = "thumper"
SWEP.Primary.Delay = 2
SWEP.Primary.Recoil = 6
SWEP.Primary.Cone = 0.0025
SWEP.Primary.Damage = 75
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Sound = Sound("Gauss_Rifle.Single")
SWEP.Primary.SoundLevel = 120
SWEP.Secondary.Delay = 0.5
SWEP.Secondary.Sound = Sound("Default.Zoom")
SWEP.Primary.SoundLevel = 120
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true

SWEP.ViewModel = "models/weapons/zaratusa/gauss_rifle/v_gauss_rifle.mdl"
SWEP.WorldModel = "models/weapons/zaratusa/gauss_rifle/w_gauss_rifle.mdl"

SWEP.IronSightsPos = Vector(-1.55, -22, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.IsSniper = true
SWEP.SniperSettings = {
	UseDefaultTTTScope = true
}

function SWEP:Initialize()
	if CLIENT and self:Clip1() == -1 then
		self:SetClip1(self.Primary.DefaultClip)
	elseif SERVER then
		self.fingerprints = {}
		self:SetIronsights(false)

		-- aditional magazine, seems to be bugged, when using DefaultClip
		timer.Simple(0.1, function()
			if (IsValid(self:GetOwner())) then
				self:GetOwner():GiveAmmo(1, "thumper", true)
			end
		end)
	end

	self:SetDeploySpeed(self.DeploySpeed)

	if self.SetHoldType then
		self:SetHoldType(self.HoldType)
	end

	PrecacheParticleSystem("smoke_trail")
end

function SWEP:PrimaryAttack(worldsnd)
	if not self:CanPrimaryAttack() or self:GetNextPrimaryFire() > CurTime() then return end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	local owner = self:GetOwner() --[[@as Player]]
	if not IsValid(owner) or not owner:IsPlayer() then return end
	owner:GetViewModel():StopParticles()

	if not worldsnd then
		self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
	elseif SERVER then
		sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
	end

	self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, tostring(self:GetPrimaryCone()))
	self:TakePrimaryAmmo(1)

	local tr = owner:GetEyeTrace()

	-- explosion effect
	local effectdata = EffectData()
	effectdata:SetOrigin(tr.HitPos)
	effectdata:SetNormal(tr.HitNormal)
	effectdata:SetEntity(tr.Entity)
	effectdata:SetAttachment(tr.PhysicsBone)
	util.Effect("Explosion", effectdata)

	-- electrical tracer
	local effectdata = EffectData()
	effectdata:SetOrigin(tr.HitPos)
	effectdata:SetStart(owner:GetShootPos())
	effectdata:SetAttachment(1)
	effectdata:SetEntity(self)
	util.Effect("ToolTracer", effectdata)

	-- explosion damage
	if SERVER then
		util.BlastDamage(self, owner, tr.HitPos, 250, 40)
	end

	self:UpdateNextIdle()

	if IsValid(owner) and not owner:IsNPC() and owner.ViewPunch then
		owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Primary.Recoil, math.Rand(-0.1, 0.1) * self.Primary.Recoil, 0))
	end

	ParticleEffectAttach("smoke_trail", PATTACH_POINT_FOLLOW, owner:GetViewModel(), 1)
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:ResetIronSights()
	self:UpdateNextIdle()

	return true
end

function SWEP:UpdateNextIdle()
	self:SetNWFloat("NextIdle", CurTime() + self:GetOwner():GetViewModel():SequenceDuration())
end

-- add some zoom to the scope for this gun
function SWEP:SecondaryAttack()
	if not self.IronSightsPos or self:GetNextPrimaryFire() > CurTime() then return end

	-- set the delay for left and right click
	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

	local bIronsights = not self:GetIronsights()
	self:SetIronsights(bIronsights)

	if SERVER then
		self:SetZoom(bIronsights)
	else
		self:EmitSound(self.Secondary.Sound)
	end
end

function SWEP:SetZoom(state)
	if not SERVER or not IsValid(self:GetOwner()) or not self:GetOwner():IsPlayer() then return end

	if state then
		self:GetOwner():SetFOV(20, 0.3)
	else
		self:GetOwner():SetFOV(0, 0.2)
	end
end

function SWEP:ResetIronSights()
	self:SetIronsights(false)
	self:SetZoom(false)
end

function SWEP:PreDrop()
	self:ResetIronSights()

	return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
	if self:Clip1() >= self.Primary.ClipSize or self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end

	self:DefaultReload(ACT_VM_RELOAD)
	self:ResetIronSights()
end

function SWEP:Holster()
	if IsValid(self:GetOwner()) then
		local vm = self:GetOwner():GetViewModel()

		if IsValid(vm) then
			vm:StopParticles()
		end
	end

	self:ResetIronSights()

	return true
end
