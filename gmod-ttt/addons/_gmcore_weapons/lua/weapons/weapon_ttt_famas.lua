if CLIENT then
	SWEP.PrintName = "Famas"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 65
	SWEP.ViewModelFlip = false
	SWEP.Icon					= "vgui/ttt/icon_gl_famas"
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Primary.BurstShots = 3 -- Number of bullets shot each burst.
SWEP.Primary.BurstInbetweenDelay = 0.06 -- The delay that's inbetween each shot of a burst.
SWEP.Primary.BurstDelay = 0.35 -- The delay between each burst.

SWEP.Icon = "vgui/ttt/icon_gl_famas"
SWEP.Primary.Delay       = 0.105
SWEP.Primary.Recoil      = .3
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 20
SWEP.Primary.Cone        = 0.0258
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound       = Sound("Weapon_FAMTC.Single")

SWEP.IronSightsPos = Vector(-3.342, 0, 0.247)
SWEP.IronSightsAng = Vector(0, -0.438, 0)

SWEP.ViewModel  = "models/weapons/famas/v_tct_famas.mdl"
SWEP.WorldModel = "models/weapons/famas/w_tct_famas.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"


local function ClearNetVars(self)
	self:SetIronsights(false)
	self:SetBurstFiring(false)
	self:SetReloadEndTime(0.0)
	self:SetBurstShotsFired(0)
	self:SetBurstShotEndTime(0.0)
end

function SWEP:OnDrop()
	ClearNetVars(self)
end


function SWEP:Deploy()
	self.BaseClass.Deploy(self)
	ClearNetVars(self)

	return true
end


function SWEP:SetupDataTables()
	-- Set to "0.0" if not reloading. Set to "Current time + (reload animation length)" when reloading.
	self:NetworkVar("Float", 0, "ReloadEndTime")
	-- Set to "true" if the "SWEP:Think()" function needs to do a burst fire.
	self:NetworkVar("Bool", 0, "BurstFiring")
	-- The number of shots already fired during the current burst. "0" no shots have been shot yet.
	self:NetworkVar("Int", 0, "BurstShotsFired")
	-- The time that the current shot being fired in the burst will be finished.
	self:NetworkVar("Float", 1, "BurstShotEndTime")

	self.BaseClass.SetupDataTables(self)
end


function SWEP:GetRandomViewpunchAngle()
	local recoil = self.Primary.Recoil
	local pitch = math.Rand(-0.2, -0.1)
	local yaw = math.Rand(-0.1, 0.1)
	local roll = 0 --math.Rand(-0.3,  0.3) -- Roll is fun.

	return Angle(pitch * recoil, yaw * recoil, roll)
end


---Burst fire function start
function SWEP:Think()
	self.BaseClass.Think(self)

	if self:GetReloadEndTime() ~= 0.0 then
		if self:GetReloadEndTime() <= CurTime() then
			self:SetReloadEndTime(0.0)
		else
			return
		end
	end

	if !self:GetBurstFiring() then return end

	-- If not shot has been fired (BurstShotEndTime = 0.0) or our current
	-- shot's end-time has been passed.
	if self:GetBurstShotEndTime() <= CurTime() then
		local shotsFired = self:GetBurstShotsFired()

		if shotsFired >= self.Primary.BurstShots or self:Clip1() == 0 then
			-- Since we've fired all of our shots, we clean up.
			self:SetBurstShotsFired(0)
			self:SetBurstShotEndTime(0.0)
			self:SetBurstFiring(false)
			-- Delay until the next burst.
			self:SetNextSecondaryFire(CurTime() + self.Primary.BurstDelay)
			self:SetNextPrimaryFire(CurTime() + self.Primary.BurstDelay)
		elseif self:CanPrimaryAttack() then
			-- We still have shots to fire.
			self:FireShot()
			self:SetBurstShotsFired(shotsFired + 1)
			self:SetBurstShotEndTime(CurTime() + self.Primary.BurstInbetweenDelay)
		end
	end
end

function SWEP:PrimaryAttack(worldsnd)
	-- Let the "SWEP:Think()" function deal with the burst firing.
	if self:GetBurstFiring() then return end

	if self:GetIronsights() then
		-- *click*
		if !self:CanPrimaryAttack() then
			self:SetNextSecondaryFire(CurTime() + self.Primary.BurstDelay)
			self:SetNextPrimaryFire(CurTime() + self.Primary.BurstDelay)

			return
		end

		self:SetBurstFiring(true)
	else
		self:FireShot()
		self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	end
end


function SWEP:FireShot(worldsnd)
	if !self:CanPrimaryAttack() then return end

	if !worldsnd then
		self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
	elseif SERVER then
		sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
	end

	self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
	self:TakePrimaryAmmo(1)

	local owner = self:GetOwner()
	if !IsValid(owner) or owner:IsNPC() or (!owner.ViewPunch) then return end

	owner:ViewPunch(self:GetRandomViewpunchAngle())
end
