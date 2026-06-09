AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType              = "ar2"

if CLIENT then
	SWEP.PrintName          = "Winchester 1873"
	SWEP.Slot               = 2

	SWEP.ViewModelFlip      = true
	SWEP.ViewModelFOV       = 70

	SWEP.Icon               = "vgui/ttt/icon_gl_winchester_1873"
	SWEP.IconLetter         = "B"
end

SWEP.Base                  = "weapon_tttbase"

SWEP.Kind                  = WEAPON_HEAVY

SWEP.Primary.Ammo          = "357"
SWEP.Primary.Damage        = 50
SWEP.Primary.Cone          = 0.01
SWEP.Primary.Delay         = 0.9
SWEP.Primary.ClipSize      = 8
SWEP.Primary.ClipMax       = 24
SWEP.Primary.DefaultClip   = 8
SWEP.Primary.Automatic     = true
SWEP.Primary.NumShots      = 1
SWEP.Primary.Sound         = Sound( "Weapon_73.Single" )
SWEP.Primary.Recoil        = 2

SWEP.AutoSpawnable         = true
SWEP.Spawnable             = true
SWEP.AmmoEnt               = "item_ammo_357_ttt"

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/winchester_1873/v_winchester1873.mdl"
SWEP.WorldModel            = "models/weapons/winchester_1873/w_winchester_1873.mdl"

SWEP.IronSightsPos = Vector(4.356, 0, 2.591)
SWEP.IronSightsAng = Vector(0, 0, 0)

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Reloading")
	self:NetworkVar("Float", 0, "ReloadTimer")

	return BaseClass.SetupDataTables(self)
end

function SWEP:Reload()

	--if self:GetNWBool( "reloading", false ) then return end
	if self:GetReloading() then return end

	if self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 then

			if self:StartReload() then
				return
			end
	end

end

function SWEP:StartReload()
	--if self:GetNWBool( "reloading", false ) then
	if self:GetReloading() then
			return false
	end

	self:SetIronsights( false )

	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	local ply = self:GetOwner()

	if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then
			return false
	end

	local wep = self

	if wep:Clip1() >= self.Primary.ClipSize then
			return false
	end

	wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

	self:SetReloadTimer(CurTime() + wep:SequenceDuration())

	--wep:SetNWBool("reloading", true)
	self:SetReloading(true)

	return true
end

function SWEP:PerformReload()
	local ply = self:GetOwner()

	-- prevent normal shooting in between reloads
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

	if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

	if self:Clip1() >= self.Primary.ClipSize then return end

	self:GetOwner():RemoveAmmo( 1, self.Primary.Ammo, false )
	self:SetClip1( self:Clip1() + 1 )

	self:SendWeaponAnim(ACT_VM_RELOAD)

	self:SetReloadTimer(CurTime() + self:SequenceDuration())
end

function SWEP:FinishReload()
	self:SetReloading(false)
	self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

	self:SetReloadTimer(CurTime() + self:SequenceDuration())
end

function SWEP:CanPrimaryAttack()
	if self:Clip1() <= 0 then
			self:EmitSound( "Weapon_Shotgun.Empty" )
			self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
			return false
	end
	return true
end

function SWEP:Think()
	BaseClass.Think(self)
	if self:GetReloading() then
			if self:GetOwner():KeyDown(IN_ATTACK) then
				self:FinishReload()
				return
			end

			if self:GetReloadTimer() <= CurTime() then

				if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then
						self:FinishReload()
				elseif self:Clip1() < self.Primary.ClipSize then
						self:PerformReload()
				else
						self:FinishReload()
				end
				return
			end
	end
end

function SWEP:Deploy()
	self:SetReloading(false)
	self:SetReloadTimer(0)
	return BaseClass.Deploy(self)
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	return 3
end

function SWEP:SecondaryAttack()
	if self.NoSights or (not self.IronSightsPos) or self:GetReloading() then return end
	--if self:GetNextSecondaryFire() > CurTime() then return end

	self:SetIronsights(not self:GetIronsights())

	self:SetNextSecondaryFire(CurTime() + 0.3)
end
