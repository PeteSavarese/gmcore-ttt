
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "AK 47"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 52
	SWEP.Icon					= "vgui/ttt/icon_gl_ak47"
end

SWEP.HoldType			= "ar2"
SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Delay       = 0.10
SWEP.Primary.Recoil      = 2.4
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 25
SWEP.Primary.Cone        = 0.015
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.AmmoEnt 			 = "item_ammo_smg1_ttt"
SWEP.AutoSpawnable 		 = true
SWEP.Primary.Sound       = Sound( "Weapon_AK47.Single" )
SWEP.HeadshotMultiplier	= 2.7

SWEP.UseHands   = true
SWEP.ViewModel  = "models/weapons/cstrike/c_rif_ak47.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"

SWEP.IronSightsPos = Vector( -6.609, -10, 2.495 )
SWEP.IronSightsAng = Vector( 2.5, 0, 0 )
