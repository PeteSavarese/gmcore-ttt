
AddCSLuaFile()

SWEP.Base					= "weapon_tttbase"

SWEP.UseHands					= true

if CLIENT then
	SWEP.PrintName					= "M14"
	SWEP.Slot					= 2
	SWEP.ViewModelFlip					= false
	SWEP.ViewModelFOV					= 70
	SWEP.Icon					= "vgui/ttt/icon_gl_m14"
end

SWEP.HoldType			= "ar2"
SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Delay       = 0.25
SWEP.Primary.Recoil      = 0.6
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 32
SWEP.Primary.Cone        = 0.02
SWEP.Primary.Ammo        = "357"
SWEP.Primary.ClipSize      = 20
SWEP.Primary.ClipMax       = 40
SWEP.Primary.DefaultClip   = 20
SWEP.AmmoEnt 			 = "item_ammo_357_ttt"
SWEP.AutoSpawnable 		 = true
SWEP.Primary.Sound       = Sound( "Weapon_M14SP.Single" )

SWEP.UseHands   = true
SWEP.ViewModel  = "models/weapons/m14/v_snip_m14sp.mdl"
SWEP.WorldModel = "models/weapons/m14/w_snip_m14sp.mdl"

SWEP.IronSightsPos = Vector (-2.7031, -1.0539, 1.6562)
SWEP.IronSightsAng = Vector (0, 0, 0)
