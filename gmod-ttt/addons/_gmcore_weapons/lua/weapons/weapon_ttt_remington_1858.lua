AddCSLuaFile()

SWEP.HoldType              = "pistol"

if CLIENT then
	SWEP.PrintName          = "Remington 1858"
	SWEP.Slot               = 1

	SWEP.ViewModelFlip      = true
	SWEP.ViewModelFOV       = 65

	SWEP.Icon               = "vgui/ttt/icon_deagle"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Kind                  = WEAPON_PISTOL
SWEP.WeaponID              = AMMO_DEAGLE

SWEP.Primary.Ammo          = "AlyxGun" -- hijack an ammo type we don't use otherwise
SWEP.Primary.Recoil        = 4
SWEP.Primary.Damage        = 50
SWEP.Primary.Delay         = 0.33
SWEP.Primary.ClipSize      = 6
SWEP.Primary.ClipMax       = 36
SWEP.Primary.DefaultClip   = 6
SWEP.Primary.Automatic     = false
SWEP.Primary.Sound         = Sound( "Remington.Single" )

SWEP.AutoSpawnable         = false
SWEP.AmmoEnt               = "item_ammo_revolver_ttt"

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/remington_1858/v_pist_re1858.mdl"
SWEP.WorldModel            = "models/weapons/remington_1858/w_remington_1858.mdl"

SWEP.IronSightsPos = Vector(5.44, 0, 1.72)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.Primary.BurstShots = 6 -- Number of bullets shot each burst.
SWEP.Primary.BurstInbetweenDelay = 0.125 -- The delay that's inbetween each shot of a burst.
SWEP.Primary.BurstDelay = 0.35 -- The delay between each burst.




local function ClearNetVars(self)
	self:SetIronsights(false)
	self:SetBurstFiring(false)
	self:SetReloadEndTime(0.0)
	self:SetBurstShotsFired(0)
	self:SetBurstShotEndTime(0.0)
	self:SetLastShotFiredTime(0.0)
end


function SWEP:OnDrop()
	ClearNetVars(self)
end


function SWEP:Deploy()
	ClearNetVars(self)
	self.BaseClass.Deploy(self)
	return true
end


function SWEP:SetupDataTables()
	-- Set to "0.0" if not reloading. Set to "Current time + (reload animation length)" when reloading.
	self:NetworkVar("Float", 0, "ReloadEndTime")
	-- Set to "true" if the "SWEP:Think()" function needs to do a burst fire.
	self:NetworkVar("Bool",  0, "BurstFiring")
	-- The number of shots already fired during the current burst. "0" no shots have been shot yet.
	self:NetworkVar("Int",   0, "BurstShotsFired")
	-- The time that the current shot being fired in the burst will be finished.
	self:NetworkVar("Float", 1, "BurstShotEndTime")

				self:NetworkVar("Float", 2, "LastShotFiredTime")

	self.BaseClass.SetupDataTables(self)
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

	self:FireShot()
	self:SetLastShotFiredTime(CurTime())
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end





function SWEP:SecondaryAttack()
	self:SetBurstFiring(true)
end


function SWEP:GetPrimaryCone()
	if self:GetBurstFiring() then return 0.15 else return 0.05 end
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	if self:GetBurstFiring() then return 1 else return 4 end
end


function SWEP:FireShot(worldsnd)
	if not self:CanPrimaryAttack() then return end

	if not worldsnd then
		self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
	elseif SERVER then
		sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
	end

	self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
	self:TakePrimaryAmmo(1)
end
