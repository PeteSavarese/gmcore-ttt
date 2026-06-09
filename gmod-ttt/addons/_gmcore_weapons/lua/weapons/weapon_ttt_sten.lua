AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "STEN"
	SWEP.Slot      = 2
	SWEP.Icon = "vgui/ttt/icon_gl_sten"

	SWEP.ViewModelFOV  = 60
	SWEP.ViewModelFlip = true
end

SWEP.Base				= "weapon_tttbase"
DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType			= "ar2"
SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Delay       = 0.10
SWEP.Primary.Recoil      = 0.75
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 20
SWEP.Primary.Cone        = 0.038
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 32
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 32
SWEP.AmmoEnt 			 = "item_ammo_smg1_ttt"
SWEP.AutoSpawnable 		 = true
SWEP.Primary.Sound       = Sound("Weaponsten.Single")

SWEP.UseHands        = true
SWEP.ViewModel  = "models/weapons/sten/v_smgsten.mdl"
SWEP.WorldModel = "models/weapons/sten/w_sten.mdl"

SWEP.IronSightsPos = Vector(4.367, -1.476, 3.119)
SWEP.IronSightsAng = Vector(-0.213, -0.426, 0)