if CLIENT then
	SWEP.PrintName = "P90"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 65
	SWEP.ViewModelFlip = true
	SWEP.Icon = "vgui/ttt/icon_gl_p90"
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Primary.Delay       = 0.07
SWEP.Primary.Recoil      = 0.5
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 14
SWEP.Primary.Cone        = 0.028
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 50
SWEP.Primary.ClipMax     = 100
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Sound       = Sound("P90_weapon.single")

SWEP.IronSightsPos = Vector(2.707, -2.46, 2.219)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.ViewModel  = "models/weapons/p90/v_p90_smg.mdl"
SWEP.WorldModel = "models/weapons/p90/w_fn_p90.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.HeadshotMultiplier	= 1.5
