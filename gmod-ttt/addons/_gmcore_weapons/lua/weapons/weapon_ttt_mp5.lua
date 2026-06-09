if CLIENT then
	SWEP.PrintName = "MP5"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 65
	SWEP.ViewModelFlip = false
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Icon = "vgui/ttt/icon_gl_mp5"
SWEP.Primary.Delay       = 0.13
SWEP.Primary.Recoil      = 0.5
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 17
SWEP.Primary.Cone        = 0.028
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound       = Sound( "Weapon_MP5Navy.Single" )

SWEP.IronSightsPos = Vector(-6.24, -2.757, 1.36)

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_mp5.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mp5.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
