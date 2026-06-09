if CLIENT then
	SWEP.PrintName = "Galil"
	SWEP.Slot      = 2

	SWEP.ViewModelFOV  = 58
	SWEP.ViewModelFlip = false
	SWEP.Icon = "vgui/ttt/icon_gl_galil"
end

SWEP.Base				= "weapon_tttbase"
SWEP.HoldType			= "ar2"
SWEP.UseHands = true

SWEP.Primary.Delay       = 0.1
SWEP.Primary.Recoil      = 0.8
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 21
SWEP.Primary.Cone        = 0.025
SWEP.Primary.ClipSize    = 35
SWEP.Primary.ClipMax     = 70
SWEP.Primary.DefaultClip = 35
SWEP.Primary.Sound = Sound("Weapon_Galil.Single")
SWEP.HeadshotMultiplier = 1.9

SWEP.IronSightsPos = Vector(-6.361, -11.103, 2.519)

SWEP.ViewModel = "models/weapons/cstrike/c_rif_galil.mdl"
SWEP.WorldModel = "models/weapons/w_rif_galil.mdl"

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.Primary.Ammo					= "Pistol"
SWEP.AmmoEnt					= "item_ammo_pistol_ttt"
