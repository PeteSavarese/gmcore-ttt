if CLIENT then
	SWEP.PrintName = "HK USC"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 65
	SWEP.ViewModelFlip = true
	SWEP.Icon = "vgui/ttt/icon_gl_usc"
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Primary.Delay       = 0.12
SWEP.Primary.Recoil      = .3
SWEP.Primary.Automatic   = false
SWEP.Primary.Damage      = 25
SWEP.Primary.Cone        = 0.02
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 25
SWEP.Primary.ClipMax     = 50
SWEP.Primary.DefaultClip = 25
SWEP.Primary.Sound       = Sound( "Weapon_hkusc.Single" )
SWEP.IronSightsPos = Vector(4.698, -2.566, 2.038)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.ViewModel  = "models/weapons/usc/v_hkoch_usc.mdl"
SWEP.WorldModel = "models/weapons/usc/w_hk_usc.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
