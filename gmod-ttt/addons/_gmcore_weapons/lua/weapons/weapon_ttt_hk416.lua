
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "HK 416"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_hk416"
end

SWEP.HoldType			= "ar2"
SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Delay       = 0.075
SWEP.Primary.Recoil      = 0.5
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 18
SWEP.Primary.Cone        = 0.01
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.AmmoEnt 			 = "item_ammo_smg1_ttt"
SWEP.AutoSpawnable 		 = true
SWEP.Primary.Sound       = Sound( "hk416weapon.UnsilSingle" )
SWEP.HeadshotMultiplier	= 1.5

SWEP.UseHands   = true
SWEP.ViewModel  = "models/weapons/hk416/v_hk416rif.mdl"
SWEP.WorldModel = "models/weapons/hk416/w_hk_416.mdl"

SWEP.IronSightsPos = Vector(-2.892, -2.132, 0.5)
SWEP.IronSightsAng = Vector(-0.033, 0.07, 0)
