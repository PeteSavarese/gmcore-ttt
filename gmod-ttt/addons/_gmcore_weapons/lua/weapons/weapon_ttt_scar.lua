if CLIENT then
	SWEP.PrintName = "SCAR-H"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 55
	SWEP.ViewModelFlip = false
	SWEP.Icon = "vgui/ttt/icon_gl_scar"
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Icon = "vgui/ttt/icon_gl_scar"
SWEP.Primary.Delay       = 0.093
SWEP.Primary.Recoil      = 0.32
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 20
SWEP.Primary.Cone        = 0.03
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 20
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Sound = Sound("Wep_fnscarh.single")
SWEP.IronSightsPos = Vector(-2.652, 0.187, -0.003)
SWEP.IronSightsAng = Vector(2.565, 0.034, 0)

SWEP.ViewModel  = "models/weapons/scar/v_fnscarh.mdl"
SWEP.WorldModel = "models/weapons/scar/w_fn_scar_h.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
