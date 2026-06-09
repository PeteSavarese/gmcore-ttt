AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "M60"
	SWEP.Slot      = 2
	SWEP.Icon = "vgui/ttt/icon_gl_m60"

	SWEP.ViewModelFOV  = 80
	SWEP.ViewModelFlip = false
end

SWEP.Base				= "weapon_tttbase"
DEFINE_BASECLASS("weapon_tttbase")

SWEP.HoldType			= "ar2"
SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Recoil				= 3.5
SWEP.Primary.Damage				= 20
SWEP.Primary.Delay				= 0.12
SWEP.Primary.Cone				= 0.02
SWEP.Primary.ClipSize				= 100
SWEP.Primary.Automatic				= true
SWEP.ViewModel  = "models/weapons/m60/v_m60machinegun.mdl"
SWEP.WorldModel = "models/weapons/m60/w_m60_machine_gun.mdl"
SWEP.Primary.Ammo					= "smg1"
SWEP.AmmoEnt					= "item_ammo_smg1_ttt"
SWEP.Kind					= WEAPON_HEAVY
SWEP.HoldType					= "ar2"
SWEP.Primary.Sound       = Sound("Weapon_M_60.Single")
SWEP.IronSightsPos = Vector(-5.851, -2.763, 3.141)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.Primary.ClipMax					= 300
SWEP.Primary.DefaultClip					= 150
SWEP.HeadshotMultiplier					= 2
SWEP.AutoSpawnable				= true